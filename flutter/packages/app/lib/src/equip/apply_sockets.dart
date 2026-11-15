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

  for (var i = 0; i < steps.length; i++) {
    final step = steps[i];
    final rowIndex = rows.length;
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
      }
      rows[rowIndex] = rows[rowIndex].copyWith(
        state: ApplyItemState.done,
        clearReason: true,
      );
      emit(index: rowIndex, running: true);
    } catch (error) {
      final mapped = _mapWriteError(error);
      if (mapped.isInActivity) {
        rows[rowIndex] = rows[rowIndex].copyWith(
          state: ApplyItemState.failed,
          reason: kInActivityEquipMessage,
        );
        emit(index: rowIndex, running: true);
        _appendFailedPlugSteps(
          rows,
          steps.sublist(i + 1),
          reason: kInActivityEquipMessage,
        );
        emit(index: rows.length - 1, running: true);
        return true;
      }

      // Plug failures: fixed planner text only — never e.toString() / raw Bungie.
      var reason = kApplySocketChangeFailedMessage;
      final clearId = step.requiresClearStepId;
      final clear = clearId == null ? null : completedClears[clearId];
      final restoreHash = step.restorePlugHash;
      final restoreSocket = step.restoreSocketIndex;
      final restoreItem = step.restoreItemInstanceId;
      if (clear != null &&
          restoreHash != null &&
          restoreSocket != null &&
          restoreItem != null &&
          restoreItem.isNotEmpty) {
        try {
          await runWriteWithThrottleBackoff(
            () => writeClient.insertSocketPlugFree(
              ctx,
              InsertSocketPlugFreeArgs(
                itemId: restoreItem,
                socketIndex: restoreSocket,
                plugItemHash: restoreHash,
                characterId: characterId,
              ),
            ),
            delay: sleeper,
          );
          reason = kApplySocketRestoredMessage;
        } catch (_) {
          reason = kApplySocketRestoreFailedMessage;
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
