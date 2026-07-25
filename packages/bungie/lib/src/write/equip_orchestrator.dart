import 'package:destiny2_domain/destiny2_domain.dart';

import 'write_client.dart';

/// One executed equip step with success/failure.
class EquipStepResult {
  const EquipStepResult({
    required this.step,
    required this.ok,
    this.error,
  });

  final PlannedEquipStep step;
  final bool ok;
  final String? error;

  String get id => step.id;
  EquipStepKind get kind => step.kind;
  String? get slot => step.slot;
  int? get itemHash => step.itemHash;
  String? get instanceId => step.instanceId;
  bool? get transferToVault => step.transferToVault;
  List<int>? get artifactConfig => step.artifactConfig;
}

/// Aggregated best-effort equip run status (no rollback).
class EquipStatus {
  const EquipStatus({
    required this.steps,
    required this.completed,
    required this.failed,
  });

  final List<EquipStepResult> steps;
  final int completed;
  final int failed;
}

EquipStatus _summarize(List<EquipStepResult> steps) {
  var completed = 0;
  var failed = 0;
  for (final step in steps) {
    if (step.ok) {
      completed += 1;
    } else {
      failed += 1;
    }
  }
  return EquipStatus(steps: steps, completed: completed, failed: failed);
}

Future<EquipStepResult> _runStep(
  BungieWriteClient client,
  WriteClientContext ctx,
  String characterId,
  PlannedEquipStep step,
) async {
  try {
    switch (step.kind) {
      case EquipStepKind.transfer:
        final instanceId = step.instanceId;
        final itemHash = step.itemHash;
        final transferToVault = step.transferToVault;
        if (instanceId == null ||
            itemHash == null ||
            transferToVault == null) {
          throw StateError(
            'Transfer step missing instanceId, itemHash, or transferToVault',
          );
        }
        await client.transferItem(
          ctx,
          TransferItemArgs(
            itemHash: itemHash,
            instanceId: instanceId,
            characterId: characterId,
            transferToVault: transferToVault,
          ),
        );
      case EquipStepKind.equip:
        final instanceId = step.instanceId;
        final itemHash = step.itemHash;
        if (instanceId == null || itemHash == null) {
          throw StateError('Equip step missing instanceId or itemHash');
        }
        await client.equipItem(
          ctx,
          EquipItemArgs(
            itemHash: itemHash,
            instanceId: instanceId,
            characterId: characterId,
          ),
        );
      case EquipStepKind.artifact:
        final itemHash = step.itemHash;
        if (itemHash == null) {
          throw StateError('Artifact step missing hash');
        }
        await client.applyArtifactConfig(
          ctx,
          ApplyArtifactArgs(
            characterId: characterId,
            artifactHash: itemHash,
            config: step.artifactConfig ?? const [],
          ),
        );
      case EquipStepKind.fashion:
        final itemHash = step.itemHash;
        final slot = step.slot;
        if (itemHash == null || slot == null) {
          throw StateError('Fashion step missing slot or hash');
        }
        await client.applyFashionSlot(
          ctx,
          ApplyFashionArgs(
            characterId: characterId,
            slot: slot,
            itemHash: itemHash,
            instanceId: step.instanceId,
          ),
        );
    }
    return EquipStepResult(step: step, ok: true);
  } catch (error) {
    final message = error is Exception || error is Error
        ? error.toString().replaceFirst(RegExp(r'^(Exception|Bad state): '), '')
        : 'Equip step failed';
    // Prefer Error.message-like text when available.
    final clean = error is StateError
        ? error.message
        : (error is Exception
            ? error.toString().replaceFirst(RegExp(r'^Exception: '), '')
            : message);
    return EquipStepResult(step: step, ok: false, error: clean);
  }
}

/// Best-effort: run [plan] in order; never roll back prior ok steps.
///
/// Continues after failures so partial status reports every step.
Future<EquipStatus> executeEquipPlan(
  BungieWriteClient client,
  WriteClientContext ctx,
  String characterId,
  List<PlannedEquipStep> plan,
) async {
  final results = <EquipStepResult>[];
  for (final step in plan) {
    results.add(await _runStep(client, ctx, characterId, step));
  }
  return _summarize(results);
}
