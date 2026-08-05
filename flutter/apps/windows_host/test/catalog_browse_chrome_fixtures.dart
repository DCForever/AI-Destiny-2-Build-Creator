import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

/// Host-fixture seeds for browse-chrome Capture + smoke
/// (`desktop-family-card`, `desktop-detail-versions`, `desktop-sort-reorder`,
/// `desktop-group-priority`, `desktop-detail-no-band-labels`).
///
/// Drive with injectable [OwnedCatalogBridge] + optional signed-in inventory on
/// [CatalogPage]. Keys stay stable for Flutter Driver / widget finders.
///
/// See `docs/ux-redesign/catalog/implementation-shots/001-browse-chrome/COMPARE.md`.

// ---------------------------------------------------------------------------
// Identity hashes (definition) — Midnight Coup family + singles
// ---------------------------------------------------------------------------

const int kBrowseBaseHash = 3141979346;
const int kBrowseAdeptHash = 3141979347;
const int kBrowseHolofoilHash = 3141979348;
const int kBrowseSoloExoticHash = 347366834;
const int kBrowseEnergyHash = 2001001;
const int kBrowseEnergyAdeptHash = 2001002;

/// Catalog rows: multi-version family + singles for grid/group/sort shots.
List<CatalogItem> browseChromeCatalogItems() => [
      const CatalogItem(
        hash: kBrowseBaseHash,
        name: 'Midnight Coup',
        slot: 'Kinetic',
        element: 'Kinetic',
        ammo: 'Primary',
        itemTypeName: 'Hand Cannon',
        frame: 'Aggressive Frame',
        isExotic: false,
      ),
      const CatalogItem(
        hash: kBrowseAdeptHash,
        name: 'Midnight Coup (Adept)',
        slot: 'Kinetic',
        element: 'Kinetic',
        ammo: 'Primary',
        itemTypeName: 'Hand Cannon',
        frame: 'Aggressive Frame',
        isExotic: false,
      ),
      const CatalogItem(
        hash: kBrowseHolofoilHash,
        name: 'Midnight Coup Holofoil',
        slot: 'Kinetic',
        element: 'Kinetic',
        ammo: 'Primary',
        itemTypeName: 'Hand Cannon',
        frame: 'Aggressive Frame',
        isExotic: false,
      ),
      const CatalogItem(
        hash: kBrowseSoloExoticHash,
        name: 'Ace of Spades',
        slot: 'Kinetic',
        element: 'Kinetic',
        ammo: 'Primary',
        itemTypeName: 'Hand Cannon',
        frame: 'Adaptive Frame',
        isExotic: true,
        intrinsicName: 'Memento Mori',
      ),
      const CatalogItem(
        hash: kBrowseEnergyHash,
        name: 'Ringing Nail',
        slot: 'Energy',
        element: 'Solar',
        ammo: 'Primary',
        itemTypeName: 'Auto Rifle',
        frame: 'Adaptive Frame',
        isExotic: false,
      ),
      const CatalogItem(
        hash: kBrowseEnergyAdeptHash,
        name: 'Ringing Nail (Adept)',
        slot: 'Energy',
        element: 'Solar',
        ammo: 'Primary',
        itemTypeName: 'Auto Rifle',
        frame: 'Adaptive Frame',
        isExotic: false,
      ),
    ];

/// Owned inventory: base + adept for Midnight Coup; none for Holofoil.
/// Power: adept higher so openVersion prefers adept when map injected.
List<InventoryItemRecord> browseChromeOwnedInventory({
  required String syncedAt,
}) =>
    [
      InventoryItemRecord(
        instanceId: 'browse-base-1',
        itemHash: kBrowseBaseHash,
        bucket: 'kinetic',
        location: 'vault',
        power: 1805,
        plugHashes: const [501, 502],
        socketPlugs: const [
          {
            'columnLabel': 'Trait',
            'columnKind': 'trait',
            'equippedPlugHash': 501,
            'reusablePlugHashes': [501, 502],
          },
        ],
        syncedAt: syncedAt,
      ),
      InventoryItemRecord(
        instanceId: 'browse-base-2',
        itemHash: kBrowseBaseHash,
        bucket: 'kinetic',
        location: 'vault',
        power: 1800,
        plugHashes: const [501],
        syncedAt: syncedAt,
      ),
      InventoryItemRecord(
        instanceId: 'browse-adept-1',
        itemHash: kBrowseAdeptHash,
        bucket: 'kinetic',
        location: 'character',
        power: 1810,
        plugHashes: const [503, 504],
        socketPlugs: const [
          {
            'columnLabel': 'Trait',
            'columnKind': 'trait',
            'equippedPlugHash': 503,
            'reusablePlugHashes': [503, 504],
          },
        ],
        syncedAt: syncedAt,
      ),
      InventoryItemRecord(
        instanceId: 'browse-energy-1',
        itemHash: kBrowseEnergyHash,
        bucket: 'energy',
        location: 'vault',
        power: 1800,
        plugHashes: const [505],
        syncedAt: syncedAt,
      ),
    ];

const Map<int, String> kBrowsePlugNameByHash = {
  501: 'Firefly',
  502: 'Frenzy',
  503: 'Outlaw',
  504: 'Rampage',
  505: 'Subsistence',
};

/// Definition perk columns for residual no-band-label detail shot.
Map<int, List<WeaponPerkColumn>> browseChromePerkColumns() => {
      kBrowseBaseHash: const [
        WeaponPerkColumn(
          column: 2,
          curated: [501, 502],
          randomized: [501, 502, 503, 504],
        ),
      ],
      kBrowseAdeptHash: const [
        WeaponPerkColumn(
          column: 2,
          curated: [503, 504],
          randomized: [501, 502, 503, 504],
        ),
      ],
    };
