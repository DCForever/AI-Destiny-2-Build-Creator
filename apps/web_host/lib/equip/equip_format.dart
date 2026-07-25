/// Display helpers for equip-ready / equip Apply UI (DART-047).
library;

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_domain/destiny2_domain.dart';

/// Advisory: soft never auto-applies; equip uses owned pins only.
const String kEquipSoftAdvisoryCaption =
    'Soft suggestions never auto-apply. Equip uses owned instance pins only.';

/// Caption for empty-combat gaps confirm dialog.
const String kEquipGapsConfirmCaption =
    'Some combat slots are empty. Apply owned pins to the character anyway?';

/// Human label for one pin status (wishlist / pinned / stale).
String formatPinStatusLabel(PinStatus status) {
  final slot = status.slot.wireName;
  switch (status.status) {
    case PinStatusKind.wishlist:
      return '$slot: wishlist (needs owned instance pin)';
    case PinStatusKind.pinned:
      return '$slot: owned pin';
    case PinStatusKind.stale:
      final reason = status.reason?.wireName ?? 'stale';
      return '$slot: stale ($reason)';
  }
}

/// Short readiness summary for status chips.
String formatEquipReadySummary(EquipReadyResult result) {
  if (result.equipReady) return 'Equip-ready';
  if (result.pinStatuses.isEmpty) return 'Not equip-ready (no combat pins)';
  final gaps = result.pinStatuses
      .where((s) => s.status != PinStatusKind.pinned)
      .length;
  return 'Not equip-ready ($gaps gap${gaps == 1 ? '' : 's'})';
}

/// Empty combat slot wire names (no applied claim).
List<String> emptyCombatSlotWires(Map<EquipmentSlot, SlotClaim> equipment) {
  final out = <String>[];
  for (final slot in EquipmentSlot.combatSlots) {
    if (!equipment.containsKey(slot)) {
      out.add(slot.wireName);
    }
  }
  return out;
}

/// Summary line for empty combat gaps confirm.
String formatEmptyCombatGapsSummary(List<String> emptySlots) {
  if (emptySlots.isEmpty) return 'All combat slots have applied pins.';
  return 'Empty combat slots: ${emptySlots.join(', ')}';
}

/// Whether Apply CTA should be enabled (UI gate; controller still re-asserts).
///
/// DART-057: when [finishComplete] is provided, requires finish-complete AND
/// equip-ready (Next FinishTab policy). Omit or pass true for equip-ready-only.
bool canEnableEquipCta({
  required bool signedIn,
  required bool equipReady,
  required String? characterId,
  required bool equipping,
  required bool loading,
  bool finishComplete = true,
}) {
  if (!signedIn) return false;
  if (equipping || loading) return false;
  if (!finishComplete) return false;
  if (!equipReady) return false;
  if (characterId == null || characterId.isEmpty) return false;
  return true;
}

/// Character dropdown label.
String formatCharacterOptionLabel(CharacterSummary c) {
  return '${c.classType} · ${c.light}';
}

/// One step line for the post-equip report.
String formatEquipStepReportLine(EquipStepResult step) {
  final kind = step.kind.wireName;
  final slot = step.slot != null ? ' ${step.slot}' : '';
  if (step.ok) {
    return '✓ $kind$slot';
  }
  final err = step.error?.trim();
  final detail = (err == null || err.isEmpty) ? 'failed' : err;
  return '✗ $kind$slot — $detail';
}

/// Aggregate completed/failed line.
String formatEquipStatusSummary(EquipStatus status) {
  return 'Completed ${status.completed} · Failed ${status.failed} · '
      'Steps ${status.steps.length}';
}

/// Message when class filter yields no characters.
String formatNoMatchingClassMessage(String buildClass) {
  return 'No $buildClass characters on this account.';
}
