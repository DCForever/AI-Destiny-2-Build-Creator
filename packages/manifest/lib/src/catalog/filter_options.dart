// Shared multi-filter chip options for Catalog browse (product parity).

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
