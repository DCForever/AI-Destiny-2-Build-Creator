import 'package:destiny2_domain/destiny2_domain.dart';

/// Pure set-slot helpers for Sets library UI (DART-030).
///
/// Parity with product `slotsForSetType` / catalog bucket maps in
/// `src/lib/catalog/setPlacementFromHit.ts` and `src/lib/sets/schemas.ts`.
///
/// [slotsForSetType] / [isSlotValidForSetType] come from `destiny2_domain`
/// (set composition constraints).

String _normalizeBucketKey(String raw) {
  return raw.trim().toLowerCase().replaceAllMapped(
        RegExp(r'[\s_-]+'),
        (m) => m.group(0)!.contains('_') ? '_' : ' ',
      );
}

/// Map a catalog bucket/slot label (e.g. Kinetic, Helmet) to a set slot wire name.
///
/// Returns null when no mapping is known for [setType].
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
      if (mapped != null) {
        if (setType == SetType.pair) {
          // Pair exotic weapon fill still uses exotic_weapon as storage slot when
          // picking exotics; bucket map is useful for weapon-type sets.
          return mapped;
        }
        return mapped;
      }
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

/// Catalog facet slot labels to prefer when filtering for a set [slot].
///
/// Empty list means “no bucket facet constraint.”
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
    case 'exotic_weapon':
      return const [];
    case 'exotic_armor':
      return const [];
    default:
      return const [];
  }
}

/// Human label for a set slot wire name.
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
    case 'shader_ornament':
      return 'Shader / Ornament';
    case 'ghost':
      return 'Ghost';
    case 'sparrow':
      return 'Sparrow';
    case 'ship':
      return 'Ship';
    case 'emblem':
      return 'Emblem';
    case 'finisher':
      return 'Finisher';
    default:
      return slot;
  }
}

/// Whether catalog item [catalogSlot] matches the target set [slot] for filtering.
bool catalogItemMatchesSetSlot(String? catalogSlot, String setSlot) {
  final mappedLabels = catalogBucketLabelsForSetSlot(setSlot);
  if (mappedLabels.isEmpty) {
    // No constraint (e.g. pair exotic slots) — accept all.
    return true;
  }
  if (catalogSlot == null || catalogSlot.isEmpty) return false;
  final c = catalogSlot.trim().toLowerCase();
  for (final label in mappedLabels) {
    if (c == label.toLowerCase()) return true;
  }
  // Also accept if mapping the catalog bucket lands on this set slot.
  // Try all set types that own this slot.
  for (final type in SetType.values) {
    if (!slotsForSetType(type).contains(setSlot) && type != SetType.mod) {
      continue;
    }
    final mapped = mapCatalogBucketToSetSlot(catalogSlot, type);
    if (mapped == setSlot) return true;
  }
  return false;
}
