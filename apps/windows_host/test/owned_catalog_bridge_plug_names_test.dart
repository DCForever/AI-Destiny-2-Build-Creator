import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/auth/windows_oauth_session.dart';
import 'package:destiny2_windows_host/catalog/owned_catalog_bridge.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
import 'package:destiny2_windows_host/settings/inventory_sync_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'inventory_sync_test_fakes.dart';

class _FakeRefresh implements ManifestRefreshApi {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppServices services;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('plug_names_');
    final root = StorageRoot(basePath: tempDir.path);
    await root.ensureLayout();
    db = AppDatabase.memory();
    services = await HostBootstrap.open(
      storageRoot: root,
      database: db,
      manifestRefresh: _FakeRefresh(),
      offlineCatalog: OfflineCatalog.preloaded(
        items: const [
          CatalogItem(
            hash: 50,
            name: 'Minor Spec',
            isExotic: false,
            itemTypeName: 'Mod',
          ),
        ],
        version: 'v1',
      ),
      tokenStore: MemoryTokenStore(),
      browserLauncher: FakeBrowserLauncher(),
      profileClient: FakeProfileClient(),
    );
  });

  tearDown(() async {
    await services.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('collectPlugHashesFromInventory gathers equipped + reusable', () {
    final hashes = collectPlugHashesFromInventory([
      InventoryItemRecord(
        instanceId: 'i1',
        itemHash: 1,
        bucket: 'Kinetic',
        location: 'vault',
        power: 1800,
        plugHashes: const [10],
        socketPlugs: [
          {
            'equippedPlugHash': 101,
            'reusablePlugHashes': [101, 102],
          },
        ],
        syncedAt: 't',
      ),
    ]);
    expect(hashes, containsAll([10, 101, 102]));
  });

  test('ensurePlugNames uses builder for missing hashes', () async {
    final session = WindowsOAuthSession(
      clientId: '',
      redirectUri: 'http://127.0.0.1:8765/callback',
      tokenStore: MemoryTokenStore(),
      oauthClient: BungieOAuthClient(
        clientId: 'x',
        redirectUri: 'http://127.0.0.1:8765/callback',
      ),
      browserLauncher: FakeBrowserLauncher(),
    );
    await session.restore();

    final sync = InventorySyncController(
      db: db,
      session: session,
      profileClient: FakeProfileClient(),
    );

    final bridge = OwnedCatalogBridge(
      db: db,
      offlineCatalog: services.offlineCatalog,
      session: session,
      inventorySync: sync,
      plugNameMapBuilder: (hashes) async => {
        for (final h in hashes) h: 'Name-$h',
      },
    );

    await bridge.refresh();
    // Seeded from catalog base.
    expect(bridge.plugNameByHash[50], 'Minor Spec');

    await bridge.ensurePlugNames([101, 102]);
    expect(bridge.plugNameByHash[101], 'Name-101');
    expect(bridge.plugNameByHash[102], 'Name-102');

    // Second call does not re-request known hashes.
    var builderCalls = 0;
    final bridge2 = OwnedCatalogBridge(
      db: db,
      offlineCatalog: services.offlineCatalog,
      session: session,
      inventorySync: sync,
      plugNameByHash: const {9: 'Known'},
      plugNameMapBuilder: (hashes) async {
        builderCalls++;
        return {for (final h in hashes) h: 'X-$h'};
      },
    );
    await bridge2.ensurePlugNames([9, 11]);
    expect(builderCalls, 1);
    expect(bridge2.plugNameByHash[9], 'Known');
    expect(bridge2.plugNameByHash[11], 'X-11');

    // Builder that completes with null must not red-screen Catalog.
    final bridge3 = OwnedCatalogBridge(
      db: db,
      offlineCatalog: services.offlineCatalog,
      session: session,
      inventorySync: sync,
      plugNameMapBuilder: (hashes) async {
        // Simulate misbehaving / failed raw-table path.
        return Future<Map<int, String>>.value(
          // ignore: unnecessary_cast — force runtime null through dynamic edge
          null as dynamic,
        );
      },
    );
    await bridge3.ensurePlugNames([999]);
    expect(bridge3.plugNameByHash.containsKey(999), isFalse);

    sync.dispose();
  });
}
