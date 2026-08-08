/// Pure demo data for Widgetbook catalog use cases — no IO, no secrets.
library;

import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';

// ---------------------------------------------------------------------------
// Items
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Weapon plate icons — real Bungie item art (CDN basenames, package assets)
// ---------------------------------------------------------------------------

/// Midnight Coup (legendary HC).
const kIconMidnightCoup =
    '/common/destiny2_content/icons/a16c0c62d2153cb59ca7dd5565d66d6a.jpg';

/// Midnight Coup alternate plate (adept / holofoil demos).
const kIconMidnightCoupAlt =
    '/common/destiny2_content/icons/d5c1b1c3eaf09bbf7aa5592490c31aa0.jpg';

/// Ace of Spades.
const kIconAceOfSpades =
    '/common/destiny2_content/icons/cdfbfd3f098329a367294f191070f8c4.jpg';

/// Cerberus+1.
const kIconCerberus =
    '/common/destiny2_content/icons/161a3f06196563345afeacb46e9df88d.jpg';

/// Ribbontail (trace).
const kIconRibbontail =
    '/common/destiny2_content/icons/04652b3f85434968340359f93de0520b.jpg';

/// Unsworn (trace).
const kIconUnsworn =
    '/common/destiny2_content/icons/dd0ae6e8b9aeccfcbec7d5971c48984c.jpg';

const kMidnightCoupBase = CatalogItem(
  hash: 101,
  name: 'Midnight Coup',
  icon: kIconMidnightCoup,
  slot: 'Kinetic',
  element: 'Kinetic',
  ammo: 'Primary',
  frame: 'Adaptive Frame',
  itemTypeName: 'Hand Cannon',
  isExotic: false,
  owned: true,
  ownedCount: 2,
);

const kMidnightCoupAdept = CatalogItem(
  hash: 102,
  name: 'Midnight Coup (Adept)',
  icon: kIconMidnightCoupAlt,
  slot: 'Kinetic',
  element: 'Kinetic',
  ammo: 'Primary',
  frame: 'Adaptive Frame',
  itemTypeName: 'Hand Cannon',
  isExotic: false,
  owned: true,
  ownedCount: 1,
);

const kMidnightCoupHolofoil = CatalogItem(
  hash: 103,
  name: 'Midnight Coup Holofoil',
  icon: kIconMidnightCoupAlt,
  slot: 'Kinetic',
  element: 'Kinetic',
  ammo: 'Primary',
  frame: 'Adaptive Frame',
  itemTypeName: 'Hand Cannon',
  isExotic: false,
  owned: false,
  ownedCount: 0,
);

const kAceOfSpades = CatalogItem(
  hash: 200,
  name: 'Ace of Spades',
  icon: kIconAceOfSpades,
  slot: 'Kinetic',
  element: 'Kinetic',
  ammo: 'Primary',
  frame: 'Adaptive Frame',
  itemTypeName: 'Hand Cannon',
  isExotic: true,
  owned: true,
  ownedCount: 1,
  description: 'The legends are true.',
  intrinsicName: 'Memento Mori',
);

const kCerberusUnowned = CatalogItem(
  hash: 300,
  name: "Cerberus+1",
  icon: kIconCerberus,
  slot: 'Kinetic',
  element: 'Kinetic',
  ammo: 'Primary',
  frame: 'Exotic Frame',
  itemTypeName: 'Auto Rifle',
  isExotic: true,
  owned: false,
  ownedCount: 0,
  intrinsicName: 'Spread Shot Package',
);

/// Multi-hash same-kind Base (Ribbontail-style fan-out).
List<CatalogItem> ribbontailMultiHashItems({int ownedHashes = 3}) {
  return [
    for (var i = 0; i < 5; i++)
      CatalogItem(
        hash: 400 + i,
        name: 'Ribbontail',
        icon: kIconRibbontail,
        slot: 'Kinetic',
        element: 'Strand',
        ammo: 'Special',
        frame: 'Adaptive Frame',
        itemTypeName: 'Trace Rifle',
        isExotic: false,
        owned: i < ownedHashes,
        ownedCount: i < ownedHashes ? 1 : 0,
      ),
  ];
}

const kUnsworn = CatalogItem(
  hash: 500,
  name: 'Unsworn',
  icon: kIconUnsworn,
  slot: 'Kinetic',
  element: 'Void',
  ammo: 'Special',
  frame: 'Adaptive Frame',
  itemTypeName: 'Trace Rifle',
  isExotic: false,
  owned: true,
  ownedCount: 1,
);

// ---------------------------------------------------------------------------
// Families
// ---------------------------------------------------------------------------

WeaponFamily midnightCoupFamily() => groupWeaponFamilies([
      kMidnightCoupBase,
      kMidnightCoupAdept,
      kMidnightCoupHolofoil,
    ]).single;

WeaponFamily ribbontailFamily({int ownedHashes = 3}) =>
    groupWeaponFamilies(ribbontailMultiHashItems(ownedHashes: ownedHashes))
        .single;

// ---------------------------------------------------------------------------
// Instances + plugs
// ---------------------------------------------------------------------------

CatalogInstanceProjection catalogInstance({
  required String id,
  required int power,
  int itemHash = 101,
  List<Map<String, Object?>>? socketPlugs,
  bool isCrafted = false,
  bool isMasterwork = false,
  int? gearTier,
  String? specialLabel,
}) {
  return CatalogInstanceProjection(
    instanceId: id,
    itemHash: itemHash,
    bucket: 'Equippable',
    location: 'Vault',
    power: power,
    isCrafted: isCrafted,
    isMasterwork: isMasterwork,
    gearTier: gearTier,
    specialLabel: specialLabel,
    socketPlugs: socketPlugs,
    syncedAt: '2026-01-01T00:00:00.000Z',
  );
}

/// Instance sockets: equipped + reusables (①/②).
const kOwnedSocketPlugs = <Map<String, Object?>>[
  {
    'columnKind': 'barrel',
    'columnLabel': 'Barrel',
    'equippedPlugHash': 10,
    'reusablePlugHashes': [10, 11],
  },
  {
    'columnKind': 'magazine',
    'columnLabel': 'Magazine',
    'equippedPlugHash': 20,
    'reusablePlugHashes': [20, 21],
  },
  {
    'columnKind': 'trait',
    'columnLabel': 'Trait',
    'equippedPlugHash': 30,
    'reusablePlugHashes': [30, 31],
  },
  {
    'columnKind': 'origin',
    'columnLabel': 'Origin Trait',
    'equippedPlugHash': 90,
    'reusablePlugHashes': [90],
  },
];

/// Definition pool for unowned / Possible rolls ③ expansion.
const kDefinitionSocketPlugs = <Map<String, Object?>>[
  {
    'columnKind': 'barrel',
    'columnLabel': 'Barrel',
    'equippedPlugHash': 10,
    'reusablePlugHashes': [10, 11, 12],
  },
  {
    'columnKind': 'magazine',
    'columnLabel': 'Magazine',
    'equippedPlugHash': 20,
    'reusablePlugHashes': [20, 21, 22],
  },
  {
    'columnKind': 'trait',
    'columnLabel': 'Trait',
    'equippedPlugHash': 30,
    'reusablePlugHashes': [30, 31, 32],
  },
  {
    'columnKind': 'origin',
    'columnLabel': 'Origin Trait',
    'equippedPlugHash': 90,
    'reusablePlugHashes': [90],
  },
];

const kPlugNameByHash = <int, String>{
  10: 'Arrowhead Brake',
  11: 'Chambered Compensator',
  12: 'Corkscrew Rifling',
  20: 'Accurized Rounds',
  21: 'Appended Mag',
  22: 'Tactical Mag',
  30: 'Kill Clip',
  31: 'Rampage',
  32: 'Outlaw',
  90: 'Omolon Fluid Dynamics',
  100: 'Enhanced Kill Clip',
};

/// Demo plug art: official Bungie PNGs shipped in `destiny2_ui_flutter`
/// (`assets/bungie-content/icons/`). Paths match CDN basenames so
/// [BungieContentIcon] resolves offline. Live host should pass real plug
/// definition icons; these are distinct stand-ins for Widgetbook only.
const kPlugIconByHash = <int, String>{
  // Barrels — weapon frame glyphs
  10: '/common/destiny2_content/icons/967fb4abc6ab98f74639d6c08e5f56ee.png',
  11: '/common/destiny2_content/icons/64209c4fd20513b33109c374179d0958.png',
  12: '/common/destiny2_content/icons/6db8cd21c2b3e6fffeb6f111d6c70dd2.png',
  // Magazines
  20: '/common/destiny2_content/icons/801d62d1f9783bee81d5700c54c24fda.png',
  21: '/common/destiny2_content/icons/e9dd736124e8ef94048901a279a5bb18.png',
  22: '/common/destiny2_content/icons/34573143849cf910d2381554bb57a10d.png',
  // Traits — armor archetype trait icons (trait-like official art)
  30: '/common/destiny2_content/icons/cda905547dd9eac7a39e6e898f619bc5.png',
  31: '/common/destiny2_content/icons/7bc3bc2bccdafc19dde31f867a06ee9f.png',
  32: '/common/destiny2_content/icons/cbf4f03459ab2818a3d37b7362b2aa93.png',
  100: '/common/destiny2_content/icons/cda905547dd9eac7a39e6e898f619bc5.png',
  // Origin
  90: '/common/destiny2_content/icons/b5feb81f684d767d6212ca138f30b34c.png',
};

const kPlugEnhancedByHash = <int, bool>{
  100: true,
};

List<CatalogInstanceProjection> multiPowerInstances({int itemHash = 101}) => [
      catalogInstance(
        id: 'i-high',
        power: 450,
        itemHash: itemHash,
        socketPlugs: kOwnedSocketPlugs,
        gearTier: 5,
        specialLabel: 'Adept',
      ),
      catalogInstance(
        id: 'i-mid',
        power: 445,
        itemHash: itemHash,
        socketPlugs: kOwnedSocketPlugs,
        gearTier: 4,
      ),
      catalogInstance(
        id: 'i-low',
        power: 335,
        itemHash: itemHash,
        socketPlugs: kOwnedSocketPlugs,
        gearTier: 3,
        specialLabel: 'Adept',
      ),
    ];

// ---------------------------------------------------------------------------
// 003 CatalogRollTargets demo scores / profiles
// ---------------------------------------------------------------------------

const kRollTargetOptions = <CatalogRollTargetOption>[
  CatalogRollTargetOption(id: 'rt-pve', name: 'PvE'),
  CatalogRollTargetOption(id: 'rt-pvp', name: 'PvP'),
];

/// Distinct socket plugs per instance for rank demos.
List<CatalogInstanceProjection> rollTargetDemoInstances({
  int itemHash = 101,
  int count = 3,
}) {
  final plugs = <List<Map<String, Object?>>>[
    // perfect: Arrow / Acc / Kill Clip
    const [
      {
        'columnKind': 'barrel',
        'columnLabel': 'Barrel',
        'equippedPlugHash': 10,
        'reusablePlugHashes': [10, 11],
      },
      {
        'columnKind': 'magazine',
        'columnLabel': 'Magazine',
        'equippedPlugHash': 20,
        'reusablePlugHashes': [20, 21],
      },
      {
        'columnKind': 'trait',
        'columnLabel': 'Trait',
        'equippedPlugHash': 30,
        'reusablePlugHashes': [30, 31],
      },
    ],
    // partial: Arrow / App / Rampage
    const [
      {
        'columnKind': 'barrel',
        'columnLabel': 'Barrel',
        'equippedPlugHash': 10,
        'reusablePlugHashes': [10, 11],
      },
      {
        'columnKind': 'magazine',
        'columnLabel': 'Magazine',
        'equippedPlugHash': 21,
        'reusablePlugHashes': [20, 21],
      },
      {
        'columnKind': 'trait',
        'columnLabel': 'Trait',
        'equippedPlugHash': 31,
        'reusablePlugHashes': [30, 31],
      },
    ],
    // dirty: Chamber / App / Outlaw
    const [
      {
        'columnKind': 'barrel',
        'columnLabel': 'Barrel',
        'equippedPlugHash': 11,
        'reusablePlugHashes': [10, 11],
      },
      {
        'columnKind': 'magazine',
        'columnLabel': 'Magazine',
        'equippedPlugHash': 21,
        'reusablePlugHashes': [20, 21],
      },
      {
        'columnKind': 'trait',
        'columnLabel': 'Trait',
        'equippedPlugHash': 32,
        'reusablePlugHashes': [30, 31, 32],
      },
    ],
  ];
  final powers = [400, 450, 420];
  final tiers = [3, 5, 4];
  final ids = ['i-perfect', 'i-partial', 'i-dirty'];
  final n = count.clamp(0, 3);
  return [
    for (var i = 0; i < n; i++)
      catalogInstance(
        id: ids[i],
        power: powers[i],
        itemHash: itemHash,
        socketPlugs: plugs[i],
        gearTier: tiers[i],
        specialLabel: i == 0 ? 'Adept' : null,
      ),
  ];
}

Map<String, CatalogInstanceRollScore> rollTargetScoresForPreset(String preset) {
  switch (preset) {
    case 'perfect':
      return const {
        'i-perfect': CatalogInstanceRollScore(
          preferredMatched: 3,
          preferredScored: 3,
          avoidHits: 0,
          avoidScored: 1,
        ),
        'i-partial': CatalogInstanceRollScore(
          preferredMatched: 1,
          preferredScored: 3,
          avoidHits: 0,
          avoidScored: 1,
        ),
        'i-dirty': CatalogInstanceRollScore(
          preferredMatched: 0,
          preferredScored: 3,
          avoidHits: 1,
          avoidScored: 1,
        ),
      };
    case 'dirty':
      return const {
        'i-perfect': CatalogInstanceRollScore(
          preferredMatched: 2,
          preferredScored: 3,
          avoidHits: 0,
          avoidScored: 1,
        ),
        'i-partial': CatalogInstanceRollScore(
          preferredMatched: 1,
          preferredScored: 3,
          avoidHits: 0,
          avoidScored: 1,
        ),
        'i-dirty': CatalogInstanceRollScore(
          preferredMatched: 0,
          preferredScored: 3,
          avoidHits: 2,
          avoidScored: 2,
        ),
      };
    case 'partial':
    default:
      return const {
        'i-perfect': CatalogInstanceRollScore(
          preferredMatched: 2,
          preferredScored: 3,
          avoidHits: 0,
          avoidScored: 1,
        ),
        'i-partial': CatalogInstanceRollScore(
          preferredMatched: 1,
          preferredScored: 3,
          avoidHits: 0,
          avoidScored: 1,
        ),
        'i-dirty': CatalogInstanceRollScore(
          preferredMatched: 0,
          preferredScored: 3,
          avoidHits: 1,
          avoidScored: 1,
        ),
      };
  }
}

/// Rank order for demo: preferredRatio desc → avoidHits asc → power.
List<CatalogInstanceProjection> rankRollTargetDemoInstances(
  List<CatalogInstanceProjection> instances,
  Map<String, CatalogInstanceRollScore> scores,
) {
  final list = List<CatalogInstanceProjection>.from(instances);
  list.sort((a, b) {
    final sa = scores[a.instanceId];
    final sb = scores[b.instanceId];
    final ra = sa?.preferredRatio ?? 0;
    final rb = sb?.preferredRatio ?? 0;
    final pr = rb.compareTo(ra);
    if (pr != 0) return pr;
    final aa = sa?.avoidHits ?? 0;
    final ab = sb?.avoidHits ?? 0;
    final av = aa.compareTo(ab);
    if (av != 0) return av;
    return b.power.compareTo(a.power);
  });
  return list;
}

const kRollTargetPreferredByColumn = <String, Set<int>>{
  'Barrel': {10},
  'Magazine': {20},
  'Trait': {30},
};

const kRollTargetAvoidByColumn = <String, Set<int>>{
  'Trait': {32},
};
