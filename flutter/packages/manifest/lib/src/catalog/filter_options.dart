// Shared multi-filter chip options for Catalog browse (product parity).

import 'catalog_browse_mode.dart';

import 'canonical_order.dart';

/// Element filter chips — canonical order; **Prismatic is not a filter**.
const List<String> catalogElements = kCatalogElementOrder;

/// Ammo filter chips — Primary → Special → Heavy.
const List<String> catalogAmmoTypes = kCatalogAmmoOrder;

/// Weapon slot filter chips — Kinetic → Energy → Power.
const List<String> catalogWeaponSlots = kCatalogSlotOrder;

/// Armor slot filter chips.
const List<String> catalogArmorSlots = kCatalogArmorSlotOrder;

/// Class filter chips — Titan → Hunter → Warlock.
const List<String> catalogClassNames = kCatalogClassOrder;

/// Weapon type (archetype) filter chips — **Rocket Launcher last**.
const List<String> catalogWeaponArchetypes = kCatalogWeaponArchetypeOrder;

const catalogArmorArchetypes = <String>[
  'Bulwark',
  'Brawler',
  'Grenadier',
  'Specialist',
  'Gunner',
  'Paragon',
];

List<String> toggleFilterValue(List<String> list, String value) {
  if (list.contains(value)) {
    return list.where((v) => v != value).toList();
  }
  return [...list, value];
}

/// Slot facet values for [mode] (kind-appropriate chrome).
List<String> catalogSlotsForMode(CatalogBrowseMode mode) {
  switch (mode) {
    case CatalogBrowseMode.weapons:
      return catalogWeaponSlots;
    case CatalogBrowseMode.armor:
      return catalogArmorSlots;
    case CatalogBrowseMode.universal:
      return [...catalogWeaponSlots, ...catalogArmorSlots];
  }
}

/// Archetype facet values for [mode].
List<String> catalogArchetypesForMode(CatalogBrowseMode mode) {
  switch (mode) {
    case CatalogBrowseMode.weapons:
      return catalogWeaponArchetypes;
    case CatalogBrowseMode.armor:
      return catalogArmorArchetypes;
    case CatalogBrowseMode.universal:
      return [...catalogWeaponArchetypes, ...catalogArmorArchetypes];
  }
}

/// Whether ammo facet row is primary chrome for [mode].
bool catalogShowsAmmoFacet(CatalogBrowseMode mode) =>
    mode == CatalogBrowseMode.weapons || mode == CatalogBrowseMode.universal;

/// Whether class facet row is primary chrome for [mode].
bool catalogShowsClassFacet(CatalogBrowseMode mode) =>
    mode == CatalogBrowseMode.armor || mode == CatalogBrowseMode.universal;

/// Whether element facet is primary for [mode].
bool catalogShowsElementFacet(CatalogBrowseMode mode) => true;
