/// Pure next-slot / post-mutation walkthrough helpers for finish flow.
///
/// Mirrors TypeScript `src/lib/builds/finishNextSlot.ts`.
library;

import '../models/equipment.dart';
import 'finish_gaps.dart';

/// Finish walkthrough step (TS `FinishWalkthroughStep`).
enum FinishWalkthroughStep {
  overview('overview'),
  category('category'),
  fill('fill'),
  armorOptimize('armor_optimize'),
  done('done');

  const FinishWalkthroughStep(this.wireName);
  final String wireName;

  static FinishWalkthroughStep? tryParse(String wire) {
    for (final v in FinishWalkthroughStep.values) {
      if (v.wireName == wire) return v;
    }
    return null;
  }
}

/// Target step after a finish mutation (TS `FinishPostMutationTarget`).
class FinishPostMutationTarget {
  const FinishPostMutationTarget({
    required this.step,
    this.fillSlot,
    this.category,
  });

  final FinishWalkthroughStep step;
  final String? fillSlot;
  final FinishCategory? category;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FinishPostMutationTarget &&
        other.step == step &&
        other.fillSlot == fillSlot &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(step, fillSlot, category);

  @override
  String toString() =>
      'FinishPostMutationTarget(step: $step, fillSlot: $fillSlot, category: $category)';
}

/// Map finish category to set type (identity for armor/weapon/mod).
SetType finishCategoryToSetType(FinishCategory category) {
  switch (category) {
    case FinishCategory.armor:
      return SetType.armor;
    case FinishCategory.weapon:
      return SetType.weapon;
    case FinishCategory.mod:
      return SetType.mod;
  }
}

/// First empty required slot from a gap's emptySlots list order.
String? firstEmptyRequiredSlot(FinishGap gap) {
  if (gap.emptySlots.isEmpty) return null;
  return gap.emptySlots.first;
}

/// Live covering armor set should open optimizer workspace (product 031).
bool shouldOpenArmorOptimize(FinishGap? gap) {
  return gap != null &&
      gap.category == FinishCategory.armor &&
      gap.coveringSetId != null &&
      gap.coveringMode == AttachmentMode.live &&
      gap.status != FinishGapStatus.satisfied;
}

/// Input for [resolvePostMutationStep].
class ResolvePostMutationStepInput {
  const ResolvePostMutationStepInput({
    this.gap,
    this.autoEnterFill = true,
    this.preferArmorOptimize = true,
  });

  final FinishGap? gap;
  final bool autoEnterFill;

  /// When true (default), armor live covering opens optimizer instead of fill.
  final bool preferArmorOptimize;
}

/// Resolve walkthrough step after a finish mutation.
FinishPostMutationTarget resolvePostMutationStep(
  ResolvePostMutationStepInput input,
) {
  final gap = input.gap;
  if (gap == null || gap.status == FinishGapStatus.satisfied) {
    return const FinishPostMutationTarget(
      step: FinishWalkthroughStep.overview,
      fillSlot: null,
      category: null,
    );
  }

  if (input.preferArmorOptimize && shouldOpenArmorOptimize(gap)) {
    return const FinishPostMutationTarget(
      step: FinishWalkthroughStep.armorOptimize,
      fillSlot: null,
      category: FinishCategory.armor,
    );
  }

  if (gap.status == FinishGapStatus.needsFill) {
    if (gap.coveringMode == AttachmentMode.snapshot) {
      return FinishPostMutationTarget(
        step: FinishWalkthroughStep.category,
        fillSlot: null,
        category: gap.category,
      );
    }
    if (gap.coveringMode == AttachmentMode.live && gap.coveringSetId != null) {
      final slot = firstEmptyRequiredSlot(gap);
      if (slot != null && input.autoEnterFill) {
        return FinishPostMutationTarget(
          step: FinishWalkthroughStep.fill,
          fillSlot: slot,
          category: gap.category,
        );
      }
      return FinishPostMutationTarget(
        step: FinishWalkthroughStep.category,
        fillSlot: null,
        category: gap.category,
      );
    }
    return FinishPostMutationTarget(
      step: FinishWalkthroughStep.category,
      fillSlot: null,
      category: gap.category,
    );
  }

  return FinishPostMutationTarget(
    step: FinishWalkthroughStep.category,
    fillSlot: null,
    category: gap.category,
  );
}

/// Whether finish create/capture actions should show for this status.
bool showFinishCreateActions(FinishGapStatus status) {
  return status == FinishGapStatus.needsSet ||
      status == FinishGapStatus.captureAvailable;
}
