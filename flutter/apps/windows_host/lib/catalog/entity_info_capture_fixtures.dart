import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';

/// Host-fixture seeds for EntityInfoHotspot Capture (004).
///
/// Description strings are **fixtures only** for dual-truth Capture /
/// Widgetbook — production hosts load maps from entity defs and never invent.

const int kEntityInfoWeaponHash = 94001;

const int kEiFrenzy = 940;
const int kEiOverflow = 941;
const int kEiIncandescent = 942;
const int kEiUnknown = 949;
const int kEiEnhanced = 950;

const Map<int, String> kEntityInfoDescriptions = {
  kEiFrenzy:
      'Being in combat for an extended time increases damage, handling, and reload for you and nearby allies until you are out of combat.',
  kEiOverflow:
      'Picking up Special or Heavy ammo automatically loads this weapon beyond normal capacity.',
  kEiIncandescent:
      'Defeating a target spreads scorch to those nearby. More powerful combatants cause scorch in a larger radius.',
  kEiEnhanced:
      'Being in combat for an extended time increases damage, handling, and reload. Enhanced: improved timer and ally radius (fixture).',
};

const Map<int, String> kEntityInfoNames = {
  kEiFrenzy: 'Frenzy',
  kEiOverflow: 'Overflow',
  kEiIncandescent: 'Incandescent',
  kEiUnknown: 'Unknown perk',
  kEiEnhanced: 'Frenzy',
};

/// Presentations for Capture / smoke. [emptyDesc] forces honest empty body.
Map<int, EntityInfoData> entityInfoCapturePresentations({
  bool includeUnknown = false,
  bool enhanced = false,
  bool emptyDesc = false,
}) {
  final out = <int, EntityInfoData>{
    kEiFrenzy: EntityInfoData(
      id: '$kEiFrenzy',
      name: 'Frenzy',
      kind: 'Trait',
      description: emptyDesc ? '' : kEntityInfoDescriptions[kEiFrenzy]!,
      metaLines: const ['① on this copy'],
    ),
    kEiOverflow: EntityInfoData(
      id: '$kEiOverflow',
      name: 'Overflow',
      kind: 'Trait',
      description: emptyDesc ? '' : kEntityInfoDescriptions[kEiOverflow]!,
      metaLines: const ['② unselected'],
    ),
    kEiIncandescent: EntityInfoData(
      id: '$kEiIncandescent',
      name: 'Incandescent',
      kind: 'Trait',
      description: emptyDesc ? '' : kEntityInfoDescriptions[kEiIncandescent]!,
      metaLines: const ['③ possible roll'],
    ),
  };
  if (includeUnknown) {
    out[kEiUnknown] = const EntityInfoData(
      id: '$kEiUnknown',
      name: 'Unknown perk',
      kind: 'Trait',
      description: '',
      nameUnknown: true,
      hashFooter: '#949',
    );
  }
  if (enhanced) {
    out[kEiEnhanced] = EntityInfoData(
      id: '$kEiEnhanced',
      name: 'Frenzy',
      kind: 'Trait',
      description: kEntityInfoDescriptions[kEiEnhanced]!,
      metaLines: const ['① Enhanced (this copy)'],
      baseDescription: kEntityInfoDescriptions[kEiFrenzy],
      enhancedDescription: kEntityInfoDescriptions[kEiEnhanced],
    );
  }
  return out;
}

List<CatalogItem> entityInfoCatalogItems() => [
      const CatalogItem(
        hash: kEntityInfoWeaponHash,
        name: 'Entity Info Fixture AR',
        slot: 'Kinetic',
        element: 'Kinetic',
        ammo: 'Primary',
        itemTypeName: 'Auto Rifle',
        frame: 'Adaptive Frame',
        isExotic: false,
      ),
    ];

Map<int, List<WeaponPerkColumn>> entityInfoPerkColumns() => {
      kEntityInfoWeaponHash: const [
        WeaponPerkColumn(
          column: 0,
          curated: [kEiFrenzy, kEiOverflow, kEiIncandescent],
          randomized: [kEiFrenzy, kEiOverflow, kEiIncandescent],
        ),
      ],
    };

List<InventoryItemRecord> entityInfoInventory({required String syncedAt}) => [
      InventoryItemRecord(
        instanceId: 'ei-owned',
        itemHash: kEntityInfoWeaponHash,
        bucket: 'Kinetic',
        location: 'vault',
        power: 1810,
        gearTier: 3,
        socketPlugs: const [
          {
            'socketIndex': 0,
            'columnKind': 'trait',
            'columnLabel': 'Trait',
            'equippedPlugHash': kEiFrenzy,
            'reusablePlugHashes': [kEiFrenzy, kEiOverflow],
          },
        ],
        syncedAt: syncedAt,
      ),
    ];

/// Perk columns for detail grid (owned ①/② + can-roll ③).
List<CatalogPerkColumn> entityInfoPerkGridColumns({
  bool enhancedSelected = false,
  bool includeUnknown = false,
}) {
  final traitCells = <CatalogPerkCell>[
    CatalogPerkCell(
      hash: enhancedSelected ? kEiEnhanced : kEiFrenzy,
      displayName: 'Frenzy',
      selected: true,
      enhanced: enhancedSelected,
    ),
    const CatalogPerkCell(
      hash: kEiOverflow,
      displayName: 'Overflow',
      selected: false,
    ),
    const CatalogPerkCell(
      hash: kEiIncandescent,
      displayName: 'Incandescent',
      fromCanRollPool: true,
    ),
    if (includeUnknown)
      const CatalogPerkCell(
        hash: kEiUnknown,
        displayName: 'Unknown perk',
        selected: false,
        unknown: true,
      ),
  ];
  return [
    CatalogPerkColumn(label: 'Trait', kind: 'Trait', cells: traitCells),
  ];
}
