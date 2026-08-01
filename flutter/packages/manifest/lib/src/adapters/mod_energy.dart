import '../types/records.dart';

/// Tier ≤4 → 10 energy; tier 5 → 11. Unknown/wishlist defaults to 10.
int armorEnergyCapacity(int? tier) {
  if (tier != null && tier >= 5) return 11;
  return 10;
}

int sumEnergyCosts(Iterable<int?> costs) {
  var total = 0;
  for (final c in costs) {
    if (c != null && c > 0) total += c;
  }
  return total;
}

ModSlotCategory? modCategoryForArmorSlot(String slot) {
  switch (slot) {
    case 'helmet':
      return ModSlotCategory.helmet;
    case 'arms':
      return ModSlotCategory.arms;
    case 'chest':
      return ModSlotCategory.chest;
    case 'legs':
      return ModSlotCategory.legs;
    case 'class_item':
      return ModSlotCategory.classItem;
    default:
      return null;
  }
}

/// Whether a mod may sit on this armor piece.
/// `general` / `tuning` are allowed on any armor slot.
bool isModLegalForArmorSlot(String slot, ModSlotCategory? category) {
  if (category == null) return true;
  if (category == ModSlotCategory.general ||
      category == ModSlotCategory.tuning) {
    return true;
  }
  final expected = modCategoryForArmorSlot(slot);
  if (expected == null) return true;
  return category == expected;
}
