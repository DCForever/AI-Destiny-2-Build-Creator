/// Host-fixture seeds for Catalog Armor dual-truth Capture (`drive: host-fixture`).
///
/// Keep in sync with `test/catalog_armor_fixtures.dart`.
library;

import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';

import 'armor_detail_projection.dart';

// ---------------------------------------------------------------------------
// Definition identities (one card per hash)
// ---------------------------------------------------------------------------

const kArmorSynthoceps = CatalogItem(
  hash: 91001,
  name: 'Synthoceps',
  slot: 'Gauntlets',
  classType: 'Titan',
  isExotic: true,
  intrinsicName: 'Biotic Enhancements',
  description: 'Increased melee lunge range.',
  owned: true,
  ownedCount: 2,
);

const kArmorCuirass = CatalogItem(
  hash: 91002,
  name: 'Cuirass of the Falling Star',
  slot: 'Chest',
  classType: 'Titan',
  isExotic: true,
  intrinsicName: 'Impact Conversion',
  description: 'Supers gain damage after a thruster.',
  owned: true,
  ownedCount: 1,
);

const kArmorFieldPlate = CatalogItem(
  hash: 91003,
  name: 'Field-Tested Plate',
  slot: 'Chest',
  classType: 'Hunter',
  isExotic: false,
  owned: false,
  ownedCount: 0,
);

const kArmorStridehunt = CatalogItem(
  hash: 91004,
  name: 'Stridehunt Greaves',
  slot: 'Legs',
  classType: 'Warlock',
  isExotic: false,
  owned: true,
  ownedCount: 3,
);

const kArmorClassItem = CatalogItem(
  hash: 91005,
  name: 'Mark of the Lost',
  slot: 'ClassItem',
  classType: 'Titan',
  isExotic: false,
  owned: false,
  ownedCount: 0,
);

/// All armor fixture identities for grid Capture.
const kArmorCaptureItems = <CatalogItem>[
  kArmorSynthoceps,
  kArmorCuirass,
  kArmorFieldPlate,
  kArmorStridehunt,
  kArmorClassItem,
];

// ---------------------------------------------------------------------------
// Instance projections
// ---------------------------------------------------------------------------

Map<String, Object?> _stats({
  required int health,
  required int melee,
  required int grenade,
  required int superStat,
  required int classStat,
  required int weapons,
  int? energyUsed,
  int? energyCapacity,
}) {
  return {
    'Health': health,
    'Melee': melee,
    'Grenade': grenade,
    'Super': superStat,
    'Class': classStat,
    'Weapons': weapons,
    if (energyUsed != null) 'energyUsed': energyUsed,
    if (energyCapacity != null) 'energyCapacity': energyCapacity,
  };
}

/// Multi-copy Synthoceps: high base total first when strip-sorted.
List<CatalogInstanceProjection> kSynthocepsCaptureInstances() {
  return [
    CatalogInstanceProjection(
      instanceId: 'syn-low',
      itemHash: kArmorSynthoceps.hash,
      bucket: 'Equippable',
      location: 'Vault',
      power: 2000,
      gearTier: 3,
      statValues: _stats(
        health: 15,
        melee: 15,
        grenade: 10,
        superStat: 10,
        classStat: 10,
        weapons: 10,
        energyUsed: 2,
        energyCapacity: 10,
      ),
      plugHashes: const [7001, 7002],
      socketPlugs: const [
        {
          'columnKind': 'mod',
          'columnLabel': 'Armor Mod',
          'equippedPlugHash': 7001,
          'reusablePlugHashes': <int>[],
        },
      ],
      plugCards: const [
        ResolvedPlugCard(
          hash: 7001,
          displayName: 'Heavy Handed',
          resolved: true,
          columnKind: 'mod',
          columnLabel: 'Armor Mod',
        ),
        ResolvedPlugCard(
          hash: 7002,
          displayName: 'Powerful Friends',
          resolved: true,
          columnKind: 'mod',
          columnLabel: 'Armor Mod',
        ),
      ],
      armorStats: const ArmorBaseStatBoard(
        stats: {
          'Health': 12,
          'Melee': 18,
          'Grenade': 8,
          'Super': 10,
          'Class': 10,
          'Weapons': 8,
        },
        total: 66,
      ),
      syncedAt: '2026-08-01T00:00:00.000Z',
    ),
    CatalogInstanceProjection(
      instanceId: 'syn-high',
      itemHash: kArmorSynthoceps.hash,
      bucket: 'Equippable',
      location: 'character',
      power: 1995,
      gearTier: 5,
      statValues: _stats(
        health: 40,
        melee: 50,
        grenade: 20,
        superStat: 25,
        classStat: 22,
        weapons: 18,
        energyUsed: 5,
        energyCapacity: 10,
      ),
      plugHashes: const [7001],
      socketPlugs: const [
        {
          'columnKind': 'mod',
          'columnLabel': 'Armor Mod',
          'equippedPlugHash': 7001,
          'reusablePlugHashes': <int>[],
        },
      ],
      plugCards: const [
        ResolvedPlugCard(
          hash: 7001,
          displayName: 'Heavy Handed',
          resolved: true,
          columnKind: 'mod',
          columnLabel: 'Armor Mod',
        ),
      ],
      armorStats: const ArmorBaseStatBoard(
        stats: {
          'Health': 30,
          'Melee': 40,
          'Grenade': 15,
          'Super': 20,
          'Class': 18,
          'Weapons': 15,
        },
        total: 138,
      ),
      syncedAt: '2026-08-01T00:00:00.000Z',
    ),
    // Live-null copy (base present, live missing).
    CatalogInstanceProjection(
      instanceId: 'syn-live-null',
      itemHash: kArmorSynthoceps.hash,
      bucket: 'Equippable',
      location: 'Vault',
      power: 1980,
      gearTier: 2,
      armorStats: const ArmorBaseStatBoard(
        stats: {
          'Health': 20,
          'Melee': 20,
          'Grenade': 10,
          'Super': 10,
          'Class': 10,
          'Weapons': 10,
        },
        total: 80,
      ),
      syncedAt: '2026-08-01T00:00:00.000Z',
    ),
  ];
}

const Map<int, String> kArmorCapturePlugNames = {
  7001: 'Heavy Handed',
  7002: 'Powerful Friends',
};

List<ArmorInstanceStripItem> armorOwnedStripItems() => projectArmorInstances(
      kSynthocepsCaptureInstances(),
      plugNameByHash: kArmorCapturePlugNames,
    );

List<ArmorInstanceStripItem> armorModsEnergyStripItems() =>
    projectArmorInstances(
      [kSynthocepsCaptureInstances().first],
      plugNameByHash: kArmorCapturePlugNames,
    );

List<ArmorInstanceStripItem> armorLiveNullStripItems() => projectArmorInstances(
      [kSynthocepsCaptureInstances().last],
      plugNameByHash: kArmorCapturePlugNames,
    );

const kArmorSetBonusTechsec = ArmorSetBonusData(
  setName: 'Techsec',
  twoPiece: 'Faster reload after ability kill',
  fourPiece: 'Orbs on multi-kill',
);

const kArmorSetBonusNone = ArmorSetBonusData(explicitNone: true);

ArmorExoticPerkData? kSynthocepsExoticPerk() => armorExoticPerkFromItem(
      isExotic: kArmorSynthoceps.isExotic,
      intrinsicName: kArmorSynthoceps.intrinsicName,
      description: kArmorSynthoceps.description,
    );

/// Matrix ids (`drive: host-fixture`) for Capture sequence.
const kArmorCaptureMatrixIds = <String>[
  'desktop-grid',
  'desktop-detail-owned',
  'desktop-instance-strip',
  'desktop-detail-unowned',
  'desktop-set-bonus',
  'desktop-mods-energy',
  'desktop-exotic-callout',
  'desktop-owned-empty',
  'desktop-signed-out-owned',
  'desktop-live-null-copy',
  'desktop-soft-error',
];
