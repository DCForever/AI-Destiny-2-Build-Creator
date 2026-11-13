import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_storage/destiny2_storage.dart';

import '../auth/windows_oauth_session.dart';
import '../host_bootstrap.dart';
import 'builds_mock_models.dart';

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
  });

  final AppServices? services;
  final BungieWriteClient? writeClient;
  final WindowsOAuthSession? oauthSession;
  final BungieProfileClient? profileClient;

  BungieWriteClient? get resolvedWriteClient =>
      writeClient ?? services?.writeClient;

  WindowsOAuthSession? get resolvedOauth =>
      oauthSession ?? services?.oauthSession;

  BungieProfileClient? get resolvedProfile =>
      profileClient ?? services?.profileClient;
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

/// Runs sequential equip for [build] using saved Fill In applied pins.
///
/// Calls [onUpdate] as progress changes. Returns a final outcome (never throws
/// for expected sign-in / empty-plan cases).
Future<BuildsMockApplyOutcome> runBuildsMockApplyToCharacter({
  required MockBuild build,
  required FillInSavedBuildPlan? plan,
  required BuildsMockApplyPorts ports,
  required bool Function() isMounted,
  required void Function(ApplyToCharacterProgress progress) onProgress,
}) async {
  final writeClient = ports.resolvedWriteClient;
  final oauth = ports.resolvedOauth;
  final profile = ports.resolvedProfile;

  if (writeClient == null || oauth == null || profile == null) {
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

  final initial = ApplyToCharacterProgress(
    items: [
      for (final item in items)
        ApplyItemProgress(
          id: item.id,
          label: item.label,
          state: ApplyItemState.waiting,
          itemHash: item.itemHash,
          instanceId: item.instanceId,
          slot: item.slot,
        ),
    ],
    currentIndex: 0,
    total: items.length,
    running: true,
  );
  onProgress(initial);

  try {
    final token = oauth.tokens!.accessToken;
    final memberships = await profile.getMemberships(token);
    if (!isMounted()) {
      return const BuildsMockApplyOutcome(finished: true);
    }
    if (memberships.isEmpty) {
      return const BuildsMockApplyOutcome(
        error: 'No Destiny memberships found',
        finished: true,
      );
    }
    final membership = memberships.first;
    final characters = await profile.getCharacters(token, membership);
    if (!isMounted()) {
      return const BuildsMockApplyOutcome(finished: true);
    }
    final matching = [
      for (final c in characters)
        if (c.classType.toLowerCase() == 'warlock') c,
    ];
    if (matching.isEmpty) {
      return const BuildsMockApplyOutcome(
        error: 'No Warlock character on this account.',
        finished: true,
      );
    }
    final characterId = matching.first.characterId;

    final result = await applyToCharacter(
      writeClient: writeClient,
      ctx: WriteClientContext(
        accessToken: token,
        membershipType: membership.membershipType,
      ),
      characterId: characterId,
      items: items,
      onProgress: (progress) {
        if (!isMounted()) return;
        onProgress(progress);
      },
    );
    if (!isMounted()) {
      return const BuildsMockApplyOutcome(finished: true);
    }
    return BuildsMockApplyOutcome(progress: result, finished: true);
  } catch (e) {
    if (!isMounted()) {
      return const BuildsMockApplyOutcome(finished: true);
    }
    return BuildsMockApplyOutcome(error: e.toString(), finished: true);
  }
}

List<ApplyToCharacterItem> itemsForBuildsMockApply(
  MockBuild build,
  FillInSavedBuildPlan? plan,
) {
  final applied = plan?.applied ?? const <FillInAppliedSlot>[];
  if (applied.isEmpty) return const [];
  return [
    for (final slot in applied)
      if (slot.instanceId != null &&
          slot.instanceId!.isNotEmpty &&
          slot.itemHash != null)
        ApplyToCharacterItem(
          id: '${build.id}-${slot.slotWire}',
          label: slot.label.isEmpty ? slot.slotWire : slot.label,
          itemHash: slot.itemHash!,
          instanceId: slot.instanceId!,
          slot: slot.slotWire,
        ),
  ];
}
