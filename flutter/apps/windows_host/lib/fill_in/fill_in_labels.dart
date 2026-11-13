import 'package:destiny2_domain/destiny2_domain.dart';

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
