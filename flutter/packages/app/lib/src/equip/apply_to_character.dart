/// DIM-style Apply-to-character: move (sequential) then bulk EquipItems.
///
/// Pressing Apply plans transfers from vault / other characters onto the
/// target, runs them immediately with inline per-item progress, then one
/// EquipItems call (exotics last). Never dismantles or auto-makes room.
library;

import 'package:destiny2_bungie/destiny2_bungie.dart';

/// Per-item apply state shown inline on the build detail card.
enum ApplyItemState {
  waiting,
  applying,
  done,
  failed,
}

/// One item row in an Apply-to-character run.
class ApplyItemProgress {
  const ApplyItemProgress({
    required this.id,
    required this.label,
    required this.state,
    this.reason,
    this.itemHash,
    this.instanceId,
    this.slot,
  });

  final String id;
  final String label;
  final ApplyItemState state;
  final String? reason;
  final int? itemHash;
  final String? instanceId;
  final String? slot;

  ApplyItemProgress copyWith({
    ApplyItemState? state,
    String? reason,
    bool clearReason = false,
  }) {
    return ApplyItemProgress(
      id: id,
      label: label,
      state: state ?? this.state,
      reason: clearReason ? null : (reason ?? this.reason),
      itemHash: itemHash,
      instanceId: instanceId,
      slot: slot,
    );
  }
}

/// Snapshot of an in-flight or finished apply run.
class ApplyToCharacterProgress {
  const ApplyToCharacterProgress({
    required this.items,
    required this.currentIndex,
    required this.total,
    required this.running,
    this.appliedCount = 0,
    this.failedCount = 0,
    this.summary,
  });

  final List<ApplyItemProgress> items;
  final int currentIndex;
  final int total;
  final bool running;
  final int appliedCount;
  final int failedCount;
  final String? summary;

  String get applyingLine =>
      running ? 'Applying ${currentIndex + 1} of $total' : (summary ?? '');
}

/// One equippable pin prepared from a filled-in build.
class ApplyToCharacterItem {
  const ApplyToCharacterItem({
    required this.id,
    required this.label,
    required this.itemHash,
    required this.instanceId,
    this.slot,
  });

  final String id;
  final String label;
  final int itemHash;
  final String instanceId;
  final String? slot;
}

/// Live inventory row used to locate pins before transfer / equip.
class ApplyInventoryItem {
  const ApplyInventoryItem({
    required this.instanceId,
    required this.itemHash,
    required this.location,
    required this.bucketHash,
    this.characterId,
    this.isExotic = false,
  });

  final String instanceId;
  final int itemHash;

  /// `vault` | `character` | `equipped`.
  final String location;
  final int bucketHash;
  final String? characterId;
  final bool isExotic;
}

/// Optional delay injector (tests record throttle sleeps).
typedef ApplyDelay = Future<void> Function(Duration delay);

/// Character inventory capacity per equipment bucket (equipped + inventory).
const int kApplyCharacterBucketCapacity = 10;

/// Builds a DIM-style move + equip plan and executes it.
///
/// Apply itself is the confirmation — plans and runs immediately with inline
/// per-item progress (no separate dry-run dialog).
///
/// - Locates each pin (target / vault / other / equipped-on-other).
/// - Full bucket → refuse that item with [kNoRoomOnCharacterMessage].
/// - Transfers sequential (other → vault → target); equipped-on-other dequips
///   first via a non-exotic replacement EquipItem on that character.
/// - One bulk [BungieWriteClient.equipItems], exotics last.
/// - Stops further equips on in-activity / unequippable errors.
Future<ApplyToCharacterProgress> applyToCharacter({
  required BungieWriteClient writeClient,
  required WriteClientContext ctx,
  required String characterId,
  required List<ApplyToCharacterItem> items,
  List<ApplyInventoryItem> inventory = const [],
  void Function(ApplyToCharacterProgress progress)? onProgress,
  ApplyDelay? delay,
}) async {
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

  void emit({required int index, required bool running, String? summary}) {
    final snap = ApplyToCharacterProgress(
      items: List<ApplyItemProgress>.unmodifiable(rows),
      currentIndex: index.clamp(0, rows.isEmpty ? 0 : rows.length - 1),
      total: rows.length,
      running: running,
      appliedCount: rows.where((r) => r.state == ApplyItemState.done).length,
      failedCount: rows.where((r) => r.state == ApplyItemState.failed).length,
      summary: summary,
    );
    onProgress?.call(snap);
  }

  if (items.isEmpty) {
    const empty = ApplyToCharacterProgress(
      items: [],
      currentIndex: 0,
      total: 0,
      running: false,
      summary: '0 applied, 0 failed',
    );
    onProgress?.call(empty);
    return empty;
  }

  emit(index: 0, running: true);

  final byInstance = <String, ApplyInventoryItem>{
    for (final row in inventory) row.instanceId: row,
  };
  final plannedIds = {for (final item in items) item.instanceId};

  final plan = <_ApplyItemPlan>[
    for (var i = 0; i < items.length; i++)
      _planItem(
        item: items[i],
        rowIndex: i,
        characterId: characterId,
        byInstance: byInstance,
        inventory: inventory,
        plannedIds: plannedIds,
      ),
  ];

  final sleeper = delay ?? defaultWriteDelay;
  var stopEquips = false;
  var stopReason = kInActivityEquipMessage;

  for (final p in plan) {
    final index = p.rowIndex;
    if (p.refusalReason != null) {
      rows[index] = rows[index].copyWith(
        state: ApplyItemState.failed,
        reason: p.refusalReason,
      );
      emit(index: index, running: true);
      continue;
    }

    if (stopEquips) {
      rows[index] = rows[index].copyWith(
        state: ApplyItemState.failed,
        reason: stopReason,
      );
      emit(index: index, running: true);
      continue;
    }

    rows[index] = rows[index].copyWith(
      state: ApplyItemState.applying,
      clearReason: true,
    );
    emit(index: index, running: true);

    try {
      for (final dequip in p.dequipSteps) {
        await runWriteWithThrottleBackoff(
          () => writeClient.equipItem(ctx, dequip),
          delay: sleeper,
        );
      }
      for (final step in p.transferSteps) {
        await runWriteWithThrottleBackoff(
          () => writeClient.transferItem(ctx, step),
          delay: sleeper,
        );
      }
    } catch (error) {
      final mapped = _mapWriteError(error);
      final reason =
          mapped.isInActivity ? kInActivityEquipMessage : mapped.statusText;
      rows[index] = rows[index].copyWith(
        state: ApplyItemState.failed,
        reason: reason,
      );
      emit(index: index, running: true);
      if (mapped.stopFurtherEquips) {
        stopEquips = true;
        stopReason = reason;
        _failRemainingWaiting(rows, fromIndex: index + 1, reason: stopReason);
        break;
      }
    }
  }

  final equipable = <_ApplyItemPlan>[
    for (final p in plan)
      if (p.refusalReason == null &&
          rows[p.rowIndex].state == ApplyItemState.applying)
        p,
  ];

  if (equipable.isEmpty || stopEquips) {
    if (stopEquips) {
      for (final p in equipable) {
        rows[p.rowIndex] = rows[p.rowIndex].copyWith(
          state: ApplyItemState.failed,
          reason: stopReason,
        );
      }
    }
    return _finish(rows, onProgress);
  }

  equipable.sort((a, b) {
    final ax = a.isExotic ? 1 : 0;
    final bx = b.isExotic ? 1 : 0;
    return ax.compareTo(bx);
  });

  final itemIds = [for (final p in equipable) p.instanceId];
  try {
    final results = await runWriteWithThrottleBackoff(
      () => writeClient.equipItems(
        ctx,
        EquipItemsArgs(characterId: characterId, itemIds: itemIds),
      ),
      delay: sleeper,
    );
    final byId = <String, EquipItemResultEntry>{
      for (final r in results) r.instanceId: r,
    };
    for (final p in equipable) {
      final result = byId[p.instanceId];
      if (result == null) {
        rows[p.rowIndex] = rows[p.rowIndex].copyWith(
          state: ApplyItemState.failed,
          reason: errorStatusName(kDestinyItemNotFound),
        );
        continue;
      }
      if (result.ok) {
        rows[p.rowIndex] = rows[p.rowIndex].copyWith(
          state: ApplyItemState.done,
          clearReason: true,
        );
        continue;
      }
      final reason =
          result.equipStatus == kDestinyCannotPerformActionAtThisLocation
              ? kInActivityEquipMessage
              : result.statusText;
      rows[p.rowIndex] = rows[p.rowIndex].copyWith(
        state: ApplyItemState.failed,
        reason: reason,
      );
      if (isEquipNotPossibleErrorCode(result.equipStatus)) {
        stopReason = reason;
        final remaining = equipable.skipWhile((e) => e != p).skip(1);
        for (final later in remaining) {
          if (rows[later.rowIndex].state == ApplyItemState.applying) {
            rows[later.rowIndex] = rows[later.rowIndex].copyWith(
              state: ApplyItemState.failed,
              reason: stopReason,
            );
          }
        }
        break;
      }
    }
  } catch (error) {
    final mapped = _mapWriteError(error);
    final reason =
        mapped.isInActivity ? kInActivityEquipMessage : mapped.statusText;
    for (final p in equipable) {
      if (rows[p.rowIndex].state == ApplyItemState.applying) {
        rows[p.rowIndex] = rows[p.rowIndex].copyWith(
          state: ApplyItemState.failed,
          reason: reason,
        );
      }
    }
  }

  return _finish(rows, onProgress);
}

ApplyToCharacterProgress _finish(
  List<ApplyItemProgress> rows,
  void Function(ApplyToCharacterProgress progress)? onProgress,
) {
  final applied = rows.where((r) => r.state == ApplyItemState.done).length;
  final failed = rows.where((r) => r.state == ApplyItemState.failed).length;
  final done = ApplyToCharacterProgress(
    items: List<ApplyItemProgress>.unmodifiable(rows),
    currentIndex: rows.isEmpty ? 0 : rows.length - 1,
    total: rows.length,
    running: false,
    appliedCount: applied,
    failedCount: failed,
    summary: '$applied applied, $failed failed',
  );
  onProgress?.call(done);
  return done;
}

void _failRemainingWaiting(
  List<ApplyItemProgress> rows, {
  required int fromIndex,
  required String reason,
}) {
  for (var i = fromIndex; i < rows.length; i++) {
    if (rows[i].state == ApplyItemState.waiting ||
        rows[i].state == ApplyItemState.applying) {
      rows[i] = rows[i].copyWith(state: ApplyItemState.failed, reason: reason);
    }
  }
}

class _ApplyItemPlan {
  const _ApplyItemPlan({
    required this.rowIndex,
    required this.instanceId,
    required this.isExotic,
    required this.dequipSteps,
    required this.transferSteps,
    this.refusalReason,
  });

  final int rowIndex;
  final String instanceId;
  final bool isExotic;
  final List<EquipItemArgs> dequipSteps;
  final List<TransferItemArgs> transferSteps;
  final String? refusalReason;
}

_ApplyItemPlan _planItem({
  required ApplyToCharacterItem item,
  required int rowIndex,
  required String characterId,
  required Map<String, ApplyInventoryItem> byInstance,
  required List<ApplyInventoryItem> inventory,
  required Set<String> plannedIds,
}) {
  final live = byInstance[item.instanceId];
  if (live == null) {
    return _ApplyItemPlan(
      rowIndex: rowIndex,
      instanceId: item.instanceId,
      isExotic: false,
      dequipSteps: const [],
      transferSteps: const [],
      refusalReason: errorStatusName(kDestinyItemNotFound),
    );
  }

  final onTarget = live.characterId == characterId &&
      (live.location == 'character' || live.location == 'equipped');
  final inVault = live.location == 'vault';
  final onOther = live.characterId != null &&
      live.characterId != characterId &&
      (live.location == 'character' || live.location == 'equipped');
  final equippedOnOther = onOther && live.location == 'equipped';

  if (onTarget) {
    return _ApplyItemPlan(
      rowIndex: rowIndex,
      instanceId: item.instanceId,
      isExotic: live.isExotic,
      dequipSteps: const [],
      transferSteps: const [],
    );
  }

  if (_bucketIsFull(inventory, characterId, live.bucketHash)) {
    return _ApplyItemPlan(
      rowIndex: rowIndex,
      instanceId: item.instanceId,
      isExotic: live.isExotic,
      dequipSteps: const [],
      transferSteps: const [],
      refusalReason: kNoRoomOnCharacterMessage,
    );
  }

  final dequips = <EquipItemArgs>[];
  final transfers = <TransferItemArgs>[];

  if (equippedOnOther) {
    final replacement = _findDequipReplacement(
      inventory: inventory,
      sourceCharacterId: live.characterId!,
      bucketHash: live.bucketHash,
      excludeIds: plannedIds,
    );
    if (replacement == null) {
      return _ApplyItemPlan(
        rowIndex: rowIndex,
        instanceId: item.instanceId,
        isExotic: live.isExotic,
        dequipSteps: const [],
        transferSteps: const [],
        refusalReason: 'Cannot unequip on other character',
      );
    }
    dequips.add(
      EquipItemArgs(
        itemHash: replacement.itemHash,
        instanceId: replacement.instanceId,
        characterId: live.characterId!,
      ),
    );
  }

  if (onOther) {
    transfers.add(
      TransferItemArgs(
        itemHash: item.itemHash,
        instanceId: item.instanceId,
        characterId: live.characterId!,
        transferToVault: true,
      ),
    );
    transfers.add(
      TransferItemArgs(
        itemHash: item.itemHash,
        instanceId: item.instanceId,
        characterId: characterId,
        transferToVault: false,
      ),
    );
  } else if (inVault) {
    transfers.add(
      TransferItemArgs(
        itemHash: item.itemHash,
        instanceId: item.instanceId,
        characterId: characterId,
        transferToVault: false,
      ),
    );
  } else {
    return _ApplyItemPlan(
      rowIndex: rowIndex,
      instanceId: item.instanceId,
      isExotic: live.isExotic,
      dequipSteps: const [],
      transferSteps: const [],
      refusalReason: errorStatusName(kDestinyItemNotFound),
    );
  }

  return _ApplyItemPlan(
    rowIndex: rowIndex,
    instanceId: item.instanceId,
    isExotic: live.isExotic,
    dequipSteps: dequips,
    transferSteps: transfers,
  );
}

bool _bucketIsFull(
  List<ApplyInventoryItem> inventory,
  String characterId,
  int bucketHash,
) {
  var count = 0;
  for (final row in inventory) {
    if (row.characterId != characterId) continue;
    if (row.bucketHash != bucketHash) continue;
    if (row.location == 'character' || row.location == 'equipped') {
      count += 1;
    }
  }
  return count >= kApplyCharacterBucketCapacity;
}

ApplyInventoryItem? _findDequipReplacement({
  required List<ApplyInventoryItem> inventory,
  required String sourceCharacterId,
  required int bucketHash,
  required Set<String> excludeIds,
}) {
  for (final row in inventory) {
    if (row.characterId != sourceCharacterId) continue;
    if (row.bucketHash != bucketHash) continue;
    if (row.location != 'character') continue;
    if (row.isExotic) continue;
    if (excludeIds.contains(row.instanceId)) continue;
    return row;
  }
  return null;
}

class _MappedWriteError {
  const _MappedWriteError({
    required this.statusText,
    required this.stopFurtherEquips,
    required this.isInActivity,
  });

  final String statusText;
  final bool stopFurtherEquips;
  final bool isInActivity;
}

_MappedWriteError _mapWriteError(Object error) {
  if (error is BungiePlatformException) {
    final code = error.errorCode;
    final status = errorStatusName(code, errorStatus: error.errorStatus);
    final inActivity = code == kDestinyCannotPerformActionAtThisLocation ||
        status == 'DestinyCannotPerformActionAtThisLocation';
    return _MappedWriteError(
      statusText: inActivity ? kInActivityEquipMessage : status,
      stopFurtherEquips: isEquipNotPossibleErrorCode(code) || inActivity,
      isInActivity: inActivity,
    );
  }
  if (error is BungieHttpException) {
    return _MappedWriteError(
      statusText: 'HTTP ${error.statusCode}',
      stopFurtherEquips: false,
      isInActivity: false,
    );
  }
  final raw =
      error.toString().replaceFirst(RegExp(r'^(Exception|Bad state): '), '');
  return _MappedWriteError(
    statusText: raw.isEmpty ? 'failed' : raw,
    stopFurtherEquips: false,
    isInActivity: false,
  );
}
