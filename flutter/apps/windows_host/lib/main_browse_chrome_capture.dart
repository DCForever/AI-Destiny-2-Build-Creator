import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'auth/browser_launcher.dart';
import 'auth/token_store.dart';
import 'catalog/catalog_page.dart';
import 'catalog/owned_catalog_bridge.dart';
import 'host_bootstrap.dart';
import 'theme/flap_theme.dart';

/// Browse-chrome dual-truth Capture entrypoint (`drive: host-fixture`).
///
/// Seeds Midnight Coup family (base+adept owned, Holofoil unowned), Ringing
/// Nail energy family, Ace exotic, perk columns for no-band-label shot — then
/// opens [CatalogPage] for Flutter Driver screenshots under
/// `docs/ux-redesign/catalog/implementation-shots/001-browse-chrome/`.
///
/// Keep seeds in sync with `test/catalog_browse_chrome_fixtures.dart`.
///
/// ```text
/// flutter run -d windows -t lib/main_browse_chrome_capture.dart
/// ```
///
/// Matrix ids (Driver keys / search):
/// - Midnight Coup family card → desktop-family-card / desktop-type-icon-filters
/// - tap `catalog_item_3141979346` → desktop-detail-versions / desktop-detail-no-band-labels
/// - More → `group_chip_slot` → desktop-group-collapse / desktop-group-outline-jump
/// - SORT & GROUP sheet → desktop-sort-reorder / desktop-group-priority
Future<void> main() async {
  enableFlutterDriverExtension();
  debugPrint(
    'main_browse_chrome_capture: Flutter Driver on · browse-chrome host fixtures',
  );
  WidgetsFlutterBinding.ensureInitialized();

  final temp = await Directory.systemTemp.createTemp('browse_chrome_capture_');
  final root = StorageRoot(basePath: temp.path);
  await root.ensureLayout();

  final db = AppDatabase.memory();
  final tokenStore = MemoryTokenStore();
  final now = DateTime.now().toUtc();
  await tokenStore.write(
    BungieTokens(
      accessToken: 'access-browse-chrome-capture',
      refreshToken: 'refresh-browse-chrome-capture',
      expiresAt: now.add(const Duration(hours: 1)),
      refreshExpiresAt: now.add(const Duration(days: 1)),
      bungieMembershipId: 'bungie-browse-chrome-capture',
    ),
  );

  final services = await HostBootstrap.open(
    storageRoot: root,
    database: db,
    manifestRefresh: _NoopRefresh(),
    offlineCatalog: OfflineCatalog.preloaded(
      storageRoot: root,
      items: _catalogItems,
      version: 'browse-chrome-capture-live',
      perkColumnsByHash: _perkColumns,
    ),
    clientId: 'browse-chrome-capture',
    tokenStore: tokenStore,
    browserLauncher: FakeBrowserLauncher(),
    profileClient: _EmptyProfileClient(),
    oauthClient: BungieOAuthClient(
      clientId: 'browse-chrome-capture',
      redirectUri: kDefaultWindowsRedirectUri,
      transport: (_) async => throw StateError('unused'),
    ),
  );

  final user = await ensureUser(
    db,
    bungieMembershipId: 'bungie-browse-chrome-capture',
    membershipType: 3,
    displayName: 'Browse Chrome Capture',
  );
  final syncedAt = now.toIso8601String();
  await replaceInventoryBatch(
    db,
    user.id,
    now: syncedAt,
    items: _ownedInventory(syncedAt: syncedAt),
  );

  final bridge = OwnedCatalogBridge(
    db: db,
    offlineCatalog: services.offlineCatalog,
    session: services.oauthSession,
    inventorySync: services.inventorySync,
    plugNameByHash: _plugNames,
    plugNameMapBuilder: (hashes) async => {
      for (final h in hashes)
        if (_plugNames.containsKey(h)) h: _plugNames[h]!,
    },
  );

  runApp(
    MaterialApp(
      title: 'Browse chrome capture',
      debugShowCheckedModeBanner: true,
      theme: buildFlapTheme(),
      home: Scaffold(
        body: CatalogPage(
          key: const Key('catalog_page'),
          services: services,
          bridge: bridge,
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Fixture seeds (keep in sync with test/catalog_browse_chrome_fixtures.dart)
// ---------------------------------------------------------------------------

const int kBrowseBaseHash = 3141979346;
const int kBrowseAdeptHash = 3141979347;
const int kBrowseHolofoilHash = 3141979348;
const int kBrowseSoloExoticHash = 347366834;
const int kBrowseEnergyHash = 2001001;
const int kBrowseEnergyAdeptHash = 2001002;

const Map<int, String> _plugNames = {
  501: 'Firefly',
  502: 'Frenzy',
  503: 'Outlaw',
  504: 'Rampage',
  505: 'Subsistence',
};

const List<CatalogItem> _catalogItems = [
  CatalogItem(
    hash: kBrowseBaseHash,
    name: 'Midnight Coup',
    slot: 'Kinetic',
    element: 'Kinetic',
    ammo: 'Primary',
    itemTypeName: 'Hand Cannon',
    frame: 'Aggressive Frame',
    isExotic: false,
  ),
  CatalogItem(
    hash: kBrowseAdeptHash,
    name: 'Midnight Coup (Adept)',
    slot: 'Kinetic',
    element: 'Kinetic',
    ammo: 'Primary',
    itemTypeName: 'Hand Cannon',
    frame: 'Aggressive Frame',
    isExotic: false,
  ),
  CatalogItem(
    hash: kBrowseHolofoilHash,
    name: 'Midnight Coup Holofoil',
    slot: 'Kinetic',
    element: 'Kinetic',
    ammo: 'Primary',
    itemTypeName: 'Hand Cannon',
    frame: 'Aggressive Frame',
    isExotic: false,
  ),
  CatalogItem(
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
  CatalogItem(
    hash: kBrowseEnergyHash,
    name: 'Ringing Nail',
    slot: 'Energy',
    element: 'Solar',
    ammo: 'Primary',
    itemTypeName: 'Auto Rifle',
    frame: 'Adaptive Frame',
    isExotic: false,
  ),
  CatalogItem(
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

final Map<int, List<WeaponPerkColumn>> _perkColumns = {
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

List<InventoryItemRecord> _ownedInventory({required String syncedAt}) => [
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

class _NoopRefresh implements ManifestRefreshApi {
  @override
  Future<bool> isStale() async => false;

  @override
  Future<ManifestStatus> refresh({
    bool forceFullDownload = false,
    bool rebuildInIsolate = true,
  }) async =>
      const ManifestStatus(
        cachedVersion: null,
        remoteVersion: null,
        isStale: true,
        entityCache: null,
      );

  @override
  Future<ManifestStatus> status() async =>
      const ManifestStatus(
        cachedVersion: null,
        remoteVersion: null,
        isStale: true,
        entityCache: null,
      );
}

class _EmptyProfileClient implements BungieProfileClient {
  @override
  Future<List<DestinyMembership>> getMemberships(String accessToken) async =>
      const [
        DestinyMembership(
          membershipType: 3,
          membershipId: 'destiny-browse-chrome',
          displayName: 'Browse Chrome Capture',
        ),
      ];

  @override
  Future<List<CharacterSummary>> getCharacters(
    String accessToken,
    DestinyMembership membership,
  ) async =>
      const [];

  @override
  Future<Object?> getCharacterLoadoutsProfile(
    String accessToken,
    DestinyMembership membership,
  ) async =>
      null;

  @override
  Future<List<RawInventoryItem>> getFullInventory(
    String accessToken,
    DestinyMembership membership,
  ) async =>
      const [];

  @override
  Future<FullInventoryParseResult> getFullInventoryWithDiagnostics(
    String accessToken,
    DestinyMembership membership,
  ) async =>
      FullInventoryParseResult(
        items: const [],
        diagnostics: InventoryParseDiagnostics(
          membership: membership,
          raw: InventoryRawCounts(),
          parsed: InventoryParsedCounts(),
          dropped: InventoryDroppedCounts(),
        ),
      );
}
