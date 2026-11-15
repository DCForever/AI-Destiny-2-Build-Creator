part of 'apply_to_character.dart';

/// Executes [plan] after gear moves/equips.
///
/// Returns whether an in-activity (or equip-not-possible) error stopped the
/// remaining socket steps.
Future<bool> _runApplySocketPhase({
  required BungieWriteClient writeClient,
  required WriteClientContext ctx,
  required String characterId,
  required ApplySocketPlan plan,
  required List<ApplyItemProgress> rows,
  required void Function({required int index, required bool running, String? summary})
      emit,
  required ApplyDelay sleeper,
}) async {
  if (plan.subclassMissingReason != null) {
    rows.add(
      ApplyItemProgress(
        id: 'subclass:missing',
        label: 'Subclass',
        state: ApplyItemState.failed,
        reason: plan.subclassMissingReason,
        slot: 'subclass',
      ),
    );
    emit(index: rows.length - 1, running: true);
    final stopped = await _runPlugSteps(
      writeClient: writeClient,
      ctx: ctx,
      characterId: characterId,
      steps: plan.armorMods,
      rows: rows,
      emit: emit,
      sleeper: sleeper,
    );
    return stopped;
  }

  final subclass = plan.subclass;
  if (subclass != null && !plan.subclassAlreadyEquipped) {
    final rowIndex = rows.length;
    rows.add(
      ApplyItemProgress(
        id: subclass.id,
        label: formatApplyOutcomeLabel(
          rawLabel: subclass.label,
          slot: 'subclass',
        ),
        state: ApplyItemState.applying,
        itemHash: subclass.itemHash,
        instanceId: subclass.instanceId,
        slot: 'subclass',
      ),
    );
    emit(index: rowIndex, running: true);
    try {
      await runWriteWithThrottleBackoff(
        () => writeClient.equipItem(
          ctx,
          EquipItemArgs(
            itemHash: subclass.itemHash,
            instanceId: subclass.instanceId,
            characterId: characterId,
          ),
        ),
        delay: sleeper,
      );
      rows[rowIndex] = rows[rowIndex].copyWith(
        state: ApplyItemState.done,
        clearReason: true,
      );
      emit(index: rowIndex, running: true);
    } catch (error) {
      final mapped = _mapWriteError(error);
      final reason =
          mapped.isInActivity ? kInActivityEquipMessage : mapped.statusText;
      rows[rowIndex] = rows[rowIndex].copyWith(
        state: ApplyItemState.failed,
        reason: reason,
      );
      emit(index: rowIndex, running: true);
      if (mapped.stopFurtherEquips) {
        _appendFailedPlugSteps(
          rows,
          [...plan.subclassPlugs, ...plan.armorMods],
          reason: reason,
        );
        emit(index: rows.length - 1, running: true);
        return true;
      }
      _appendFailedPlugSteps(
        rows,
        [...plan.subclassPlugs, ...plan.armorMods],
        reason: 'Subclass not equipped',
      );
      emit(index: rows.length - 1, running: true);
      return false;
    }
  } else if (subclass != null && plan.subclassAlreadyEquipped) {
    rows.add(
      ApplyItemProgress(
        id: subclass.id,
        label: formatApplyOutcomeLabel(
          rawLabel: subclass.label,
          slot: 'subclass',
        ),
        state: ApplyItemState.done,
        itemHash: subclass.itemHash,
        instanceId: subclass.instanceId,
        slot: 'subclass',
      ),
    );
    emit(index: rows.length - 1, running: true);
  }

  final stoppedOnSubclass = await _runPlugSteps(
    writeClient: writeClient,
    ctx: ctx,
    characterId: characterId,
    steps: plan.subclassPlugs,
    rows: rows,
    emit: emit,
    sleeper: sleeper,
  );
  if (stoppedOnSubclass) {
    _appendFailedPlugSteps(
      rows,
      plan.armorMods,
      reason: kInActivityEquipMessage,
    );
    emit(index: rows.length - 1, running: true);
    return true;
  }

  return _runPlugSteps(
    writeClient: writeClient,
    ctx: ctx,
    characterId: characterId,
    steps: plan.armorMods,
    rows: rows,
    emit: emit,
    sleeper: sleeper,
  );
}

Future<bool> _runPlugSteps({
  required BungieWriteClient writeClient,
  required WriteClientContext ctx,
  required String characterId,
  required List<ApplyPlugStep> steps,
  required List<ApplyItemProgress> rows,
  required void Function({required int index, required bool running, String? summary})
      emit,
  required ApplyDelay sleeper,
}) async {
  final completedClears = <String, ApplyPlugStep>{};
  final failedClearIds = <String>{};
  // Clears whose original plug has not yet been restored (or consumed by a
  // successful insert). Restored on insert failure or in-activity.
  final pendingRestoreClears = <String, ApplyPlugStep>{};

  for (var i = 0; i < steps.length; i++) {
    final step = steps[i];
    final rowIndex = rows.length;

    // Any failed clear in the chain stops its matching insert.
    final requiredClears = step.clearStepIdsRequired;
    if (requiredClears.any(failedClearIds.contains)) {
      rows.add(
        ApplyItemProgress(
          id: step.id,
          label: step.label,
          state: ApplyItemState.failed,
          reason: kApplySocketClearFailedMessage,
        ),
      );
      emit(index: rowIndex, running: true);
      continue;
    }

    if (step.skipReason != null) {
      rows.add(
        ApplyItemProgress(
          id: step.id,
          label: step.label,
          state: ApplyItemState.failed,
          reason: step.skipReason,
        ),
      );
      emit(index: rowIndex, running: true);
      continue;
    }
    if (!step.shouldCall) {
      rows.add(
        ApplyItemProgress(
          id: step.id,
          label: step.label,
          state: ApplyItemState.done,
        ),
      );
      emit(index: rowIndex, running: true);
      continue;
    }

    rows.add(
      ApplyItemProgress(
        id: step.id,
        label: step.label,
        state: ApplyItemState.applying,
      ),
    );
    emit(index: rowIndex, running: true);

    try {
      await runWriteWithThrottleBackoff(
        () => writeClient.insertSocketPlugFree(
          ctx,
          InsertSocketPlugFreeArgs(
            itemId: step.itemInstanceId,
            socketIndex: step.socketIndex,
            plugItemHash: step.plugItemHash,
            characterId: characterId,
          ),
        ),
        delay: sleeper,
      );
      if (step.kind == ApplyPlugKind.armorModClear) {
        completedClears[step.id] = step;
        pendingRestoreClears[step.id] = step;
      } else if (step.kind == ApplyPlugKind.armorMod) {
        // Successful insert consumes its clears — no restore needed.
        for (final clearId in step.clearStepIdsRequired) {
          pendingRestoreClears.remove(clearId);
        }
      }
      rows[rowIndex] = rows[rowIndex].copyWith(
        state: ApplyItemState.done,
        clearReason: true,
      );
      emit(index: rowIndex, running: true);
    } catch (error) {
      final mapped = _mapWriteError(error);
      if (mapped.isInActivity) {
        // In-activity after a clear: restore every pending clear, then stop.
        final pendingSnapshot =
            Map<String, ApplyPlugStep>.from(pendingRestoreClears);
        final restored = await _restorePendingClears(
          writeClient: writeClient,
          ctx: ctx,
          characterId: characterId,
          pending: pendingRestoreClears,
          sleeper: sleeper,
        );
        pendingRestoreClears.clear();
        if (restored.attempted && !restored.allOk) {
          _markClearRowsRestoreFailed(rows, pendingSnapshot.keys);
        }
        rows[rowIndex] = rows[rowIndex].copyWith(
          state: ApplyItemState.failed,
          reason: restored.attempted
              ? (restored.allOk
                  ? kApplySocketRestoredMessage
                  : kApplySocketRestoreFailedMessage)
              : kInActivityEquipMessage,
        );
        emit(index: rowIndex, running: true);
        if (step.kind == ApplyPlugKind.armorModClear) {
          failedClearIds.add(step.id);
        }
        _appendFailedPlugSteps(
          rows,
          steps.sublist(i + 1),
          reason: kInActivityEquipMessage,
        );
        emit(index: rows.length - 1, running: true);
        return true;
      }

      // Plug failures: fixed planner text only — never e.toString() / raw Bungie.
      var reason = step.kind == ApplyPlugKind.armorModClear
          ? kApplySocketClearFailedMessage
          : kApplySocketChangeFailedMessage;
      if (step.kind == ApplyPlugKind.armorModClear) {
        failedClearIds.add(step.id);
      }

      final targets = step.restoreTargets;
      if (targets.isNotEmpty || pendingRestoreClears.isNotEmpty) {
        final toRestore = targets.isNotEmpty
            ? targets
            : [
                for (final clear in pendingRestoreClears.values)
                  if (clear.currentPlugHash != null)
                    ApplySocketRestore(
                      clearStepId: clear.id,
                      itemInstanceId: clear.itemInstanceId,
                      socketIndex: clear.socketIndex,
                      plugItemHash: clear.currentPlugHash!,
                    ),
              ];
        final restoreResult = await _restoreSocketTargets(
          writeClient: writeClient,
          ctx: ctx,
          characterId: characterId,
          targets: toRestore,
          sleeper: sleeper,
        );
        for (final t in toRestore) {
          pendingRestoreClears.remove(t.clearStepId);
        }
        if (restoreResult.attempted) {
          reason = restoreResult.allOk
              ? kApplySocketRestoredMessage
              : kApplySocketRestoreFailedMessage;
          if (!restoreResult.allOk) {
            _markClearRowsRestoreFailed(
              rows,
              toRestore.map((t) => t.clearStepId),
            );
          }
        }
      }

      rows[rowIndex] = rows[rowIndex].copyWith(
        state: ApplyItemState.failed,
        reason: reason,
      );
      emit(index: rowIndex, running: true);
    }
  }
  return false;
}

class _RestoreOutcome {
  const _RestoreOutcome({required this.attempted, required this.allOk});
  final bool attempted;
  final bool allOk;
}

Future<_RestoreOutcome> _restorePendingClears({
  required BungieWriteClient writeClient,
  required WriteClientContext ctx,
  required String characterId,
  required Map<String, ApplyPlugStep> pending,
  required ApplyDelay sleeper,
}) async {
  if (pending.isEmpty) {
    return const _RestoreOutcome(attempted: false, allOk: true);
  }
  final targets = <ApplySocketRestore>[
    for (final clear in pending.values)
      if (clear.currentPlugHash != null)
        ApplySocketRestore(
          clearStepId: clear.id,
          itemInstanceId: clear.itemInstanceId,
          socketIndex: clear.socketIndex,
          plugItemHash: clear.currentPlugHash!,
        ),
  ];
  return _restoreSocketTargets(
    writeClient: writeClient,
    ctx: ctx,
    characterId: characterId,
    targets: targets,
    sleeper: sleeper,
  );
}

/// Restores every cleared socket (covers multi-clear frees).
Future<_RestoreOutcome> _restoreSocketTargets({
  required BungieWriteClient writeClient,
  required WriteClientContext ctx,
  required String characterId,
  required List<ApplySocketRestore> targets,
  required ApplyDelay sleeper,
}) async {
  if (targets.isEmpty) {
    return const _RestoreOutcome(attempted: false, allOk: true);
  }
  var allOk = true;
  for (final target in targets) {
    if (target.itemInstanceId.isEmpty) {
      allOk = false;
      continue;
    }
    try {
      await runWriteWithThrottleBackoff(
        () => writeClient.insertSocketPlugFree(
          ctx,
          InsertSocketPlugFreeArgs(
            itemId: target.itemInstanceId,
            socketIndex: target.socketIndex,
            plugItemHash: target.plugItemHash,
            characterId: characterId,
          ),
        ),
        delay: sleeper,
      );
    } catch (_) {
      allOk = false;
    }
  }
  return _RestoreOutcome(attempted: true, allOk: allOk);
}

void _appendFailedPlugSteps(
  List<ApplyItemProgress> rows,
  List<ApplyPlugStep> pending, {
  required String reason,
}) {
  for (final step in pending) {
    if (rows.any((r) => r.id == step.id)) continue;
    rows.add(
      ApplyItemProgress(
        id: step.id,
        label: step.label,
        state: ApplyItemState.failed,
        reason: reason,
      ),
    );
  }
}

/// When a restore fails, mark the earlier clear row(s) so the UI shows the
/// cleared socket was not put back (Skeptic should-fix).
void _markClearRowsRestoreFailed(
  List<ApplyItemProgress> rows,
  Iterable<String> clearStepIds,
) {
  final ids = clearStepIds.where((id) => id.isNotEmpty).toSet();
  if (ids.isEmpty) return;
  for (var i = 0; i < rows.length; i++) {
    if (!ids.contains(rows[i].id)) continue;
    rows[i] = rows[i].copyWith(
      state: ApplyItemState.failed,
      reason: kApplySocketRestoreFailedMessage,
    );
  }
}
