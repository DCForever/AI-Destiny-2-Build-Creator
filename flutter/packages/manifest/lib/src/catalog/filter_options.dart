// Shared multi-filter chip options for Catalog browse (product parity).

import 'catalog_browse_mode.dart';

const catalogElements = <String>[
  'Kinetic',
  'Arc',
  'Solar',
  'Void',
  'Stasis',
  'Strand',
  'Prismatic',
];

const catalogAmmoTypes = <String>['Primary', 'Special', 'Heavy'];

const catalogWeaponSlots = <String>['Kinetic', 'Energy', 'Power'];

const catalogArmorSlots = <String>[
  'Helmet',
  'Gauntlets',
  'Chest',
  'Legs',
  'ClassItem',
];

const catalogClassNames = <String>['Titan', 'Hunter', 'Warlock'];

const catalogWeaponArchetypes = <String>[
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
  'Rocket Launcher',
  'Linear Fusion Rifle',
  'Machine Gun',
  'Sword',
];

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
