import 'package:destiny2_domain/destiny2_domain.dart';

/// Pure set-slot helpers for web Sets library UI (DART-046/065).

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
      final colon = s.indexOf(':');
      if (colon > 0) {
        final piece = s.substring(0, colon);
        final hashPart = s.substring(colon + 1);
        final hash = int.tryParse(hashPart);
        if (hash != null &&
            hash > 0 &&
            EquipmentSlot.armorSlots.any((a) => a.wireName == piece)) {
          return true;
        }
      }
      return false;
  }
}

String _normalizeBucketKey(String raw) {
  return raw.trim().toLowerCase().replaceAllMapped(
        RegExp(r'[\s_-]+'),
        (m) => m.group(0)!.contains('_') ? '_' : ' ',
      );
}

/// Map a catalog bucket/slot label to a set slot wire name.
String? mapCatalogBucketToSetSlot(String? catalogSlot, SetType setType) {
  if (catalogSlot == null || catalogSlot.trim().isEmpty) return null;
  final key = _normalizeBucketKey(catalogSlot);
  final compact = key.replaceAll(RegExp(r'\s+'), '');
  final bare = compact.replaceFirst(RegExp(r'weapons?$'), '');

  switch (setType) {
    case SetType.weapon:
    case SetType.pair:
      const weaponMap = {
        'kinetic': 'primary',
        'energy': 'special',
        'power': 'heavy',
        'primary': 'primary',
        'special': 'special',
        'heavy': 'heavy',
      };
      final mapped = weaponMap[bare] ?? weaponMap[compact] ?? weaponMap[key];
      if (mapped != null) return mapped;
      if (setType == SetType.pair &&
          (bare.contains('exotic') || key.contains('exotic'))) {
        return EquipmentSlot.exoticWeapon.wireName;
      }
      return null;

    case SetType.armor:
    case SetType.mod:
      const armorMap = {
        'helmet': 'helmet',
        'gauntlets': 'arms',
        'arms': 'arms',
        'chest': 'chest',
        'chestarmor': 'chest',
        'chest armor': 'chest',
        'legs': 'legs',
        'legarmor': 'legs',
        'leg armor': 'legs',
        'classitem': 'class_item',
        'class_item': 'class_item',
        'class item': 'class_item',
        'classarmor': 'class_item',
        'class armor': 'class_item',
      };
      return armorMap[key] ??
          armorMap[compact] ??
          armorMap[key.replaceAll(' ', '_')] ??
          armorMap[key.replaceAll(' ', '')];

    case SetType.fashion:
      for (final f in FashionSlot.values) {
        if (f.wireName == key || f.wireName.replaceAll('_', ' ') == key) {
          return f.wireName;
        }
      }
      return null;
  }
}

List<String> catalogBucketLabelsForSetSlot(String slot) {
  switch (slot) {
    case 'primary':
      return const ['Kinetic'];
    case 'special':
      return const ['Energy'];
    case 'heavy':
      return const ['Power'];
    case 'helmet':
      return const ['Helmet'];
    case 'arms':
      return const ['Gauntlets', 'Arms'];
    case 'chest':
      return const ['Chest', 'Chest Armor'];
    case 'legs':
      return const ['Legs', 'Leg Armor'];
    case 'class_item':
      return const ['Class Item', 'Class Armor'];
    default:
      return const [];
  }
}

String setSlotDisplayLabel(String slot) {
  switch (slot) {
    case 'primary':
      return 'Primary';
    case 'special':
      return 'Special';
    case 'heavy':
      return 'Heavy';
    case 'helmet':
      return 'Helmet';
    case 'arms':
      return 'Arms';
    case 'chest':
      return 'Chest';
    case 'legs':
      return 'Legs';
    case 'class_item':
      return 'Class Item';
    case 'exotic_weapon':
      return 'Exotic Weapon';
    case 'exotic_armor':
      return 'Exotic Armor';
    default:
      return slot;
  }
}

bool catalogItemMatchesSetSlot(String? catalogSlot, String setSlot) {
  final mappedLabels = catalogBucketLabelsForSetSlot(setSlot);
  if (mappedLabels.isEmpty) return true;
  if (catalogSlot == null || catalogSlot.isEmpty) return false;
  final c = catalogSlot.trim().toLowerCase();
  for (final label in mappedLabels) {
    if (c == label.toLowerCase()) return true;
  }
  for (final type in SetType.values) {
    if (!slotsForSetType(type).contains(setSlot) && type != SetType.mod) {
      continue;
    }
    final mapped = mapCatalogBucketToSetSlot(catalogSlot, type);
    if (mapped == setSlot) return true;
  }
  return false;
}
