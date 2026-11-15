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

/// Apply outcome-row label: real item name, exotic annotated, never slot keys.
///
/// Never returns `primary`, `None`, empty, or a raw slot wire alone when a
/// readable fallback exists. Exotic weapons → `Name (Exotic weapon)`; exotic
/// armor → `Name (Exotic armor)`.
String formatApplyOutcomeLabel({
  required String rawLabel,
  String? slot,
  bool isExotic = false,
}) {
  final cleaned = _cleanApplyItemName(rawLabel);
  final exoticKind = _applyExoticKindLabel(slot, isExotic: isExotic);
  if (cleaned != null) {
    if (exoticKind != null) return '$cleaned ($exoticKind)';
    return cleaned;
  }
  final readable = readableApplySlotLabel(slot);
  if (exoticKind != null) return exoticKind;
  return readable;
}

/// Human slot name for Apply rows (never raw `primary` / `None`).
String readableApplySlotLabel(String? slot) {
  switch ((slot ?? '').trim().toLowerCase()) {
    case 'primary':
    case 'kinetic':
      return 'Kinetic';
    case 'special':
    case 'energy':
      return 'Energy';
    case 'heavy':
    case 'power':
      return 'Power';
    case 'helmet':
      return 'Helmet';
    case 'arms':
    case 'gauntlets':
      return 'Gauntlets';
    case 'chest':
      return 'Chest';
    case 'legs':
      return 'Legs';
    case 'class_item':
    case 'classitem':
      return 'Class Item';
    case 'exotic_weapon':
      return 'Exotic weapon';
    case 'exotic_armor':
      return 'Exotic armor';
    default:
      final trimmed = (slot ?? '').trim();
      if (trimmed.isEmpty ||
          trimmed.toLowerCase() == 'none' ||
          trimmed.toLowerCase() == 'primary') {
        return 'Item';
      }
      return trimmed;
  }
}

String? _cleanApplyItemName(String rawLabel) {
  final trimmed = rawLabel.trim();
  if (trimmed.isEmpty) return null;
  final lower = trimmed.toLowerCase();
  if (lower == 'none' || lower == 'null') return null;
  switch (lower) {
    case 'primary':
    case 'kinetic':
    case 'special':
    case 'energy':
    case 'heavy':
    case 'power':
    case 'helmet':
    case 'arms':
    case 'gauntlets':
    case 'chest':
    case 'legs':
    case 'class_item':
    case 'classitem':
    case 'exotic_weapon':
    case 'exotic_armor':
      return null;
  }
  return trimmed;
}

String? _applyExoticKindLabel(String? slot, {required bool isExotic}) {
  final wire = (slot ?? '').trim().toLowerCase();
  if (wire == 'exotic_weapon') return 'Exotic weapon';
  if (wire == 'exotic_armor') return 'Exotic armor';
  if (!isExotic) return null;
  switch (wire) {
    case 'primary':
    case 'kinetic':
    case 'special':
    case 'energy':
    case 'heavy':
    case 'power':
      return 'Exotic weapon';
    case 'helmet':
    case 'arms':
    case 'gauntlets':
    case 'chest':
    case 'legs':
    case 'class_item':
    case 'classitem':
      return 'Exotic armor';
    default:
      return 'Exotic';
  }
}
