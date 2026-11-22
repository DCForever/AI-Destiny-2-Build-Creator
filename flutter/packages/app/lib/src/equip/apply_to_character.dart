/// DIM-style Apply-to-character: move (sequential) then bulk EquipItems,
/// then optional subclass equip + InsertSocketPlugFree for abilities /
/// aspects / fragments / armor mods.
///
/// Pressing Apply plans transfers from vault / other characters onto the
/// target, runs them immediately with inline per-item progress, then one
/// EquipItems call (exotics last). Never dismantles. When the target bucket
/// is full (planner count or Bungie 1642/1637), makes room by transferring one
/// eligible unequipped non-plan item to the vault (at most 2 attempts per
/// item), then retries the original move. Socket phase uses only the Free
/// plug-insert action (never the paid non-Free variant).
library;

import 'package:destiny2_bungie/destiny2_bungie.dart';

import '../presentation/equip_format.dart';
import 'apply_socket_plan.dart';

export 'apply_socket_plan.dart';

part 'apply_sockets.dart';

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
    this.isExotic = false,
  });

  final String id;
  final String label;
  final int itemHash;
  final String instanceId;
  final String? slot;
  final bool isExotic;
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
    this.power = 0,
    this.name = '',
    this.isLocked = false,
    this.isTransferable = true,
    this.classType,
  });

  final String instanceId;
  final int itemHash;

  /// `vault` | `character` | `equipped` | `postmaster`.
  final String location;
  final int bucketHash;
  final String? characterId;
  final bool isExotic;

  /// Primary-stat power for make-room eviction ordering (lowest first).
  final int power;

  /// Display name when known (make-room / side-effect outcome rows).
  final String name;

  /// Destiny ItemState Locked bit — never make-room-evict locked items.
  final bool isLocked;

  /// False when DestinyTransferStatus is not CanTransfer.
  final bool isTransferable;

  /// Titan | Hunter | Warlock when known (armor); null/empty/Unknown = any.
  final String? classType;
}

/// Optional delay injector (tests record throttle sleeps).
typedef ApplyDelay = Future<void> Function(Duration delay);

/// Character inventory capacity per equipment bucket (equipped + inventory).
const int kApplyCharacterBucketCapacity = 10;

/// Vault capacity (all vault items). Make-room refuses when vault is full.
///
/// Bungie vault size as of Destiny 2 Update 9.7.0 (Monument of Triumph): 1300
/// slots. Prior: help.bungie.net listed 600; Update 9.5.0 added +300 → 1000
/// (bungie.net News `destiny_update_9_5_0`); 9.7.0 expanded to 1300
/// (titanquisitor.com / community patch notes for 9.7.0).
const int kApplyVaultCapacity = 1300;

/// Max make-room eviction attempts per planned item (then fixed-text failure).
const int kApplyMakeRoomMaxAttempts = 2;

/// Id prefix for make-room outcome rows (excluded from applied/failed counts).
const String kApplyMakeRoomRowIdPrefix = 'make-room:';

/// Id prefix for move/equip side-effect rows (excluded from applied/failed counts).
const String kApplySideEffectRowIdPrefix = 'apply-side:';

/// True when a progress row is auxiliary (make-room / move / dequip report).
bool isAuxiliaryApplyRow(ApplyItemProgress row) =>
    row.id.startsWith(kApplyMakeRoomRowIdPrefix) ||
    row.id.startsWith(kApplySideEffectRowIdPrefix);

/// Builds a socket plan from items that actually equipped in this run.
typedef ApplySocketPlanBuilder = ApplySocketPlan? Function(
  List<ApplyToCharacterItem> successfullyEquipped,
);

/// Builds a DIM-style move + equip plan and executes it.
///
/// Apply itself is the confirmation — plans and runs immediately with inline
/// per-item progress (no separate dry-run dialog).
Future<ApplyToCharacterProgress> applyToCharacter({
  required BungieWriteClient writeClient,
  required WriteClientContext ctx,
  required String characterId,
  required List<ApplyToCharacterItem> items,
  List<ApplyInventoryItem> inventory = const [],
  Map<String, String> characterClassById = const {},
  ApplySocketPlan? socketPlan,
  ApplySocketPlanBuilder? socketPlanBuilder,
  void Function(ApplyToCharacterProgress progress)? onProgress,
  ApplyDelay? delay,
}) async {
  final rows = <ApplyItemProgress>[
    for (final item in items)
      ApplyItemProgress(
        id: item.id,
        label: formatApplyOutcomeLabel(
          rawLabel: item.label,
          slot: item.slot,
          isExotic: item.isExotic,
        ),
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
      total: _planItemCount(rows),
      running: running,
      appliedCount: _countPlanRows(rows, ApplyItemState.done),
      failedCount: _countPlanRows(rows, ApplyItemState.failed),
      summary: summary,
    );
    onProgress?.call(snap);
  }

  ApplySocketPlan? resolveSockets(
    List<ApplyToCharacterItem> equipped,
  ) {
    if (socketPlanBuilder != null) return socketPlanBuilder(equipped);
    return socketPlan;
  }

  if (items.isEmpty) {
    final earlySockets = resolveSockets(const []);
    if (earlySockets == null || !earlySockets.hasWork) {
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
  }

  emit(index: 0, running: true);

  final byInstance = <String, ApplyInventoryItem>{
    for (final row in inventory) row.instanceId: row,
  };
  final plannedIds = {for (final item in items) item.instanceId};
  final characterReserved = <int, int>{};
  var vaultReserved = 0;
  final reservedEvicteeIds = <String>{};
  final workingInventory = List<ApplyInventoryItem>.from(inventory);

  final plan = <_ApplyItemPlan>[
    for (var i = 0; i < items.length; i++)
      _planItem(
        item: items[i],
        rowIndex: i,
        characterId: characterId,
        byInstance: byInstance,
        inventory: workingInventory,
        plannedIds: plannedIds,
        characterClassById: characterClassById,
        characterReserved: characterReserved,
        vaultReserved: () => vaultReserved,
        reserveVault: () => vaultReserved += 1,
        reservedEvicteeIds: reservedEvicteeIds,
      ),
  ];

  final sleeper = delay ?? defaultWriteDelay;
  var stopEquips = false;
  var stopReason = kInActivityEquipMessage;

  if (items.isEmpty) {
    final sockets = resolveSockets(const []);
    if (sockets != null && sockets.hasWork) {
      await _runApplySocketPhase(
        writeClient: writeClient,
        ctx: ctx,
        characterId: characterId,
        plan: sockets,
        rows: rows,
        emit: emit,
        sleeper: sleeper,
      );
    }
    return _finish(rows, onProgress);
  }

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

    var reachedVault = false;
    try {
      for (final prep in p.prepTransferSteps) {
        await runWriteWithThrottleBackoff(
          () => writeClient.transferItem(ctx, prep),
          delay: sleeper,
        );
        final prepName = _itemDisplayName(workingInventory, prep.instanceId);
        rows.add(
          ApplyItemProgress(
            id: '$kApplySideEffectRowIdPrefix${prep.instanceId}:vault-to-char',
            label: kApplyMovedItemMessage(
              prepName,
              'vault',
              'character ${prep.characterId}',
            ),
            state: ApplyItemState.done,
          ),
        );
        emit(index: index, running: true);
      }
      for (final dequip in p.dequipSteps) {
        await runWriteWithThrottleBackoff(
          () => writeClient.equipItem(ctx, dequip),
          delay: sleeper,
        );
        final dequipName =
            _itemDisplayName(workingInventory, dequip.instanceId);
        rows.add(
          ApplyItemProgress(
            id: '$kApplySideEffectRowIdPrefix${dequip.instanceId}:equip',
            label: kApplyEquippedOnOtherCharacterMessage(
              dequipName,
              dequip.characterId,
            ),
            state: ApplyItemState.done,
          ),
        );
        emit(index: index, running: true);
      }
      final transferResult = await _runTransfersWithMakeRoom(
        writeClient: writeClient,
        ctx: ctx,
        characterId: characterId,
        plan: p,
        inventory: workingInventory,
        plannedIds: plannedIds,
        reservedEvicteeIds: reservedEvicteeIds,
        vaultReserved: () => vaultReserved,
        sleeper: sleeper,
        itemLabel: rows[index].label,
        onMakeRoom: (message, evicteeId) {
          rows.add(
            ApplyItemProgress(
              id: '$kApplyMakeRoomRowIdPrefix$evicteeId',
              label: message,
              state: ApplyItemState.done,
            ),
          );
          emit(index: index, running: true);
        },
        onPlanItemMoved: (from, to) {
          final pinName =
              _itemDisplayName(workingInventory, p.instanceId);
          rows.add(
            ApplyItemProgress(
              id: '$kApplySideEffectRowIdPrefix${p.instanceId}:$from-$to',
              label: kApplyMovedItemMessage(pinName, from, to),
              state: ApplyItemState.done,
            ),
          );
          emit(index: index, running: true);
        },
        onReachedVault: () => reachedVault = true,
      );
      if (transferResult != null) {
        // After a successful hop onto the vault, always tell Daniel the item
        // is stranded there (PR55) — do not replace with generic still-full.
        final reason = reachedVault
            ? kMovedToVaultStuckMessage
            : transferResult;
        rows[index] = rows[index].copyWith(
          state: ApplyItemState.failed,
          reason: reason,
        );
        emit(index: index, running: true);
        continue;
      }
    } catch (error) {
      final mapped = _mapWriteError(error);
      final reason = reachedVault
          ? kMovedToVaultStuckMessage
          : (mapped.isInActivity
              ? kInActivityEquipMessage
              : mapped.statusText);
      rows[index] = rows[index].copyWith(
        state: ApplyItemState.failed,
        reason: reason,
      );
      emit(index: index, running: true);
      if (!reachedVault && mapped.stopFurtherEquips) {
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

  List<ApplyToCharacterItem> successfullyEquipped() {
    final byId = <String, ApplyToCharacterItem>{
      for (final item in items) item.instanceId: item,
    };
    return [
      for (final p in plan)
        if (rows[p.rowIndex].state == ApplyItemState.done)
          if (byId[p.instanceId] != null) byId[p.instanceId]!,
    ];
  }

  if (equipable.isEmpty || stopEquips) {
    if (stopEquips) {
      for (final p in equipable) {
        rows[p.rowIndex] = rows[p.rowIndex].copyWith(
          state: ApplyItemState.failed,
          reason: stopReason,
        );
      }
      return _finish(rows, onProgress);
    }
    final sockets = resolveSockets(successfullyEquipped());
    if (sockets != null && sockets.hasWork) {
      await _runApplySocketPhase(
        writeClient: writeClient,
        ctx: ctx,
        characterId: characterId,
        plan: sockets,
        rows: rows,
        emit: emit,
        sleeper: sleeper,
      );
    }
    return _finish(rows, onProgress);
  }

  equipable.sort((a, b) {
    final ax = a.isExotic ? 1 : 0;
    final bx = b.isExotic ? 1 : 0;
    return ax.compareTo(bx);
  });

  final itemIds = [for (final p in equipable) p.instanceId];
  var stopSockets = false;
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
        stopSockets = true;
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
    if (mapped.stopFurtherEquips) {
      return _finish(rows, onProgress);
    }
  }

  if (!stopSockets) {
    final sockets = resolveSockets(successfullyEquipped());
    if (sockets != null && sockets.hasWork) {
      await _runApplySocketPhase(
        writeClient: writeClient,
        ctx: ctx,
        characterId: characterId,
        plan: sockets,
        rows: rows,
        emit: emit,
        sleeper: sleeper,
      );
    }
  }

  return _finish(rows, onProgress);
}

ApplyToCharacterProgress _finish(
  List<ApplyItemProgress> rows,
  void Function(ApplyToCharacterProgress progress)? onProgress,
) {
  final applied = _countPlanRows(rows, ApplyItemState.done);
  final failed = _countPlanRows(rows, ApplyItemState.failed);
  final done = ApplyToCharacterProgress(
    items: List<ApplyItemProgress>.unmodifiable(rows),
    currentIndex: rows.isEmpty ? 0 : rows.length - 1,
    total: _planItemCount(rows),
    running: false,
    appliedCount: applied,
    failedCount: failed,
    summary: '$applied applied, $failed failed',
  );
  onProgress?.call(done);
  return done;
}

int _planItemCount(List<ApplyItemProgress> rows) =>
    rows.where((r) => !isAuxiliaryApplyRow(r)).length;

int _countPlanRows(List<ApplyItemProgress> rows, ApplyItemState state) {
  var n = 0;
  for (final row in rows) {
    if (isAuxiliaryApplyRow(row)) continue;
    if (row.state == state) n += 1;
  }
  return n;
}

void _failRemainingWaiting(
  List<ApplyItemProgress> rows, {
  required int fromIndex,
  required String reason,
}) {
  for (var i = fromIndex; i < rows.length; i++) {
    if (isAuxiliaryApplyRow(rows[i])) continue;
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
    required this.itemHash,
    required this.bucketHash,
    required this.isExotic,
    required this.prepTransferSteps,
    required this.dequipSteps,
    required this.transferSteps,
    this.refusalReason,
  });

  final int rowIndex;
  final String instanceId;
  final int itemHash;
  final int bucketHash;
  final bool isExotic;

  /// Vault → other-character pulls before dequip (replacement was in vault).
  final List<TransferItemArgs> prepTransferSteps;
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
  required Map<String, String> characterClassById,
  required Map<int, int> characterReserved,
  required int Function() vaultReserved,
  required void Function() reserveVault,
  required Set<String> reservedEvicteeIds,
}) {
  final live = byInstance[item.instanceId];
  if (live == null) {
    return _ApplyItemPlan(
      rowIndex: rowIndex,
      instanceId: item.instanceId,
      itemHash: item.itemHash,
      bucketHash: 0,
      isExotic: false,
      prepTransferSteps: const [],
      dequipSteps: const [],
      transferSteps: const [],
      refusalReason: errorStatusName(kDestinyItemNotFound),
    );
  }

  if (live.itemHash != item.itemHash) {
    return _ApplyItemPlan(
      rowIndex: rowIndex,
      instanceId: item.instanceId,
      itemHash: item.itemHash,
      bucketHash: live.bucketHash,
      isExotic: live.isExotic,
      prepTransferSteps: const [],
      dequipSteps: const [],
      transferSteps: const [],
      refusalReason: kItemHashMismatchMessage,
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
      itemHash: item.itemHash,
      bucketHash: live.bucketHash,
      isExotic: live.isExotic,
      prepTransferSteps: const [],
      dequipSteps: const [],
      transferSteps: const [],
    );
  }

  final prepTransfers = <TransferItemArgs>[];
  final dequips = <EquipItemArgs>[];
  final transfers = <TransferItemArgs>[];

  // Pick a make-room candidate early, but only reserve after every refusal
  // check for this item has passed (so a later refuse does not consume a slot).
  ApplyInventoryItem? plannedEvictee;
  final needsCharacterSlot = onOther || inVault;
  if (needsCharacterSlot) {
    final occupied = _bucketCount(inventory, characterId, live.bucketHash) +
        (characterReserved[live.bucketHash] ?? 0);
    if (occupied >= kApplyCharacterBucketCapacity) {
      final vaultOccupied = _vaultCount(inventory) + vaultReserved();
      if (vaultOccupied >= kApplyVaultCapacity) {
        return _ApplyItemPlan(
          rowIndex: rowIndex,
          instanceId: item.instanceId,
          itemHash: item.itemHash,
          bucketHash: live.bucketHash,
          isExotic: live.isExotic,
          prepTransferSteps: const [],
          dequipSteps: const [],
          transferSteps: const [],
          refusalReason: kNoRoomInVaultMessage,
        );
      }
      plannedEvictee = _pickMakeRoomEvictee(
        inventory: inventory,
        characterId: characterId,
        bucketHash: live.bucketHash,
        excludeIds: {...plannedIds, ...reservedEvicteeIds},
      );
      if (plannedEvictee == null) {
        return _ApplyItemPlan(
          rowIndex: rowIndex,
          instanceId: item.instanceId,
          itemHash: item.itemHash,
          bucketHash: live.bucketHash,
          isExotic: live.isExotic,
          prepTransferSteps: const [],
          dequipSteps: const [],
          transferSteps: const [],
          refusalReason: kNoRoomOnCharacterMessage,
        );
      }
    }
  }

  if (onOther) {
    // Eviction (if any) also needs a vault slot before the hop.
    final vaultForHop = _vaultCount(inventory) +
        vaultReserved() +
        (plannedEvictee != null ? 1 : 0);
    if (vaultForHop >= kApplyVaultCapacity) {
      return _ApplyItemPlan(
        rowIndex: rowIndex,
        instanceId: item.instanceId,
        itemHash: item.itemHash,
        bucketHash: live.bucketHash,
        isExotic: live.isExotic,
        prepTransferSteps: const [],
        dequipSteps: const [],
        transferSteps: const [],
        refusalReason: kNoRoomInVaultMessage,
      );
    }
  }

  if (equippedOnOther) {
    final sourceCharacterId = live.characterId!;
    final replacement = _findDequipReplacement(
      inventory: inventory,
      sourceCharacterId: sourceCharacterId,
      bucketHash: live.bucketHash,
      excludeIds: plannedIds,
      sourceClassType: characterClassById[sourceCharacterId],
    );
    if (replacement == null) {
      return _ApplyItemPlan(
        rowIndex: rowIndex,
        instanceId: item.instanceId,
        itemHash: item.itemHash,
        bucketHash: live.bucketHash,
        isExotic: live.isExotic,
        prepTransferSteps: const [],
        dequipSteps: const [],
        transferSteps: const [],
        refusalReason: kCannotUnequipOnOtherCharacterMessage,
      );
    }
    if (replacement.location == 'vault') {
      final otherOccupied =
          _bucketCount(inventory, sourceCharacterId, live.bucketHash);
      if (otherOccupied >= kApplyCharacterBucketCapacity) {
        return _ApplyItemPlan(
          rowIndex: rowIndex,
          instanceId: item.instanceId,
          itemHash: item.itemHash,
          bucketHash: live.bucketHash,
          isExotic: live.isExotic,
          prepTransferSteps: const [],
          dequipSteps: const [],
          transferSteps: const [],
          refusalReason: kCannotUnequipOnOtherCharacterMessage,
        );
      }
      prepTransfers.add(
        TransferItemArgs(
          itemHash: replacement.itemHash,
          instanceId: replacement.instanceId,
          characterId: sourceCharacterId,
          transferToVault: false,
        ),
      );
      _markInventoryMovedToCharacter(
        inventory,
        replacement.instanceId,
        sourceCharacterId,
      );
    }
    dequips.add(
      EquipItemArgs(
        itemHash: replacement.itemHash,
        instanceId: replacement.instanceId,
        characterId: sourceCharacterId,
      ),
    );
  }

  // All refusal checks passed — commit make-room reservation now.
  if (plannedEvictee != null) {
    transfers.add(
      TransferItemArgs(
        itemHash: plannedEvictee.itemHash,
        instanceId: plannedEvictee.instanceId,
        characterId: characterId,
        transferToVault: true,
      ),
    );
    reservedEvicteeIds.add(plannedEvictee.instanceId);
    _markInventoryMovedToVault(inventory, plannedEvictee.instanceId);
  }

  if (onOther) {
    transfers.add(
      TransferItemArgs(
        itemHash: live.itemHash,
        instanceId: item.instanceId,
        characterId: live.characterId!,
        transferToVault: true,
      ),
    );
    transfers.add(
      TransferItemArgs(
        itemHash: live.itemHash,
        instanceId: item.instanceId,
        characterId: characterId,
        transferToVault: false,
      ),
    );
    reserveVault();
    characterReserved[live.bucketHash] =
        (characterReserved[live.bucketHash] ?? 0) + 1;
  } else if (inVault) {
    transfers.add(
      TransferItemArgs(
        itemHash: live.itemHash,
        instanceId: item.instanceId,
        characterId: characterId,
        transferToVault: false,
      ),
    );
    characterReserved[live.bucketHash] =
        (characterReserved[live.bucketHash] ?? 0) + 1;
  } else {
    return _ApplyItemPlan(
      rowIndex: rowIndex,
      instanceId: item.instanceId,
      itemHash: item.itemHash,
      bucketHash: live.bucketHash,
      isExotic: live.isExotic,
      prepTransferSteps: const [],
      dequipSteps: const [],
      transferSteps: const [],
      refusalReason: errorStatusName(kDestinyItemNotFound),
    );
  }

  return _ApplyItemPlan(
    rowIndex: rowIndex,
    instanceId: item.instanceId,
    itemHash: item.itemHash,
    bucketHash: live.bucketHash,
    isExotic: live.isExotic,
    prepTransferSteps: prepTransfers,
    dequipSteps: dequips,
    transferSteps: transfers,
  );
}

/// Runs planned transfers; on 1642/1637 to-character, make-room and retry.
///
/// Returns a fixed failure reason, or null on success. Throws mapped stop
/// errors (in-activity) via the caller catch path for non-no-room failures.
Future<String?> _runTransfersWithMakeRoom({
  required BungieWriteClient writeClient,
  required WriteClientContext ctx,
  required String characterId,
  required _ApplyItemPlan plan,
  required List<ApplyInventoryItem> inventory,
  required Set<String> plannedIds,
  required Set<String> reservedEvicteeIds,
  required int Function() vaultReserved,
  required ApplyDelay sleeper,
  required String itemLabel,
  required void Function(String message, String evicteeId) onMakeRoom,
  required void Function(String from, String to) onPlanItemMoved,
  required void Function() onReachedVault,
}) async {
  // Planned make-room transfers count toward the per-item limit of 2.
  final steps = List<TransferItemArgs>.from(plan.transferSteps);
  var makeRoomAttempts = _plannedMakeRoomCount(plan);

  for (var i = 0; i < steps.length; i++) {
    final step = steps[i];
    try {
      await runWriteWithThrottleBackoff(
        () => writeClient.transferItem(ctx, step),
        delay: sleeper,
      );
      if (step.transferToVault && step.instanceId == plan.instanceId) {
        onReachedVault();
        onPlanItemMoved(
          'character ${step.characterId}',
          'vault',
        );
      } else if (!step.transferToVault &&
          step.instanceId == plan.instanceId) {
        onPlanItemMoved(
          'vault',
          'character ${step.characterId}',
        );
      }
      if (step.instanceId != plan.instanceId && step.transferToVault) {
        final name = _itemDisplayName(inventory, step.instanceId);
        onMakeRoom(kMakeRoomMovedToVaultMessage(name), step.instanceId);
        _markInventoryMovedToVault(inventory, step.instanceId);
      }
    } catch (error) {
      if (!_isNoRoomError(error)) {
        rethrow;
      }
      if (step.transferToVault) {
        // Eviction or hop-to-vault failed for space — surface vault-full text
        // (caller maps to stranded-vault when the pin itself reached vault).
        return kNoRoomInVaultMessage;
      }
      // Destination character bucket full — make room, then retry this step.
      while (true) {
        if (makeRoomAttempts >= kApplyMakeRoomMaxAttempts) {
          return kMakeRoomStillFullMessage(itemLabel);
        }
        final vaultOccupied = _vaultCount(inventory) + vaultReserved();
        if (vaultOccupied >= kApplyVaultCapacity) {
          return kNoRoomInVaultMessage;
        }
        final evictee = _pickMakeRoomEvictee(
          inventory: inventory,
          characterId: characterId,
          bucketHash: plan.bucketHash,
          excludeIds: {
            ...plannedIds,
            ...reservedEvicteeIds,
            plan.instanceId,
          },
        );
        if (evictee == null) {
          return kMakeRoomStillFullMessage(itemLabel);
        }
        try {
          await runWriteWithThrottleBackoff(
            () => writeClient.transferItem(
              ctx,
              TransferItemArgs(
                itemHash: evictee.itemHash,
                instanceId: evictee.instanceId,
                characterId: characterId,
                transferToVault: true,
              ),
            ),
            delay: sleeper,
          );
        } catch (evictError) {
          if (_isNoRoomError(evictError)) {
            return kNoRoomInVaultMessage;
          }
          rethrow;
        }
        makeRoomAttempts += 1;
        reservedEvicteeIds.add(evictee.instanceId);
        // Inventory mutation tracks vault occupancy; skip vaultReserved bump.
        _markInventoryMovedToVault(inventory, evictee.instanceId);
        final name = _itemDisplayName(inventory, evictee.instanceId);
        onMakeRoom(kMakeRoomMovedToVaultMessage(name), evictee.instanceId);
        try {
          await runWriteWithThrottleBackoff(
            () => writeClient.transferItem(ctx, step),
            delay: sleeper,
          );
          if (step.transferToVault && step.instanceId == plan.instanceId) {
            onReachedVault();
            onPlanItemMoved('character ${step.characterId}', 'vault');
          } else if (!step.transferToVault &&
              step.instanceId == plan.instanceId) {
            onPlanItemMoved('vault', 'character ${step.characterId}');
          }
          break;
        } catch (retryError) {
          if (!_isNoRoomError(retryError)) {
            rethrow;
          }
          // Loop for another make-room attempt.
        }
      }
    }
  }
  return null;
}

bool _isNoRoomError(Object error) {
  if (error is BungiePlatformException) {
    return isNoRoomInDestinationErrorCode(error.errorCode);
  }
  return false;
}

int _plannedMakeRoomCount(_ApplyItemPlan plan) {
  var n = 0;
  for (final step in plan.transferSteps) {
    if (step.instanceId != plan.instanceId && step.transferToVault) n += 1;
  }
  return n;
}

/// Pick an unequipped non-plan item to move to vault.
///
/// Rule (deterministic): same character + bucketHash, location == `character`
/// (never equipped / postmaster), not locked, transferable, not excluded;
/// prefer non-exotic, then lowest power, then lowest instanceId.
/// TransferItem only — never lock-state changes.
ApplyInventoryItem? _pickMakeRoomEvictee({
  required List<ApplyInventoryItem> inventory,
  required String characterId,
  required int bucketHash,
  required Set<String> excludeIds,
}) {
  ApplyInventoryItem? best;
  for (final row in inventory) {
    if (row.characterId != characterId) continue;
    if (row.bucketHash != bucketHash) continue;
    if (row.location != 'character') continue;
    if (row.location == 'postmaster' ||
        row.bucketHash == kPostmasterBucketHash) {
      continue;
    }
    if (row.isLocked) continue;
    if (!row.isTransferable) continue;
    if (excludeIds.contains(row.instanceId)) continue;
    if (best == null) {
      best = row;
      continue;
    }
    if (row.isExotic != best.isExotic) {
      if (!row.isExotic) best = row;
      continue;
    }
    if (row.power != best.power) {
      if (row.power < best.power) best = row;
      continue;
    }
    if (row.instanceId.compareTo(best.instanceId) < 0) {
      best = row;
    }
  }
  return best;
}

String _itemDisplayName(
  List<ApplyInventoryItem> inventory,
  String instanceId,
) {
  for (final row in inventory) {
    if (row.instanceId != instanceId) continue;
    final name = row.name.trim();
    if (name.isNotEmpty) return name;
    break;
  }
  return 'item';
}

void _markInventoryMovedToVault(
  List<ApplyInventoryItem> inventory,
  String instanceId,
) {
  for (var i = 0; i < inventory.length; i++) {
    final row = inventory[i];
    if (row.instanceId != instanceId) continue;
    inventory[i] = ApplyInventoryItem(
      instanceId: row.instanceId,
      itemHash: row.itemHash,
      location: 'vault',
      bucketHash: row.bucketHash,
      isExotic: row.isExotic,
      power: row.power,
      name: row.name,
      isLocked: row.isLocked,
      isTransferable: row.isTransferable,
      classType: row.classType,
    );
    return;
  }
}

void _markInventoryMovedToCharacter(
  List<ApplyInventoryItem> inventory,
  String instanceId,
  String characterId,
) {
  for (var i = 0; i < inventory.length; i++) {
    final row = inventory[i];
    if (row.instanceId != instanceId) continue;
    inventory[i] = ApplyInventoryItem(
      instanceId: row.instanceId,
      itemHash: row.itemHash,
      location: 'character',
      bucketHash: row.bucketHash,
      characterId: characterId,
      isExotic: row.isExotic,
      power: row.power,
      name: row.name,
      isLocked: row.isLocked,
      isTransferable: row.isTransferable,
      classType: row.classType,
    );
    return;
  }
}

int _bucketCount(
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
  return count;
}

int _vaultCount(List<ApplyInventoryItem> inventory) {
  var count = 0;
  for (final row in inventory) {
    if (row.location == 'vault') count += 1;
  }
  return count;
}

/// Prefer unequipped non-exotic same-bucket on [sourceCharacterId], then vault.
///
/// Skips exotics so the other character's one-exotic-weapon / one-exotic-armor
/// rule cannot be broken by the replacement. Vault armor must match
/// [sourceClassType] when the item declares a class.
ApplyInventoryItem? _findDequipReplacement({
  required List<ApplyInventoryItem> inventory,
  required String sourceCharacterId,
  required int bucketHash,
  required Set<String> excludeIds,
  String? sourceClassType,
}) {
  ApplyInventoryItem? vaultPick;
  for (final row in inventory) {
    if (row.bucketHash != bucketHash) continue;
    if (row.isExotic) continue;
    if (excludeIds.contains(row.instanceId)) continue;
    if (row.location == 'character' &&
        row.characterId == sourceCharacterId) {
      return row;
    }
    if (row.location != 'vault') continue;
    if (!row.isTransferable) continue;
    if (!_itemClassCompatible(row, sourceClassType)) continue;
    vaultPick ??= row;
  }
  return vaultPick;
}

bool _itemClassCompatible(ApplyInventoryItem row, String? characterClass) {
  final itemClass = row.classType?.trim() ?? '';
  if (itemClass.isEmpty || itemClass.toLowerCase() == 'unknown') {
    return true;
  }
  final guardian = characterClass?.trim() ?? '';
  if (guardian.isEmpty) return false;
  return itemClass.toLowerCase() == guardian.toLowerCase();
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
      statusText: bungieHttpFailureMessage(error.statusCode),
      stopFurtherEquips: false,
      isInActivity: false,
    );
  }
  // Never surface Exception.toString() / tokens on Apply rows.
  return const _MappedWriteError(
    statusText: kGenericApplyFailureMessage,
    stopFurtherEquips: false,
    isInActivity: false,
  );
}
