/// Pure demo data for Widgetbook catalog use cases — no IO, no secrets.
library;

import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

// ---------------------------------------------------------------------------
// Items
// ---------------------------------------------------------------------------

const kMidnightCoupBase = CatalogItem(
  hash: 101,
  name: 'Midnight Coup',
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
}) {
  return CatalogInstanceProjection(
    instanceId: id,
    itemHash: itemHash,
    bucket: 'Equippable',
    location: 'Vault',
    power: power,
    isCrafted: isCrafted,
    isMasterwork: isMasterwork,
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

const kPlugEnhancedByHash = <int, bool>{
  100: true,
};

List<CatalogInstanceProjection> multiPowerInstances({int itemHash = 101}) => [
      catalogInstance(
        id: 'i-high',
        power: 1810,
        itemHash: itemHash,
        socketPlugs: kOwnedSocketPlugs,
        isMasterwork: true,
      ),
      catalogInstance(
        id: 'i-mid',
        power: 1800,
        itemHash: itemHash,
        socketPlugs: kOwnedSocketPlugs,
      ),
      catalogInstance(
        id: 'i-low',
        power: 1790,
        itemHash: itemHash,
        socketPlugs: kOwnedSocketPlugs,
        isCrafted: true,
      ),
    ];
