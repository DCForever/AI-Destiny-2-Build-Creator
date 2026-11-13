import 'package:destiny2_domain/destiny2_domain.dart';

/// Human label for a Fill In equipment slot (dialog + saved missing list).
String fillInSlotLabel(EquipmentSlot slot) {
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
      return 'Exotic weapon (kinetic)';
    case EquipmentSlot.special:
      return 'Exotic weapon (energy)';
    case EquipmentSlot.heavy:
      return 'Exotic weapon (power)';
    case EquipmentSlot.exoticWeapon:
      return 'Exotic weapon';
    case EquipmentSlot.exoticArmor:
      return 'Exotic armor';
  }
}
