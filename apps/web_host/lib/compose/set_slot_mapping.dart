import 'package:destiny2_domain/destiny2_domain.dart';

/// Pure set-slot helpers for web Sets library UI (DART-046).

/// Concrete fill targets offered for a set type.
List<String> slotsForSetType(SetType type) {
  switch (type) {
    case SetType.weapon:
      return EquipmentSlot.weaponSlots.map((s) => s.wireName).toList();
    case SetType.armor:
      return EquipmentSlot.armorSlots.map((s) => s.wireName).toList();
    case SetType.pair:
      return EquipmentSlot.pairSlots.map((s) => s.wireName).toList();
    case SetType.fashion:
      return FashionSlot.values.map((s) => s.wireName).toList();
    case SetType.mod:
      return EquipmentSlot.armorSlots.map((s) => s.wireName).toList();
  }
}

/// Whether [slot] is a valid write key for [type].
bool isSlotValidForSetType(SetType type, String slot) {
  final s = slot.trim();
  if (s.isEmpty) return false;
  switch (type) {
    case SetType.weapon:
    case SetType.armor:
    case SetType.pair:
    case SetType.fashion:
      return slotsForSetType(type).contains(s);
    case SetType.mod:
      if (s == 'mod' || s.startsWith('mod:')) return true;
      if (EquipmentSlot.armorSlots.any((a) => a.wireName == s)) return true;
      return false;
  }
}
