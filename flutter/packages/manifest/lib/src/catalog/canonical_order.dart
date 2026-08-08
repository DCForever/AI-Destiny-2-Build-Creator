import 'sort_by_name.dart';

// ---------------------------------------------------------------------------
// Canonical catalog facet / group-by segment orders (SSoT)
// ---------------------------------------------------------------------------
//
// Used by: filter chip lists, multi-level group sibling order, weapons multi-key
// sort. Unknown values sort after known ranks, then by [compareDisplayName].
//
// Dimension-aware compare lives in [group_catalog.dart] (uses these lists).

/// Weapon slot order: Kinetic → Energy → Power.
const List<String> kCatalogSlotOrder = ['Kinetic', 'Energy', 'Power'];

/// Ammo order: Primary → Special → Heavy.
const List<String> kCatalogAmmoOrder = ['Primary', 'Special', 'Heavy'];

/// Damage element order for weapons/armor filter + group-by.
///
/// **Prismatic is not a catalog filter** (subclass identity only).
const List<String> kCatalogElementOrder = [
  'Kinetic',
  'Stasis',
  'Strand',
  'Arc',
  'Solar',
  'Void',
];

/// Weapon archetype (item type) display order.
///
/// **Rocket Launcher is always last** among known weapon types.
const List<String> kCatalogWeaponArchetypeOrder = [
  'Auto Rifle',
  'Pulse Rifle',
  'Scout Rifle',
  'Hand Cannon',
  'Sidearm',
  'Submachine Gun',
  'Bow',
  'Fusion Rifle',
  'Glaive',
  'Sniper Rifle',
  'Shotgun',
  'Trace Rifle',
  'Grenade Launcher',
  'Linear Fusion Rifle',
  'Machine Gun',
  'Sword',
  'Rocket Launcher',
];

/// Armor class order when grouping by class.
const List<String> kCatalogClassOrder = ['Titan', 'Hunter', 'Warlock'];

/// Armor slot order when grouping by armor slots.
const List<String> kCatalogArmorSlotOrder = [
  'Helmet',
  'Gauntlets',
  'Chest',
  'Legs',
  'ClassItem',
];

/// Index of [value] in [order], or [order.length] if unknown.
int catalogCanonicalIndex(List<String> order, String? value) {
  if (value == null || value.trim().isEmpty) return order.length;
  final raw = value.trim();
  final exact = order.indexOf(raw);
  if (exact >= 0) return exact;
  final lower = raw.toLowerCase();
  for (var i = 0; i < order.length; i++) {
    if (order[i].toLowerCase() == lower) return i;
  }
  // Common aliases
  if (identical(order, kCatalogWeaponArchetypeOrder) ||
      order == kCatalogWeaponArchetypeOrder) {
    if (lower == 'smg' || lower == 'submachine guns') {
      return catalogCanonicalIndex(order, 'Submachine Gun');
    }
    if (lower == 'combat bow' || lower == 'bows') {
      return catalogCanonicalIndex(order, 'Bow');
    }
  }
  if ((identical(order, kCatalogSlotOrder) || order == kCatalogSlotOrder) &&
      lower == 'heavy') {
    return catalogCanonicalIndex(order, 'Power');
  }
  return order.length;
}

/// Compare two display labels under a fixed [order] list.
///
/// Known ranks first; unknown after known; ties broken by [compareDisplayName].
int compareCanonicalLabels(String a, String b, List<String> order) {
  final ia = catalogCanonicalIndex(order, a);
  final ib = catalogCanonicalIndex(order, b);
  if (ia != ib) return ia.compareTo(ib);
  return compareDisplayName(a, b);
}
