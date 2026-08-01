/// Finish-gaps display + CTA policy helpers (DART-057 / GAP-FEAT-06).
///
/// Pure [evaluateFinishGaps] lives in destiny2_domain. Soft never auto-applies.
/// Equip/export CTAs require finish-complete AND equip-ready.
library;

import 'package:destiny2_domain/destiny2_domain.dart';

/// Policy caption shown above finish + equip/export.
const String kFinishGapsPolicyCaption =
    'Finish categories (armor / weapons / mods). One-tap Create or Capture, '
    'then fill empty slots. Equip Apply and DIM export require finish-complete '
    'AND equip-ready. Soft never auto-applies.';

/// Finish walkthrough advisory (BR-BLD-008).
const String kFinishWalkthroughCaption =
    'Slot-first: Create (inherited name, no tags) or Capture, then fill first '
    'empty required slot. Skip for now leaves gaps unfinished. Soft never '
    'auto-applies.';

/// Caption when CTA blocked solely by finish incomplete.
const String kFinishIncompleteCtaCaption =
    'Finish incomplete — equip/export blocked until armor, weapons, and mods '
    'categories are complete (and equip-ready).';

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

String formatFinishGapsCompleteSummary(FinishGapsResult result) {
  if (result.complete) return 'Finish complete';
  final next = result.nextActionable;
  if (next == null) return 'Finish incomplete';
  return 'Finish incomplete — next: ${finishCategoryLabel(next.category)}';
}

/// Product policy (Next FinishTab parity): finish-complete AND equip-ready.
bool canProceedWithFinishAndEquipReady({
  required bool finishComplete,
  required bool equipReady,
}) {
  return finishComplete && equipReady;
}

AttachmentMode finishAttachmentModeFromWire(String mode) {
  return mode == AttachmentMode.snapshot.wireName
      ? AttachmentMode.snapshot
      : AttachmentMode.live;
}
