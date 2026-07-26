import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/catalog/catalog_page.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
import 'package:flutter/material.dart';
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

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppServices services;

  final fixtureItems = <CatalogItem>[
    const CatalogItem(
      hash: 1,
      name: 'Edge Transit',
      slot: 'Energy',
      element: 'Void',
      ammo: 'Special',
      itemTypeName: 'Grenade Launcher',
      isExotic: false,
    ),
    const CatalogItem(
      hash: 2,
      name: "Dragon's Breath",
      slot: 'Power',
      element: 'Solar',
      ammo: 'Heavy',
      itemTypeName: 'Rocket Launcher',
      isExotic: true,
    ),
    const CatalogItem(
      hash: 3,
      name: 'Arc Logic',
      slot: 'Energy',
      element: 'Arc',
      ammo: 'Primary',
      itemTypeName: 'Auto Rifle',
      isExotic: false,
    ),
  ];

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dart020_catalog_ui_');
    final root = StorageRoot(basePath: tempDir.path);
    await root.ensureLayout();
    services = await HostBootstrap.open(
      storageRoot: root,
      database: AppDatabase.memory(),
      manifestRefresh: _FakeRefresh(),
      offlineCatalog: OfflineCatalog.preloaded(
        storageRoot: root,
        items: fixtureItems,
        version: 'fixture-1',
      ),
      clientId: 'test-client',
      tokenStore: MemoryTokenStore(),
      browserLauncher: FakeBrowserLauncher(),
      profileClient: FakeProfileClient(),
      oauthClient: BungieOAuthClient(
        clientId: 'test-client',
        redirectUri: kDefaultWindowsRedirectUri,
        transport: (_) async => throw StateError('unused'),
      ),
    );
  });

  tearDown(() async {
    await services.dispose();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Finder itemKey(int hash) =>
      find.byKey(Key('catalog_item_$hash'), skipOffstage: false);

  testWidgets('shows fixture item names offline', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(services: services)),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('catalog_list')), findsOneWidget);
    expect(itemKey(1), findsOneWidget); // Edge Transit
    expect(itemKey(2), findsOneWidget); // Dragon's Breath
    expect(itemKey(3), findsOneWidget); // Arc Logic
    expect(find.byKey(const Key('catalog_status')), findsOneWidget);
  });

  testWidgets('element include chip narrows list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(services: services)),
    );
    await _pumpFrames(tester);

    await tester.ensureVisible(find.byKey(const Key('element_chip_Solar')));
    await tester.tap(find.byKey(const Key('element_chip_Solar')));
    await _pumpFrames(tester);

    expect(itemKey(2), findsOneWidget);
    expect(itemKey(1), findsNothing);
    expect(itemKey(3), findsNothing);
  });

  testWidgets('slot archetype chips and group-by (DART-062)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(services: services)),
    );
    await _pumpFrames(tester);

    // Slot Energy include
    await tester.ensureVisible(find.byKey(const Key('slot_chip_Energy')));
    await tester.tap(find.byKey(const Key('slot_chip_Energy')));
    await _pumpFrames(tester);
    expect(itemKey(1), findsOneWidget);
    expect(itemKey(3), findsOneWidget);
    expect(itemKey(2), findsNothing);

    // Archetype Auto Rifle include further narrows
    await tester.ensureVisible(
      find.byKey(const Key('archetype_chip_Auto Rifle')),
    );
    await tester.tap(find.byKey(const Key('archetype_chip_Auto Rifle')));
    await _pumpFrames(tester);
    expect(itemKey(3), findsOneWidget);
    expect(itemKey(1), findsNothing);

    // Clear archetype by cycling off (include → exclude → off): two more taps
    await tester.tap(find.byKey(const Key('archetype_chip_Auto Rifle')));
    await _pumpFrames(tester);
    await tester.tap(find.byKey(const Key('archetype_chip_Auto Rifle')));
    await _pumpFrames(tester);

    // Group by element shows header
    await tester.ensureVisible(find.byKey(const Key('group_chip_element')));
    await tester.tap(find.byKey(const Key('group_chip_element')));
    await _pumpFrames(tester);
    expect(
      find.byKey(const Key('catalog_group_Arc'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('catalog_group_Void'), skipOffstage: false),
      findsOneWidget,
    );
    // Filter membership unchanged (2 Energy weapons)
    expect(itemKey(1), findsOneWidget);
    expect(itemKey(3), findsOneWidget);
  });

  testWidgets('results are alpha-sorted by display name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(services: services)),
    );
    await _pumpFrames(tester);

    final tiles = tester
        .widgetList<ListTile>(
          find.byWidgetPredicate(
            (w) =>
                w is ListTile &&
                w.key is Key &&
                (w.key as Key).toString().contains('catalog_item_'),
            skipOffstage: false,
          ),
        )
        .toList();
    final names = tiles
        .map((t) => t.title)
        .whereType<Text>()
        .map((t) => t.data)
        .whereType<String>()
        .toList();
    expect(names, ['Arc Logic', "Dragon's Breath", 'Edge Transit']);
  });

  testWidgets('free-text filters by name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(services: services)),
    );
    await _pumpFrames(tester);

    await tester.enterText(find.byKey(const Key('catalog_query')), 'arc');
    await _pumpFrames(tester);

    expect(itemKey(3), findsOneWidget);
    expect(itemKey(1), findsNothing);
  });

  testWidgets('empty entity cache shows empty state', (tester) async {
    // Preloaded empty avoids extra dart:io timing flakiness; disk noVersion
    // path is covered by packages/manifest offline_catalog_test.
    final emptyServices = AppServices(
      storageRoot: services.storageRoot,
      db: services.db,
      manifestRefresh: _FakeRefresh(),
      offlineCatalog: OfflineCatalog.preloaded(
        storageRoot: services.storageRoot,
        items: const [],
      ),
      oauthSession: services.oauthSession,
      profileClient: services.profileClient,
      inventorySync: services.inventorySync,
      writeClient: services.writeClient,
    );

    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(services: emptyServices)),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('catalog_empty')), findsOneWidget);
    expect(find.textContaining('entity cache'), findsOneWidget);
    // Do not dispose emptyServices — shares services.db closed in tearDown.
  });

  testWidgets('owned scope with empty entity cache blames entities not only sync',
      (tester) async {
    final emptyServices = AppServices(
      storageRoot: services.storageRoot,
      db: services.db,
      manifestRefresh: _FakeRefresh(),
      offlineCatalog: OfflineCatalog.preloaded(
        storageRoot: services.storageRoot,
        items: const [],
      ),
      oauthSession: services.oauthSession,
      profileClient: services.profileClient,
      inventorySync: services.inventorySync,
      writeClient: services.writeClient,
    );

    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(services: emptyServices)),
    );
    await _pumpFrames(tester);

    await tester.tap(find.byKey(const Key('scope_chip_owned')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('catalog_empty')), findsOneWidget);
    expect(
      find.textContaining('not solely an inventory sync problem'),
      findsOneWidget,
    );
    expect(find.textContaining('Entity cache'), findsOneWidget);
  });

  testWidgets('reloadToken reloads when OfflineCatalog gains items',
      (tester) async {
    // BUG-20260725-001: after Settings sync, shell bumps reloadToken so Catalog
    // re-reads OfflineCatalog (IndexedStack keeps the page state alive).
    final emptyServices = AppServices(
      storageRoot: services.storageRoot,
      db: services.db,
      manifestRefresh: _FakeRefresh(),
      offlineCatalog: OfflineCatalog.preloaded(
        storageRoot: services.storageRoot,
        items: const [],
      ),
      oauthSession: services.oauthSession,
      profileClient: services.profileClient,
      inventorySync: services.inventorySync,
      writeClient: services.writeClient,
    );
    final fullServices = AppServices(
      storageRoot: services.storageRoot,
      db: services.db,
      manifestRefresh: _FakeRefresh(),
      offlineCatalog: OfflineCatalog.preloaded(
        storageRoot: services.storageRoot,
        items: const [
          CatalogItem(
            hash: 42,
            name: 'Reload Rifle',
            slot: 'Kinetic',
            element: 'Kinetic',
            ammo: 'Primary',
            itemTypeName: 'Auto Rifle',
            isExotic: false,
          ),
        ],
        version: 'reload-v1',
      ),
      oauthSession: services.oauthSession,
      profileClient: services.profileClient,
      inventorySync: services.inventorySync,
      writeClient: services.writeClient,
    );

    var active = emptyServices;
    var reloadToken = 0;
    late StateSetter setParent;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setParent = setState;
            return CatalogPage(
              services: active,
              reloadToken: reloadToken,
            );
          },
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('catalog_empty')), findsOneWidget);

    active = fullServices;
    reloadToken = 1;
    setParent(() {});
    await _pumpFrames(tester);

    expect(find.text('Reload Rifle'), findsOneWidget);
    expect(find.byKey(const Key('catalog_list')), findsOneWidget);
  });
}
