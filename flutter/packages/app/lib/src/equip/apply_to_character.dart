/// Sequential Apply-to-character for a prepared item list (Builds mock path).
///
/// Reuses [executeEquipPlan] + [BungieWriteClient] equip/transfer only.
/// Progress is reported one item at a time (DIM-style).
library;

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_domain/destiny2_domain.dart';

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
  }) {
    return ApplyItemProgress(
      id: id,
      label: label,
      state: state ?? this.state,
      reason: reason ?? this.reason,
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

/// Runs equip steps sequentially with inline progress (no confirm dialog).
///
/// Builds a plan of [EquipStepKind.equip] only (one change at a time). Failures
/// do not stop later items.
Future<ApplyToCharacterProgress> applyToCharacter({
  required BungieWriteClient writeClient,
  required WriteClientContext ctx,
  required String characterId,
  required List<ApplyToCharacterItem> items,
  void Function(ApplyToCharacterProgress progress)? onProgress,
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

  void emit({
    required int index,
    required bool running,
    int applied = 0,
    int failed = 0,
    String? summary,
  }) {
    final snap = ApplyToCharacterProgress(
      items: List<ApplyItemProgress>.unmodifiable(rows),
      currentIndex: index.clamp(0, rows.isEmpty ? 0 : rows.length - 1),
      total: rows.length,
      running: running,
      appliedCount: applied,
      failedCount: failed,
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

  final plan = <PlannedEquipStep>[
    for (final item in items)
      PlannedEquipStep(
        id: item.id,
        kind: EquipStepKind.equip,
        slot: item.slot,
        itemHash: item.itemHash,
        instanceId: item.instanceId,
      ),
  ];

  final status = await executeEquipPlan(
    writeClient,
    ctx,
    characterId,
    plan,
    onProgress: ({
      required int index,
      required int total,
      required PlannedEquipStep step,
      EquipStepResult? result,
    }) async {
      if (result == null) {
        rows[index] = rows[index].copyWith(state: ApplyItemState.applying);
        emit(index: index, running: true);
        return;
      }
      if (result.ok) {
        rows[index] = rows[index].copyWith(state: ApplyItemState.done);
      } else {
        final reason = (result.error ?? 'failed').trim();
        rows[index] = rows[index].copyWith(
          state: ApplyItemState.failed,
          reason: reason.isEmpty ? 'failed' : reason,
        );
      }
      emit(
        index: index,
        running: true,
        applied: rows.where((r) => r.state == ApplyItemState.done).length,
        failed: rows.where((r) => r.state == ApplyItemState.failed).length,
      );
    },
  );

  final summary = '${status.completed} applied, ${status.failed} failed';
  final done = ApplyToCharacterProgress(
    items: List<ApplyItemProgress>.unmodifiable(rows),
    currentIndex: rows.isEmpty ? 0 : rows.length - 1,
    total: rows.length,
    running: false,
    appliedCount: status.completed,
    failedCount: status.failed,
    summary: summary,
  );
  onProgress?.call(done);
  return done;
}
