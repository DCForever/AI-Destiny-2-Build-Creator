import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';

/// Human label for a Fill In equipment slot (dialog + saved missing list).
///
/// Weapon rows are [Kinetic] / [Energy] / [Power]. Only the exotic combat
/// weapon row gets an [Exotic] prefix — never label all three as exotic.
String fillInSlotLabel(EquipmentSlot slot, {bool isExotic = false}) {
  switch (slot) {
    case EquipmentSlot.helmet:
      return 'Helmet';
    case EquipmentSlot.arms:
      return 'Gauntlets';
    case EquipmentSlot.chest:
      return 'Chest';
    case EquipmentSlot.legs:
      return 'Legs';
    case EquipmentSlot.classItem:
      return 'Class Item';
    case EquipmentSlot.primary:
      return isExotic ? 'Exotic Kinetic' : 'Kinetic';
    case EquipmentSlot.special:
      return isExotic ? 'Exotic Energy' : 'Energy';
    case EquipmentSlot.heavy:
      return isExotic ? 'Exotic Power' : 'Power';
    case EquipmentSlot.exoticWeapon:
      return 'Exotic weapon';
    case EquipmentSlot.exoticArmor:
      return 'Exotic armor';
  }
}

/// Missing-list / row label for a Fill In slot, including unnamed exotic armor.
///
/// Summary-only exotic armor (no known combat bucket) must stay visible as
/// `Exotic armor (slot unknown): {name}` — never Class Item, never silent.
String fillInMissingSlotLabel({
  required EquipmentSlot slot,
  bool isExotic = false,
  String? exoticArmorName,
}) {
  if (slot == EquipmentSlot.exoticArmor) {
    final name = exoticArmorName?.trim() ?? '';
    if (name.isEmpty) return 'Exotic armor (slot unknown)';
    return 'Exotic armor (slot unknown): $name';
  }
  return fillInSlotLabel(slot, isExotic: isExotic);
}

/// Armor combat slots in dialog / saved-list order.
const List<EquipmentSlot> kFillInArmorSectionOrder = [
  EquipmentSlot.helmet,
  EquipmentSlot.arms,
  EquipmentSlot.chest,
  EquipmentSlot.legs,
  EquipmentSlot.classItem,
];

/// Weapon combat slots in dialog / saved-list order.
const List<EquipmentSlot> kFillInWeaponSectionOrder = [
  EquipmentSlot.primary,
  EquipmentSlot.special,
  EquipmentSlot.heavy,
];

bool fillInIsArmorSectionSlot(EquipmentSlot slot) {
  return kFillInArmorSectionOrder.contains(slot) ||
      slot == EquipmentSlot.exoticArmor;
}

bool fillInIsWeaponSectionSlot(EquipmentSlot slot) {
  return kFillInWeaponSectionOrder.contains(slot) ||
      slot == EquipmentSlot.exoticWeapon;
}

/// Build structured saved rows from diffs (never includes blank item names for
/// held/filled). [filledSlotWires] marks slots already written by Apply.
List<FillInSavedSlotRow> buildFillInSavedSlotRows({
  required List<FillInSlotDiff> diffs,
  required String exoticArmorName,
  Set<String> filledSlotWires = const {},
}) {
  final bySlot = <EquipmentSlot, FillInSlotDiff>{
    for (final d in diffs) d.slot: d,
  };
  final rows = <FillInSavedSlotRow>[];

  void addRow(EquipmentSlot slot) {
    final diff = bySlot[slot];
    if (diff == null) return;
    final slotLabel = fillInMissingSlotLabel(
      slot: slot,
      isExotic: diff.isExotic,
      exoticArmorName: exoticArmorName,
    );
    final filled = filledSlotWires.contains(slot.wireName);
    final String state;
    final String itemName;
    if (diff.isHeld) {
      state = 'held';
      itemName = diff.currentLabel.trim();
      if (!_realItemName(itemName)) return;
    } else if (filled) {
      state = 'filled';
      final sub = (diff.substituteLabel ?? '').trim();
      final cur = diff.currentLabel.trim();
      itemName = _realItemName(sub)
          ? sub
          : (_realItemName(cur) ? cur : '');
      if (itemName.isEmpty) return;
    } else {
      state = 'missing';
      final current = diff.currentLabel.trim();
      itemName = _realItemName(current) ? current : '';
    }
    if (state != 'missing' && itemName.isEmpty) return;
    rows.add(
      FillInSavedSlotRow(
        slotWire: slot.wireName,
        slotLabel: slotLabel,
        state: state,
        itemName: itemName,
      ),
    );
  }

  for (final slot in kFillInArmorSectionOrder) {
    addRow(slot);
  }
  if (bySlot.containsKey(EquipmentSlot.exoticArmor)) {
    addRow(EquipmentSlot.exoticArmor);
  }
  for (final slot in kFillInWeaponSectionOrder) {
    addRow(slot);
  }
  return List<FillInSavedSlotRow>.unmodifiable(rows);
}

bool _realItemName(String label) {
  final trimmed = label.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed == kFillInNoWeaponInDimLink) return false;
  final lower = trimmed.toLowerCase();
  for (final slot in EquipmentSlot.values) {
    if (slot.wireName == lower) return false;
  }
  return true;
}
