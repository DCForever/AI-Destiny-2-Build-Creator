// Hand-trimmed raw-table fixtures (port of product rawTables.ts).

Map<String, dynamic> _dp(String name, [String description = '', String? icon]) {
  final m = <String, dynamic>{'name': name, 'description': description};
  if (icon != null) m['icon'] = icon;
  return m;
}

Map<String, dynamic> _mkItem(
  int hash,
  String name,
  String desc, [
  Map<String, dynamic> extra = const {},
]) {
  return {
    'hash': hash,
    'displayProperties': _dp(name, desc),
    ...extra,
  };
}

Map<String, dynamic> _mkPlug(
  int hash,
  String name,
  String catId, [
  String desc = '',
  Map<String, dynamic> extra = const {},
]) {
  return _mkItem(hash, name, desc, {
    'plug': {'plugCategoryIdentifier': catId},
    ...extra,
  });
}

final Map<String, dynamic> fixtureStatTable = {
  '2996146975': {
    'hash': 2996146975,
    'displayProperties': _dp('Mobility', 'Movement speed.'),
  },
  '392767087': {
    'hash': 392767087,
    'displayProperties': _dp('Resilience', 'Damage resistance.'),
  },
  '1943323491': {
    'hash': 1943323491,
    'displayProperties': _dp('Recovery', 'Rift recharge.'),
  },
  '1735777505': {
    'hash': 1735777505,
    'displayProperties': _dp('Discipline', 'Grenade recharge.'),
  },
  '144602215': {
    'hash': 144602215,
    'displayProperties': _dp('Intellect', 'Super recharge.'),
  },
  '4244567560': {
    'hash': 4244567560,
    'displayProperties': _dp('Strength', 'Melee recharge.'),
  },
  '2223994109': {
    'hash': 2223994109,
    'displayProperties': _dp('Aspect Energy Capacity', 'Fragment slots.'),
  },
};

final Map<String, dynamic> fixtureSlotTable = {
  '3001': {
    'hash': 3001,
    'displayProperties': _dp('Kinetic Weapons'),
  },
  '3002': {
    'hash': 3002,
    'displayProperties': _dp('Energy Weapons'),
  },
  '3003': {
    'hash': 3003,
    'displayProperties': _dp('Power Weapons'),
  },
  '3004': {'hash': 3004, 'displayProperties': _dp('Helmet')},
  '3005': {'hash': 3005, 'displayProperties': _dp('Gauntlets')},
  '3006': {'hash': 3006, 'displayProperties': _dp('Chest Armor')},
  '3007': {'hash': 3007, 'displayProperties': _dp('Leg Armor')},
  '3008': {'hash': 3008, 'displayProperties': _dp('Class Armor')},
};

final Map<String, dynamic> fixtureDamageTable = {
  '4001': {'hash': 4001, 'displayProperties': _dp('Solar')},
  '4002': {'hash': 4002, 'displayProperties': _dp('Stasis')},
  '4003': {'hash': 4003, 'displayProperties': _dp('Arc')},
  '4004': {'hash': 4004, 'displayProperties': _dp('Void')},
};

final Map<String, dynamic> fixturePlugSetTable = {
  '5001': {
    'reusablePlugItems': [
      {'plugItemHash': 1010},
      {'plugItemHash': 1011},
    ],
  },
  '5002': {
    'reusablePlugItems': [
      {'plugItemHash': 1012},
      {'plugItemHash': 1013},
    ],
  },
  '5003': {
    'reusablePlugItems': [
      {'plugItemHash': 1012},
    ],
  },
};

final Map<String, dynamic> fixtureSandboxPerkTable = {
  '8001': {
    'hash': 8001,
    'displayProperties': _dp('Hive Mind', 'Bonus for 2-piece set.'),
  },
  '8701': {
    'hash': 8701,
    'displayProperties':
        _dp('Volatile Flow Effect', 'Picking up an orb grants Volatile Rounds.'),
  },
  '8702': {
    'hash': 8702,
    'displayProperties': _dp(
      'Heavy Ammo Finder Effect',
      'Increases the effect of all contributions towards the Heavy ammo meter.',
    ),
  },
  '8703': {
    'hash': 8703,
    'displayProperties': _dp(
      'Focusing Strike',
      'Grants class ability energy when you cause damage with a powered melee attack.',
    ),
  },
};

final Map<String, dynamic> fixtureItemTable = {
  '1001': {
    'hash': 1001,
    'displayProperties':
        _dp('Celestial Nighthawk', 'Exotic Hunter helmet.', '/nighthawk.png'),
    'itemType': 2,
    'classType': 1,
    'flavorText': "It's a space monocle.",
    'inventory': {'tierType': 6},
    'equippingBlock': {'equipmentSlotTypeHash': 3004},
    'sockets': {
      'socketEntries': [
        {'singleInitialItemHash': 1002},
        {'singleInitialItemHash': 1003},
      ],
      'socketCategories': <dynamic>[],
    },
  },
  '1002': _mkPlug(
    1002,
    'Hawkeye Hack',
    'intrinsics',
    'Precision hits and kills with Golden Gun reduce its cooldown.',
  ),
  '1003': _mkPlug(
    1003,
    'Celestial Archetype',
    'armor_archetypes',
    'Exotic armor archetype.',
    {'itemTypeDisplayName': 'Archetype'},
  ),
  '1007': {
    'hash': 1007,
    'displayProperties':
        _dp('Chattering Bone', 'Legendary pulse rifle.', '/chatbone.png'),
    'itemType': 3,
    'itemTypeDisplayName': 'Pulse Rifle',
    'defaultDamageTypeHash': 4002,
    'inventory': {'tierType': 5},
    'equippingBlock': {'ammoType': 1, 'equipmentSlotTypeHash': 3001},
    'sockets': {
      'socketEntries': [
        {'singleInitialItemHash': 1008},
        {'singleInitialItemHash': 1009},
        {'reusablePlugSetHash': 5001},
        {'reusablePlugSetHash': 5003, 'randomizedPlugSetHash': 5002},
      ],
      'socketCategories': [
        {
          'socketCategoryHash': 4241085061,
          'socketIndexes': [0, 1, 2, 3],
        },
      ],
    },
  },
  '1008': _mkPlug(
    1008,
    'Precision Frame',
    'frames',
    "This weapon's recoil pattern is more predictably vertical.",
    {'itemTypeDisplayName': 'Intrinsic'},
  ),
  '1009': _mkPlug(
    1009,
    'Tex Balanced Stock',
    'origins',
    'Holding reload grants stability and handling for a short duration.',
  ),
  '1010': _mkPlug(
    1010,
    'Corkscrew Rifling',
    'barrels',
    'Balanced barrel.',
    {'itemTypeDisplayName': 'Barrel'},
  ),
  '1011': _mkPlug(
    1011,
    'Fluted Barrel',
    'barrels',
    'Ultra-light barrel.',
    {'itemTypeDisplayName': 'Barrel'},
  ),
  '1012': _mkPlug(
    1012,
    'Kill Clip',
    'frames',
    'Reloading after a kill grants increased damage.',
    {'itemTypeDisplayName': 'Trait'},
  ),
  '1013': _mkPlug(
    1013,
    'Slideshot',
    'frames',
    'Sliding partially reloads this weapon.',
    {'itemTypeDisplayName': 'Trait'},
  ),
  '1014': _mkItem(1014, 'Touch of Thunder', 'Improves Arc grenades.', {
    'itemTypeDisplayName': 'Arc Aspect',
    'classType': 1,
    'plug': {'plugCategoryIdentifier': 'hunter.arc.aspects'},
    'investmentStats': [
      {'statTypeHash': 2223994109, 'value': 4},
    ],
  }),
  '1015': _mkItem(1015, 'Consecration', 'Sliding charges a Solar Flare.', {
    'itemTypeDisplayName': 'Solar Aspect',
    'classType': 0,
    'plug': {'plugCategoryIdentifier': 'titan.solar.aspects'},
    'investmentStats': [
      {'statTypeHash': 2223994109, 'value': 2},
    ],
  }),
  '1016': _mkItem(
    1016,
    'Spark of Brilliance',
    'Defeating a blinded target creates a blinding explosion.',
    {
      'itemTypeDisplayName': 'Arc Fragment',
      'plug': {'plugCategoryIdentifier': 'shared.arc.fragments'},
      'investmentStats': <dynamic>[],
    },
  ),
  '1017': _mkItem(
    1017,
    'Echo of Undermining',
    'Your Void grenades weaken targets.',
    {
      'itemTypeDisplayName': 'Void Fragment',
      'plug': {'plugCategoryIdentifier': 'shared.void.fragments'},
      'investmentStats': [
        {'statTypeHash': 4244567560, 'value': -10},
      ],
    },
  ),
  '1018': _mkItem(1018, 'Chaos Reach', 'Unleash a long-range Arc beam.', {
    'itemTypeDisplayName': 'Arc Super',
    'classType': 2,
    'plug': {'plugCategoryIdentifier': 'warlock.arc.supers'},
  }),
  '1019': _mkItem(
    1019,
    'Pulse Grenade',
    'Grenade that periodically damages enemies.',
    {
      'itemTypeDisplayName': 'Arc Grenade',
      'classType': 3,
      'plug': {'plugCategoryIdentifier': 'shared.grenades'},
    },
  ),
  '1020': _mkItem(1020, 'Storm Fist', 'Arc charged melee attack.', {
    'itemTypeDisplayName': 'Arc Melee',
    'classType': 0,
    'plug': {'plugCategoryIdentifier': 'titan.arc.melee'},
  }),
  '1021': _mkItem(
    1021,
    "Gambler's Dodge",
    'Dodge near an enemy to recharge melee.',
    {
      'itemTypeDisplayName': 'Void Class Ability',
      'classType': 1,
      'plug': {'plugCategoryIdentifier': 'hunter.void.class_abilities'},
    },
  ),
  '1022': _mkItem(
    1022,
    'Burst Glide',
    'Jump with initial burst of momentum.',
    {
      'itemTypeDisplayName': 'Arc Jump',
      'classType': 2,
      'plug': {'plugCategoryIdentifier': 'warlock.arc.movement'},
    },
  ),
  '1026': _mkItem(
    1026,
    'Phoenix Dive',
    'Dive to the ground and create a burst of Solar Light that cures nearby allies.',
    {
      'itemTypeDisplayName': 'Solar Class Ability',
      'classType': 2,
      'plug': {'plugCategoryIdentifier': 'warlock.solar.class_abilities'},
    },
  ),
  '1023': _mkItem(
    1023,
    'Charged Up',
    'Increases the maximum number of stacks.',
    {
      'itemType': 19,
      'plug': {
        'plugCategoryIdentifier': 'enhancements.v2_head',
        'energyCost': {'energyCost': 1},
      },
    },
  ),
  '1024': _mkItem(
    1024,
    'Special Ammo Finder',
    'Increases special ammo drop chance.',
    {
      'itemType': 19,
      'plug': {
        'plugCategoryIdentifier': 'enhancements.general',
        'energyCost': {'energyCost': 0},
      },
    },
  ),
  '1025': _mkItem(1025, 'Harmonic Tuning', 'Tuning mod.', {
    'itemType': 19,
    'plug': {'plugCategoryIdentifier': 'enhancements.tuning'},
  }),
  '1030': _mkItem(1030, 'Major Melee', '+10 Melee.', {
    'itemType': 19,
    'plug': {
      'plugCategoryIdentifier': 'enhancements.v2_general',
      'energyCost': {'energyCost': 3},
    },
    'investmentStats': [
      {'statTypeHash': 4244567218, 'value': 10},
    ],
  }),
  '1031': _mkItem(1031, 'Minor Health', '+5 Health.', {
    'itemType': 19,
    'plug': {
      'plugCategoryIdentifier': 'enhancements.v2_chest',
      'energyCost': {'energyCost': 1},
    },
    'investmentStats': [
      {'statTypeHash': 392767087, 'value': 5},
    ],
  }),
  '1027': {
    'hash': 1027,
    'displayProperties': _dp('Heavy Ammo Finder', ''),
    'itemType': 19,
    'plug': {
      'plugCategoryIdentifier': 'enhancements.v2_head',
      'energyCost': {'energyCost': 1},
    },
    'tooltipNotifications': [
      {
        'displayString':
            'Primary ammo weapon final blows help you find ammo more quickly. Does not function in Crucible.',
        'displayStyle': 'ui_display_style_perk_info',
      },
    ],
  },
  '1028': {
    'hash': 1028,
    'displayProperties': _dp('Focusing Strike', ''),
    'itemType': 19,
    'plug': {
      'plugCategoryIdentifier': 'enhancements.v2_arms',
      'energyCost': {'energyCost': 1},
    },
    'perks': [
      {'perkHash': 8703},
    ],
    'tooltipNotifications': [
      {
        'displayString':
            'Multiple copies of this mod can be stacked to increase the potency of its effect, with diminishing returns for each additional copy of the mod.',
        'displayStyle': 'ui_display_style_perk_info',
      },
    ],
  },
  '1029': {
    'hash': 1029,
    'displayProperties': _dp('Focusing Strike', ''),
    'itemType': 19,
    'plug': {
      'plugCategoryIdentifier': 'enhancements.v2_arms',
      'energyCost': {'energyCost': 2},
    },
    'perks': [
      {'perkHash': 8703},
    ],
  },
};

/// All raw tables needed by MVP extractors.
final Map<String, Map<String, dynamic>> fixtureRawTables = {
  'DestinyInventoryItemDefinition': fixtureItemTable,
  'DestinyStatDefinition': fixtureStatTable,
  'DestinyPlugSetDefinition': fixturePlugSetTable,
  'DestinyDamageTypeDefinition': fixtureDamageTable,
  'DestinyEquipmentSlotDefinition': fixtureSlotTable,
  'DestinySandboxPerkDefinition': fixtureSandboxPerkTable,
};

Future<Map<String, dynamic>> loadFixtureRawTable(String name) async {
  final table = fixtureRawTables[name];
  if (table == null) return <String, dynamic>{};
  return Map<String, dynamic>.from(table);
}
