/// Finish-gaps display helpers for mobile compose (DART-057).
///
/// Pure [evaluateFinishGaps] lives in destiny2_domain. Soft never auto-applies.
/// Mobile does not ship equip/DIM CTAs (matrix N/A) — display readiness only.
library;

import 'package:destiny2_domain/destiny2_domain.dart';

/// Policy caption (parity with desktop finish-complete ∧ equip-ready).
const String kFinishGapsPolicyCaption =
    'Finish categories (armor / weapons / mods). On Windows/Jaspr, equip and '
    'DIM export require finish-complete AND equip-ready. Soft never auto-applies.';

/// Human status label for a finish gap row.
String formatFinishGapStatusLabel(FinishGapStatus status) {
  switch (status) {
    case FinishGapStatus.satisfied:
      return 'Complete';
    case FinishGapStatus.needsSet:
      return 'Needs covering set';
    case FinishGapStatus.needsFill:
      return 'Needs fill';
    case FinishGapStatus.captureAvailable:
      return 'Capture available';
  }
}

/// Category row summary: "Armor: Needs covering set".
String formatFinishGapRowSummary(FinishGap gap) {
  final cat = finishCategoryLabel(gap.category);
  final status = formatFinishGapStatusLabel(gap.status);
  if (gap.status == FinishGapStatus.needsFill && gap.emptySlots.isNotEmpty) {
    return '$cat: $status (${gap.emptySlots.join(', ')})';
  }
  if (gap.status == FinishGapStatus.satisfied) {
    return '$cat: $status (${gap.filledSlotCount}/${gap.requiredSlotCount})';
  }
  if (gap.coveringSetName != null && gap.coveringSetName!.isNotEmpty) {
    return '$cat: $status — ${gap.coveringSetName}';
  }
  return '$cat: $status';
}

/// Aggregate complete chip text.
String formatFinishGapsCompleteSummary(FinishGapsResult result) {
  if (result.complete) return 'Finish complete';
  final next = result.nextActionable;
  if (next == null) return 'Finish incomplete';
  return 'Finish incomplete — next: ${finishCategoryLabel(next.category)}';
}

/// Build domain finish input from wire fields (host adapters).
EvaluateFinishGapsInput buildFinishGapsInput({
  required String variantId,
  required bool isDefaultVariant,
  required List<FinishAttachmentInput> attachments,
  required Map<String, FinishEquipmentClaim?> equipment,
  bool hasModCoverage = false,
}) {
  return EvaluateFinishGapsInput(
    variantId: variantId,
    isDefaultVariant: isDefaultVariant,
    attachments: attachments,
    equipment: equipment,
    hasModCoverage: hasModCoverage,
  );
}

AttachmentMode finishAttachmentModeFromWire(String mode) {
  return mode == AttachmentMode.snapshot.wireName
      ? AttachmentMode.snapshot
      : AttachmentMode.live;
}
