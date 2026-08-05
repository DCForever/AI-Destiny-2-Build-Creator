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

/// Residual-polish dual-truth Capture entrypoint (`drive: host-fixture`).
///
/// Seeds [OwnedCatalogBridge.plugEnhancedByHash], catalyst-present exotic, and
/// unowned enhance-note scout — then opens [CatalogPage] for Flutter Driver
/// screenshots under
/// `docs/ux-redesign/catalog/implementation-shots/001-residual-polish/`.
///
/// ```text
/// flutter run -d windows -t lib/main_residual_capture.dart
/// ```
///
/// Matrix ids (search box / item keys):
/// - Residual Enhanced HC → desktop-enhanced-live
/// - Residual Catalyst Exotic → desktop-catalyst-present
/// - Residual Enhance-Note Scout → desktop-enhance-note
Future<void> main() async {
  enableFlutterDriverExtension();
  debugPrint(
    'main_residual_capture: Flutter Driver on · residual-polish host fixtures',
  );
  WidgetsFlutterBinding.ensureInitialized();

  final temp = await Directory.systemTemp.createTemp('residual_capture_live_');
  final root = StorageRoot(basePath: temp.path);
  await root.ensureLayout();

  final db = AppDatabase.memory();
  final tokenStore = MemoryTokenStore();
  final now = DateTime.now().toUtc();
  await tokenStore.write(
    BungieTokens(
      accessToken: 'access-residual-capture',
      refreshToken: 'refresh-residual-capture',
      expiresAt: now.add(const Duration(hours: 1)),
      refreshExpiresAt: now.add(const Duration(days: 1)),
      bungieMembershipId: 'bungie-residual-capture',
    ),
  );

  final services = await HostBootstrap.open(
    storageRoot: root,
    database: db,
    manifestRefresh: _NoopRefresh(),
    offlineCatalog: OfflineCatalog.preloaded(
      storageRoot: root,
      items: _catalogItems,
      version: 'residual-polish-capture-live',
      perkColumnsByHash: _perkColumns,
    ),
    clientId: 'residual-capture',
    tokenStore: tokenStore,
    browserLauncher: FakeBrowserLauncher(),
    profileClient: _EmptyProfileClient(),
    oauthClient: BungieOAuthClient(
      clientId: 'residual-capture',
      redirectUri: kDefaultWindowsRedirectUri,
      transport: (_) async => throw StateError('unused'),
    ),
  );

  final user = await ensureUser(
    db,
    bungieMembershipId: 'bungie-residual-capture',
    membershipType: 3,
    displayName: 'Residual Capture',
  );
  await replaceInventoryBatch(
    db,
    user.id,
    now: now.toIso8601String(),
    items: [
      InventoryItemRecord(
        instanceId: 'residual-enhanced-inst',
        itemHash: kEnhancedWeaponHash,
        bucket: 'Kinetic',
        location: 'vault',
        power: 1810,
        isMasterwork: true,
        plugHashes: const [kEnhancedPlugHash, kBasePlugHash],
        socketPlugs: const [
          {
            'columnKind': 'trait',
            'columnLabel': 'Trait',
            'equippedPlugHash': kEnhancedPlugHash,
            'reusablePlugHashes': [kEnhancedPlugHash, kBasePlugHash],
          },
        ],
        syncedAt: now.toIso8601String(),
      ),
    ],
  );

  final bridge = OwnedCatalogBridge(
    db: db,
    offlineCatalog: services.offlineCatalog,
    session: services.oauthSession,
    inventorySync: services.inventorySync,
    plugNameByHash: _plugNames,
    plugEnhancedByHash: const {kEnhancedPlugHash: true},
    plugNameMapBuilder: (hashes) async => {
      for (final h in hashes)
        if (_plugNames.containsKey(h)) h: _plugNames[h]!,
    },
    plugEnhancedMapBuilder: (hashes) async => {
      for (final h in hashes)
        if (h == kEnhancedPlugHash) h: true,
    },
  );

  runApp(
    MaterialApp(
      title: 'Residual polish capture',
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
// Fixture seeds (keep in sync with test/catalog_residual_polish_fixtures.dart)
// ---------------------------------------------------------------------------

const int kEnhancedWeaponHash = 91001;
const int kCatalystExoticHash = 91002;
const int kEnhanceNoteWeaponHash = 91003;
const int kEnhancedPlugHash = 801;
const int kBasePlugHash = 802;
const int kPoolEnhancedPlugHash = 803;
const int kPoolBasePlugHash = 804;

const Map<int, String> _plugNames = {
  kEnhancedPlugHash: 'Enhanced Frenzy',
  kBasePlugHash: 'Overflow',
  kPoolEnhancedPlugHash: 'Enhanced Kill Clip',
  kPoolBasePlugHash: 'Rapid Hit',
};

const List<CatalogItem> _catalogItems = [
  CatalogItem(
    hash: kEnhancedWeaponHash,
    name: 'Residual Enhanced HC',
    slot: 'Kinetic',
    element: 'Kinetic',
    ammo: 'Primary',
    itemTypeName: 'Hand Cannon',
    frame: 'Adaptive Frame',
    isExotic: false,
  ),
  CatalogItem(
    hash: kCatalystExoticHash,
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
  CatalogItem(
    hash: kEnhanceNoteWeaponHash,
    name: 'Residual Enhance-Note Scout',
    slot: 'Energy',
    element: 'Solar',
    ammo: 'Primary',
    itemTypeName: 'Scout Rifle',
    frame: 'Precision Frame',
    isExotic: false,
  ),
];

final Map<int, List<WeaponPerkColumn>> _perkColumns = {
  kEnhancedWeaponHash: const [
    WeaponPerkColumn(
      column: 2,
      curated: [kEnhancedPlugHash, kBasePlugHash],
      randomized: [
        kEnhancedPlugHash,
        kBasePlugHash,
        kPoolBasePlugHash,
        kPoolEnhancedPlugHash,
      ],
    ),
  ],
  kEnhanceNoteWeaponHash: const [
    WeaponPerkColumn(
      column: 2,
      curated: [kPoolBasePlugHash],
      randomized: [kPoolBasePlugHash, kPoolEnhancedPlugHash],
    ),
  ],
};

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
          membershipId: 'destiny-residual',
          displayName: 'Residual Capture',
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
