import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_storage/destiny2_storage.dart';

import '../auth/windows_oauth_session.dart';
import '../host_bootstrap.dart';
import 'builds_mock_models.dart';

/// Visible reason when a planned instance is absent from the live profile.
const String kApplyLiveInventoryMissingReason =
    'Not in current inventory - re-import DIM CSV';

/// Visible reason when the live inventory read fails or is empty (fail closed).
const String kApplyLiveInventoryReadFailedReason =
    'Could not read live inventory - try again';

/// Host-side Apply to character for the Builds mock page.
///
/// Kept out of the dim_loadouts read-only guard's builds_mock caller list so
/// those files never mention write-client types. Reuses existing oauth +
/// [BungieWriteClient] — no new scopes or auth flows.
class BuildsMockApplyPorts {
  const BuildsMockApplyPorts({
    this.services,
    this.writeClient,
    this.oauthSession,
    this.profileClient,
    this.exoticItemHashes,
  });

  final AppServices? services;
  final BungieWriteClient? writeClient;
  final WindowsOAuthSession? oauthSession;
  final BungieProfileClient? profileClient;

  /// Optional itemHash set known exotic (definition tierType / catalog).
  /// Merged with OfflineCatalog.isExotic when [services] is present.
  final Set<int>? exoticItemHashes;

  BungieWriteClient? get resolvedWriteClient =>
      writeClient ?? services?.writeClient;

  WindowsOAuthSession? get resolvedOauth =>
      oauthSession ?? services?.oauthSession;

  BungieProfileClient? get resolvedProfile =>
      profileClient ?? services?.profileClient;
}

/// One resolved Apply target: membership + character (label and equip share it).
class BuildsMockApplyTarget {
  const BuildsMockApplyTarget({
    required this.membership,
    required this.character,
  });

  final DestinyMembership membership;
  final CharacterSummary character;

  String get characterId => character.characterId;
}

/// Outcome of resolving the Apply target (ok or a short disable reason).
class BuildsMockApplyTargetResolution {
  const BuildsMockApplyTargetResolution.ok(BuildsMockApplyTarget this.target)
      : reason = null;

  const BuildsMockApplyTargetResolution.unavailable(String this.reason)
      : target = null;

  final BuildsMockApplyTarget? target;
  final String? reason;

  bool get hasTarget => target != null;
}

/// Result of starting / finishing an apply run (UI owns setState).
class BuildsMockApplyOutcome {
  const BuildsMockApplyOutcome({
    this.progress,
    this.error,
    this.finished = false,
  });

  final ApplyToCharacterProgress? progress;
  final String? error;
  final bool finished;
}

/// Display label for the auto-picked Apply target (no picker yet).
///
/// Example: `Warlock 2010 · …4821` (class + light + last 4 of character id).
/// Apply itself cannot be undone — only Fill In has Undo (app build copy).
String formatBuildsMockApplyTargetLabel(CharacterSummary character) {
  final id = character.characterId;
  final suffix = id.length <= 4 ? id : id.substring(id.length - 4);
  return '${character.classType} ${character.light} · …$suffix';
}

/// Resolve the Apply target once: `memberships.first` + first Warlock.
///
/// Returns [BuildsMockApplyTargetResolution.unavailable] with a short reason
/// when signed out / no memberships / no Warlock / missing ports.
Future<BuildsMockApplyTargetResolution> resolveBuildsMockApplyTarget(
  BuildsMockApplyPorts ports,
) async {
  final oauth = ports.resolvedOauth;
  final profile = ports.resolvedProfile;
  if (oauth == null || profile == null) {
    return const BuildsMockApplyTargetResolution.unavailable(
      'Apply needs host services (sign-in + profile).',
    );
  }
  if (!oauth.isSignedIn || oauth.tokens == null) {
    return const BuildsMockApplyTargetResolution.unavailable(
      'Sign in from Settings to apply.',
    );
  }
  try {
    final token = oauth.tokens!.accessToken;
    final memberships = await profile.getMemberships(token);
    if (memberships.isEmpty) {
      return const BuildsMockApplyTargetResolution.unavailable(
        'No Destiny membership found.',
      );
    }
    final membership = memberships.first;
    final characters = await profile.getCharacters(token, membership);
    for (final c in characters) {
      if (c.classType.toLowerCase() == 'warlock') {
        return BuildsMockApplyTargetResolution.ok(
          BuildsMockApplyTarget(membership: membership, character: c),
        );
      }
    }
    return const BuildsMockApplyTargetResolution.unavailable(
      'No Warlock character on this account.',
    );
  } catch (_) {
    return const BuildsMockApplyTargetResolution.unavailable(
      'Could not load characters for Apply.',
    );
  }
}

/// Runs DIM-style move + bulk equip for [build] using saved Fill In pins.
///
/// [target] must be the same resolved character shown in the Applies-to label.
/// Apply itself is the confirmation — moves run immediately with inline
/// progress. Returns a final outcome (never throws for expected sign-in /
/// empty-plan cases).
Future<BuildsMockApplyOutcome> runBuildsMockApplyToCharacter({
  required MockBuild build,
  required FillInSavedBuildPlan? plan,
  required BuildsMockApplyPorts ports,
  required BuildsMockApplyTarget target,
  required bool Function() isMounted,
  required void Function(ApplyToCharacterProgress progress) onProgress,
}) async {
  final writeClient = ports.resolvedWriteClient;
  final oauth = ports.resolvedOauth;

  if (writeClient == null || oauth == null) {
    return const BuildsMockApplyOutcome(
      error:
          'Apply to character needs host services (sign-in + write client).',
      finished: true,
    );
  }
  if (!oauth.isSignedIn || oauth.tokens == null) {
    return const BuildsMockApplyOutcome(
      error: 'Sign in from Settings to apply this build to a character.',
      finished: true,
    );
  }

  final items = itemsForBuildsMockApply(build, plan);
  if (items.isEmpty) {
    return const BuildsMockApplyOutcome(
      error:
          'No equippable items. Run Fill In → Apply to build first '
          '(needs inventory instance ids).',
      finished: true,
    );
  }

  final rows = <ApplyItemProgress>[
    for (final item in items)
      ApplyItemProgress(
        id: item.id,
        label: item.label,
        state: ApplyItemState.waiting,
        itemHash: item.itemHash,
        instanceId: item.instanceId,
        slot: item.slot,
      ),
  ];
  final initial = ApplyToCharacterProgress(
    items: List<ApplyItemProgress>.unmodifiable(rows),
    currentIndex: 0,
    total: items.length,
    running: true,
  );
  onProgress(initial);

  try {
    final token = oauth.tokens!.accessToken;
    if (!isMounted()) {
      return const BuildsMockApplyOutcome(finished: true);
    }

    final gated = await _gateApplyItemsAgainstLiveInventory(
      ports: ports,
      accessToken: token,
      membership: target.membership,
      items: items,
      rows: rows,
      onProgress: onProgress,
      isMounted: isMounted,
    );
    if (!isMounted()) {
      return const BuildsMockApplyOutcome(finished: true);
    }
    if (gated == null) {
      return BuildsMockApplyOutcome(
        progress: _finishedProgress(rows),
        finished: true,
      );
    }
    if (gated.items.isEmpty) {
      return BuildsMockApplyOutcome(
        progress: _finishedProgress(rows),
        finished: true,
      );
    }

    final result = await applyToCharacter(
      writeClient: writeClient,
      ctx: WriteClientContext(
        accessToken: token,
        membershipType: target.membership.membershipType,
      ),
      characterId: target.characterId,
      items: gated.items,
      inventory: gated.inventory,
      onProgress: (progress) {
        if (!isMounted()) return;
        onProgress(_mergeApplyProgress(rows, progress));
      },
    );
    if (!isMounted()) {
      return const BuildsMockApplyOutcome(finished: true);
    }
    final merged = _mergeApplyProgress(rows, result);
    return BuildsMockApplyOutcome(progress: merged, finished: true);
  } catch (e) {
    if (!isMounted()) {
      return const BuildsMockApplyOutcome(finished: true);
    }
    return const BuildsMockApplyOutcome(
      error: kGenericApplyFailureMessage,
      finished: true,
    );
  }
}

/// Present pins + live inventory snapshot for move planning.
class _GatedApplyItems {
  const _GatedApplyItems({
    required this.items,
    required this.inventory,
  });

  final List<ApplyToCharacterItem> items;
  final List<ApplyInventoryItem> inventory;
}

/// Reads live inventory once. Returns present items + snapshot, or `null` when
/// the read failed / was empty (fail closed — caller must not write).
///
/// Missing instances are marked failed on [rows] with
/// [kApplyLiveInventoryMissingReason]; read failures mark every row with
/// [kApplyLiveInventoryReadFailedReason].
Future<_GatedApplyItems?> _gateApplyItemsAgainstLiveInventory({
  required BuildsMockApplyPorts ports,
  required String accessToken,
  required DestinyMembership membership,
  required List<ApplyToCharacterItem> items,
  required List<ApplyItemProgress> rows,
  required void Function(ApplyToCharacterProgress progress) onProgress,
  required bool Function() isMounted,
}) async {
  final profile = ports.resolvedProfile;
  FullInventoryParseResult? parsed;
  if (profile != null) {
    try {
      // Diagnostics distinguish partial profiles (missing component `data`)
      // from a complete read where some instances are simply absent.
      parsed =
          await profile.getFullInventoryWithDiagnostics(accessToken, membership);
    } catch (_) {
      parsed = null;
    }
  }

  if (!isMounted()) {
    return const _GatedApplyItems(items: [], inventory: []);
  }

  final inventoryIncomplete = parsed == null ||
      !parsed.diagnostics.inventorySectionsComplete ||
      parsed.items.isEmpty;
  if (inventoryIncomplete) {
    for (var i = 0; i < rows.length; i++) {
      rows[i] = rows[i].copyWith(
        state: ApplyItemState.failed,
        reason: kApplyLiveInventoryReadFailedReason,
      );
    }
    onProgress(_finishedProgress(rows));
    return null;
  }

  final inventory = parsed.items;
  final liveIds = <String>{
    for (final item in inventory)
      if (item.instanceId.isNotEmpty) item.instanceId,
  };
  final exoticHashes = _exoticHashesForApply(ports);
  final nameByHash = _catalogNamesByHash(ports);
  final snapshot = <ApplyInventoryItem>[
    for (final item in inventory)
      if (item.instanceId.isNotEmpty)
        ApplyInventoryItem(
          instanceId: item.instanceId,
          itemHash: item.itemHash,
          location: item.bucketHash == kPostmasterBucketHash
              ? 'postmaster'
              : item.location,
          bucketHash: item.bucketHash,
          characterId: item.characterId,
          isExotic: item.isExotic || exoticHashes.contains(item.itemHash),
          power: item.power,
          name: nameByHash[item.itemHash] ?? '',
          isLocked: item.isLocked,
          isTransferable: item.isTransferable,
        ),
  ];
  final liveByInstance = <String, ApplyInventoryItem>{
    for (final row in snapshot) row.instanceId: row,
  };
  final present = <ApplyToCharacterItem>[];
  for (var i = 0; i < items.length; i++) {
    if (liveIds.contains(items[i].instanceId)) {
      final live = liveByInstance[items[i].instanceId];
      final isExotic = items[i].isExotic || (live?.isExotic ?? false);
      final label = formatApplyOutcomeLabel(
        rawLabel: items[i].label,
        slot: items[i].slot,
        isExotic: isExotic,
      );
      present.add(
        ApplyToCharacterItem(
          id: items[i].id,
          label: label,
          itemHash: items[i].itemHash,
          instanceId: items[i].instanceId,
          slot: items[i].slot,
          isExotic: isExotic,
        ),
      );
      rows[i] = ApplyItemProgress(
        id: items[i].id,
        label: label,
        state: rows[i].state,
        reason: rows[i].reason,
        itemHash: items[i].itemHash,
        instanceId: items[i].instanceId,
        slot: items[i].slot,
      );
    } else {
      rows[i] = rows[i].copyWith(
        state: ApplyItemState.failed,
        reason: kApplyLiveInventoryMissingReason,
      );
    }
  }
  onProgress(
    ApplyToCharacterProgress(
      items: List<ApplyItemProgress>.unmodifiable(rows),
      currentIndex: 0,
      total: rows.length,
      running: present.isNotEmpty,
      appliedCount: 0,
      failedCount: rows.where((r) => r.state == ApplyItemState.failed).length,
      summary: present.isEmpty ? _summaryForRows(rows) : null,
    ),
  );
  return _GatedApplyItems(items: present, inventory: snapshot);
}

ApplyToCharacterProgress _mergeApplyProgress(
  List<ApplyItemProgress> rows,
  ApplyToCharacterProgress partial,
) {
  final byId = <String, ApplyItemProgress>{
    for (final row in partial.items) row.id: row,
  };
  for (var i = 0; i < rows.length; i++) {
    final updated = byId[rows[i].id];
    if (updated != null) {
      rows[i] = updated;
    }
  }
  final knownIds = {for (final row in rows) row.id};
  for (final row in partial.items) {
    if (!knownIds.contains(row.id)) {
      rows.add(row);
      knownIds.add(row.id);
    }
  }
  final applied = _countNonMakeRoom(rows, ApplyItemState.done);
  final failed = _countNonMakeRoom(rows, ApplyItemState.failed);
  var currentIndex = 0;
  if (!partial.running) {
    currentIndex = rows.isEmpty ? 0 : rows.length - 1;
  } else if (partial.items.isNotEmpty) {
    final activeId = partial.items[partial.currentIndex.clamp(
      0,
      partial.items.length - 1,
    )].id;
    final idx = rows.indexWhere((r) => r.id == activeId);
    if (idx >= 0) currentIndex = idx;
  }
  return ApplyToCharacterProgress(
    items: List<ApplyItemProgress>.unmodifiable(rows),
    currentIndex: currentIndex,
    total: rows.where((r) => !r.id.startsWith(kApplyMakeRoomRowIdPrefix)).length,
    running: partial.running,
    appliedCount: applied,
    failedCount: failed,
    summary: partial.running ? null : _summaryForRows(rows),
  );
}

int _countNonMakeRoom(List<ApplyItemProgress> rows, ApplyItemState state) {
  var n = 0;
  for (final row in rows) {
    if (row.id.startsWith(kApplyMakeRoomRowIdPrefix)) continue;
    if (row.state == state) n += 1;
  }
  return n;
}

ApplyToCharacterProgress _finishedProgress(List<ApplyItemProgress> rows) {
  return ApplyToCharacterProgress(
    items: List<ApplyItemProgress>.unmodifiable(rows),
    currentIndex: rows.isEmpty ? 0 : rows.length - 1,
    total: rows.where((r) => !r.id.startsWith(kApplyMakeRoomRowIdPrefix)).length,
    running: false,
    appliedCount: _countNonMakeRoom(rows, ApplyItemState.done),
    failedCount: _countNonMakeRoom(rows, ApplyItemState.failed),
    summary: _summaryForRows(rows),
  );
}

String _summaryForRows(List<ApplyItemProgress> rows) {
  final applied = _countNonMakeRoom(rows, ApplyItemState.done);
  final failed = _countNonMakeRoom(rows, ApplyItemState.failed);
  return '$applied applied, $failed failed';
}

List<ApplyToCharacterItem> itemsForBuildsMockApply(
  MockBuild build,
  FillInSavedBuildPlan? plan,
) {
  final applied = plan?.applied ?? const <FillInAppliedSlot>[];
  if (applied.isEmpty) return const [];
  final exoticSlots = <String>{};
  for (final s in build.slots) {
    if (s.isExoticSlot) exoticSlots.add(s.slot);
  }
  return [
    for (final slot in applied)
      if (slot.instanceId != null &&
          slot.instanceId!.isNotEmpty &&
          slot.itemHash != null)
        ApplyToCharacterItem(
          id: '${build.id}-${slot.slotWire}',
          label: formatApplyOutcomeLabel(
            rawLabel: slot.label,
            slot: slot.slotWire,
            isExotic: exoticSlots.contains(slot.slotWire) ||
                _slotWireLooksExotic(slot.slotWire),
          ),
          itemHash: slot.itemHash!,
          instanceId: slot.instanceId!,
          slot: slot.slotWire,
          isExotic: exoticSlots.contains(slot.slotWire) ||
              _slotWireLooksExotic(slot.slotWire),
        ),
  ];
}

bool _slotWireLooksExotic(String slotWire) {
  final wire = slotWire.trim().toLowerCase();
  return wire == 'exotic_weapon' || wire == 'exotic_armor';
}

/// Exotic hashes from inject + OfflineCatalog (definition isExotic / tierType).
Set<int> _exoticHashesForApply(BuildsMockApplyPorts ports) {
  final hashes = <int>{...?ports.exoticItemHashes};
  final catalog = ports.services?.offlineCatalog;
  if (catalog != null) {
    for (final item in catalog.baseItems) {
      if (item.isExotic) hashes.add(item.hash);
    }
  }
  return hashes;
}

Map<int, String> _catalogNamesByHash(BuildsMockApplyPorts ports) {
  final out = <int, String>{};
  final catalog = ports.services?.offlineCatalog;
  if (catalog == null) return out;
  for (final item in catalog.baseItems) {
    final name = item.name.trim();
    if (name.isNotEmpty) out[item.hash] = name;
  }
  return out;
}
