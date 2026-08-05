import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';

/// Host-fixture seeds for residual-polish Capture + smoke
/// (`desktop-enhanced-live`, `desktop-catalyst-present`, `desktop-enhance-note`).
///
/// Drive with injectable [OwnedCatalogBridge] + signed-in inventory on
/// [CatalogPage]. Keys stay stable for Flutter Driver / widget finders.
///
/// See `docs/ux-redesign/catalog/implementation-shots/001-residual-polish/COMPARE.md`.

// ---------------------------------------------------------------------------
// Identity hashes (definition)
// ---------------------------------------------------------------------------

/// Owned legendary with enhanced ① plug + can-roll pool (enhance note).
const int kResidualEnhancedWeaponHash = 91001;

/// Unowned exotic with catalyst fields non-empty (display-only panel).
const int kResidualCatalystExoticHash = 91002;

/// Unowned legendary whose definition pool includes Enhanced identity
/// (note only; no E cells).
const int kResidualEnhanceNoteWeaponHash = 91003;

// Plug hashes
const int kResidualEnhancedPlugHash = 801; // ① Enhanced Frenzy (host map true)
const int kResidualBasePlugHash = 802; // ② Overflow (not enhanced)
const int kResidualPoolEnhancedPlugHash = 803; // ③ Enhanced Kill Clip (note only)
const int kResidualPoolBasePlugHash = 804; // ③ Rapid Hit (base)

/// Plug names for bridge seed / name-heuristic paths.
const Map<int, String> kResidualPlugNameByHash = {
  kResidualEnhancedPlugHash: 'Enhanced Frenzy',
  kResidualBasePlugHash: 'Overflow',
  kResidualPoolEnhancedPlugHash: 'Enhanced Kill Clip',
  kResidualPoolBasePlugHash: 'Rapid Hit',
};

/// Host map: only instance ① is enhanced (gold+E). ③ hashes omitted or false.
const Map<int, bool> kResidualPlugEnhancedByHash = {
  kResidualEnhancedPlugHash: true,
};

/// Catalog rows for residual-polish host fixtures.
List<CatalogItem> residualPolishCatalogItems() => [
      const CatalogItem(
        hash: kResidualEnhancedWeaponHash,
        name: 'Residual Enhanced HC',
        slot: 'Kinetic',
        element: 'Kinetic',
        ammo: 'Primary',
        itemTypeName: 'Hand Cannon',
        frame: 'Adaptive Frame',
        isExotic: false,
      ),
      const CatalogItem(
        hash: kResidualCatalystExoticHash,
        name: 'Residual Catalyst Exotic',
        slot: 'Kinetic',
        element: 'Kinetic',
        ammo: 'Primary',
        itemTypeName: 'Hand Cannon',
        frame: 'Adaptive Frame',
        isExotic: true,
        intrinsicName: 'Memento Mori',
        catalystName: 'Ace of Spades Catalyst',
        catalystDescription: 'Kills with this weapon grant improved stability.',
      ),
      const CatalogItem(
        hash: kResidualEnhanceNoteWeaponHash,
        name: 'Residual Enhance-Note Scout',
        slot: 'Energy',
        element: 'Solar',
        ammo: 'Primary',
        itemTypeName: 'Scout Rifle',
        frame: 'Precision Frame',
        isExotic: false,
      ),
    ];

/// Definition perk columns: enhanced identity in randomized pool (note path).
Map<int, List<WeaponPerkColumn>> residualPolishPerkColumns() => {
      kResidualEnhancedWeaponHash: const [
        WeaponPerkColumn(
          column: 2, // Trait 1
          curated: [kResidualEnhancedPlugHash, kResidualBasePlugHash],
          randomized: [
            kResidualEnhancedPlugHash,
            kResidualBasePlugHash,
            kResidualPoolBasePlugHash,
            kResidualPoolEnhancedPlugHash,
          ],
        ),
      ],
      kResidualEnhanceNoteWeaponHash: const [
        WeaponPerkColumn(
          column: 2,
          curated: [kResidualPoolBasePlugHash],
          randomized: [
            kResidualPoolBasePlugHash,
            kResidualPoolEnhancedPlugHash,
          ],
        ),
      ],
      // Exotic: empty perk columns — catalyst panel is independent of plugs.
    };

/// Owned instance with ① Enhanced + ② base reusable (socket_plugs shape).
InventoryItemRecord residualEnhancedInventoryRow({
  String syncedAt = '2026-08-04T12:00:00.000Z',
}) {
  return InventoryItemRecord(
    instanceId: 'residual-enhanced-inst',
    itemHash: kResidualEnhancedWeaponHash,
    bucket: 'Kinetic',
    location: 'vault',
    power: 1810,
    isMasterwork: true,
    plugHashes: const [kResidualEnhancedPlugHash, kResidualBasePlugHash],
    socketPlugs: const [
      {
        'columnKind': 'trait',
        'columnLabel': 'Trait',
        'equippedPlugHash': kResidualEnhancedPlugHash,
        'reusablePlugHashes': [
          kResidualEnhancedPlugHash,
          kResidualBasePlugHash,
        ],
      },
    ],
    syncedAt: syncedAt,
  );
}
