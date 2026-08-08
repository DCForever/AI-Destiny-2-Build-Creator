import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

/// Host-fixture seeds for CatalogRollTargets Capture + smoke (003).
///
/// Shared by [main_roll_targets_capture.dart] and
/// `test/catalog_roll_targets_host_smoke_test.dart`.
///
/// Matrix ids (`drive: host-fixture`) — document under
/// `docs/ux-redesign/catalog/implementation-shots/003-catalog-roll-targets/COMPARE.md`.

// ---------------------------------------------------------------------------
// Identity
// ---------------------------------------------------------------------------

const int kRollTargetWeaponHash = 92001;
const int kRollTargetUnownedHash = 92002;

// Plugs
const int kRtBarrelArrow = 910;
const int kRtBarrelChamber = 911;
const int kRtMagAcc = 920;
const int kRtMagApp = 921;
const int kRtTraitKill = 930;
const int kRtTraitRampage = 931;
const int kRtTraitOutlaw = 932;

const Map<int, String> kRollTargetPlugNames = {
  kRtBarrelArrow: 'Arrowhead Brake',
  kRtBarrelChamber: 'Chambered Compensator',
  kRtMagAcc: 'Accurized Rounds',
  kRtMagApp: 'Appended Mag',
  kRtTraitKill: 'Kill Clip',
  kRtTraitRampage: 'Rampage',
  kRtTraitOutlaw: 'Outlaw',
};

List<CatalogItem> rollTargetCatalogItems() => [
      const CatalogItem(
        hash: kRollTargetWeaponHash,
        name: 'Roll Target HC',
        slot: 'Kinetic',
        element: 'Kinetic',
        ammo: 'Primary',
        itemTypeName: 'Hand Cannon',
        frame: 'Adaptive Frame',
        isExotic: false,
      ),
      const CatalogItem(
        hash: kRollTargetUnownedHash,
        name: 'Roll Target Unowned',
        slot: 'Energy',
        element: 'Solar',
        ammo: 'Primary',
        itemTypeName: 'Scout Rifle',
        frame: 'Precision Frame',
        isExotic: false,
      ),
    ];

Map<int, List<WeaponPerkColumn>> rollTargetPerkColumns() => {
      kRollTargetWeaponHash: const [
        WeaponPerkColumn(
          column: 0,
          curated: [kRtBarrelArrow, kRtBarrelChamber],
          randomized: [kRtBarrelArrow, kRtBarrelChamber],
        ),
        WeaponPerkColumn(
          column: 1,
          curated: [kRtMagAcc, kRtMagApp],
          randomized: [kRtMagAcc, kRtMagApp],
        ),
        WeaponPerkColumn(
          column: 2,
          curated: [kRtTraitKill, kRtTraitRampage, kRtTraitOutlaw],
          randomized: [kRtTraitKill, kRtTraitRampage, kRtTraitOutlaw],
        ),
      ],
      kRollTargetUnownedHash: const [
        WeaponPerkColumn(
          column: 2,
          curated: [kRtTraitKill, kRtTraitRampage],
          randomized: [kRtTraitKill, kRtTraitRampage, kRtTraitOutlaw],
        ),
      ],
    };

/// Three owned copies: perfect / partial / dirty for rank + dual segs.
List<InventoryItemRecord> rollTargetInventoryItems({
  required String syncedAt,
}) =>
    [
      // Perfect preferred + clean avoid (highest match ratio)
      InventoryItemRecord(
        instanceId: 'rt-perfect',
        itemHash: kRollTargetWeaponHash,
        bucket: 'Kinetic',
        location: 'vault',
        power: 400,
        gearTier: 3,
        socketPlugs: const [
          {
            'socketIndex': 0,
            'columnKind': 'barrel',
            'columnLabel': 'Barrel',
            'equippedPlugHash': kRtBarrelArrow,
            'reusablePlugHashes': [kRtBarrelArrow, kRtBarrelChamber],
          },
          {
            'socketIndex': 1,
            'columnKind': 'magazine',
            'columnLabel': 'Magazine',
            'equippedPlugHash': kRtMagAcc,
            'reusablePlugHashes': [kRtMagAcc, kRtMagApp],
          },
          {
            'socketIndex': 2,
            'columnKind': 'trait',
            'columnLabel': 'Trait',
            'equippedPlugHash': kRtTraitKill,
            'reusablePlugHashes': [kRtTraitKill, kRtTraitRampage],
          },
        ],
        syncedAt: syncedAt,
      ),
      // Partial preferred, clean avoid — higher power than perfect
      InventoryItemRecord(
        instanceId: 'rt-partial',
        itemHash: kRollTargetWeaponHash,
        bucket: 'Kinetic',
        location: 'vault',
        power: 450,
        gearTier: 5,
        socketPlugs: const [
          {
            'socketIndex': 0,
            'columnKind': 'barrel',
            'columnLabel': 'Barrel',
            'equippedPlugHash': kRtBarrelArrow,
            // No Chamber preferred alternate — only Arrow on this copy for barrel.
            'reusablePlugHashes': [kRtBarrelArrow],
          },
          {
            'socketIndex': 1,
            'columnKind': 'magazine',
            'columnLabel': 'Magazine',
            // Miss Accurized preferred — only Appended on this copy.
            'equippedPlugHash': kRtMagApp,
            'reusablePlugHashes': [kRtMagApp],
          },
          {
            'socketIndex': 2,
            'columnKind': 'trait',
            'columnLabel': 'Trait',
            // Miss Kill Clip preferred — only Rampage on this copy.
            'equippedPlugHash': kRtTraitRampage,
            'reusablePlugHashes': [kRtTraitRampage],
          },
        ],
        syncedAt: syncedAt,
      ),
      // Bad roll: miss preferred + avoid hit (Outlaw equipped; no preferred plugs).
      InventoryItemRecord(
        instanceId: 'rt-dirty',
        itemHash: kRollTargetWeaponHash,
        bucket: 'Kinetic',
        location: 'vault',
        power: 420,
        gearTier: 4,
        socketPlugs: const [
          {
            'socketIndex': 0,
            'columnKind': 'barrel',
            'columnLabel': 'Barrel',
            'equippedPlugHash': kRtBarrelChamber,
            'reusablePlugHashes': [kRtBarrelChamber],
          },
          {
            'socketIndex': 1,
            'columnKind': 'magazine',
            'columnLabel': 'Magazine',
            'equippedPlugHash': kRtMagApp,
            'reusablePlugHashes': [kRtMagApp],
          },
          {
            'socketIndex': 2,
            'columnKind': 'trait',
            'columnLabel': 'Trait',
            'equippedPlugHash': kRtTraitOutlaw,
            'reusablePlugHashes': [kRtTraitOutlaw],
          },
        ],
        syncedAt: syncedAt,
      ),
    ];

/// PvE target: prefer Arrow+Acc+Kill; avoid Outlaw.
/// Column keys match [catalogRollColumnKey] (socketIndex → socket_N).
WeaponRollTarget rollTargetPveProfile({
  required int userId,
  String id = 'rt-pve-fixture',
}) {
  return WeaponRollTarget(
    id: id,
    userId: userId.toString(),
    weaponKey: '$kRollTargetWeaponHash',
    name: 'PvE',
    columns: rollTargetPveColumns(),
  );
}

/// Seed DB rows for [rollTargetPveProfile] via app use cases (caller).
List<RollTargetColumn> rollTargetPveColumns() => const [
      RollTargetColumn(
        columnKey: 'socket_0',
        label: 'Barrel',
        preferredPlugHashes: {kRtBarrelArrow},
      ),
      RollTargetColumn(
        columnKey: 'socket_1',
        label: 'Magazine',
        preferredPlugHashes: {kRtMagAcc},
      ),
      RollTargetColumn(
        columnKey: 'socket_2',
        label: 'Trait',
        preferredPlugHashes: {kRtTraitKill},
        avoidPlugHashes: {kRtTraitOutlaw},
      ),
    ];
