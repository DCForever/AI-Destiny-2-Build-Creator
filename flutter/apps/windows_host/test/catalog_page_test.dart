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

  Future<void> expandFilters(WidgetTester tester) async {
    final toggle = find.byKey(const Key('catalog_filters_toggle'));
    if (toggle.evaluate().isNotEmpty) {
      // Open if closed: subtitle is only shown when collapsed.
      final tile = tester.widget<ListTile>(toggle);
      if (tile.subtitle != null) {
        await tester.tap(toggle);
        await _pumpFrames(tester);
      }
    }
  }

  Future<void> expandMoreFilters(WidgetTester tester) async {
    await expandFilters(tester);
    final more = find.byKey(const Key('catalog_more_filters_toggle'));
    if (more.evaluate().isNotEmpty) {
      await tester.ensureVisible(more);
      await tester.tap(more);
      await _pumpFrames(tester);
    }
  }

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
    expect(find.byKey(const Key('mode_chip_weapons')), findsOneWidget);
    expect(find.byKey(const Key('mode_chip_universal')), findsOneWidget);
    expect(find.byKey(const Key('catalog_filters_toggle')), findsOneWidget);
    expect(find.byKey(const Key('catalog_board_header')), findsOneWidget);
  });

  testWidgets('element include chip narrows list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(services: services)),
    );
    await _pumpFrames(tester);
    await expandFilters(tester);

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
    // Primary facets (slot) open with Filters; archetype/group behind More.
    await expandFilters(tester);

    // Slot Energy include
    await tester.ensureVisible(find.byKey(const Key('slot_chip_Energy')));
    await tester.tap(find.byKey(const Key('slot_chip_Energy')));
    await _pumpFrames(tester);
    expect(itemKey(1), findsOneWidget);
    expect(itemKey(3), findsOneWidget);
    expect(itemKey(2), findsNothing);

    await expandMoreFilters(tester);

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

    // Arc Logic (3), Dragon's Breath (2), Edge Transit (1) — flap board order
    final y3 = tester.getTopLeft(itemKey(3)).dy;
    final y2 = tester.getTopLeft(itemKey(2)).dy;
    final y1 = tester.getTopLeft(itemKey(1)).dy;
    expect(y3 < y2, isTrue);
    expect(y2 < y1, isTrue);
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

  testWidgets('Weapons|Armor|Universal modes filter by kind (DART-063)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final mixedRoot = StorageRoot(basePath: tempDir.path);
    final mixedServices = AppServices(
      storageRoot: mixedRoot,
      db: services.db,
      manifestRefresh: _FakeRefresh(),
      offlineCatalog: OfflineCatalog.preloaded(
        storageRoot: mixedRoot,
        items: const [
          CatalogItem(
            hash: 10,
            name: 'Hand Cannon',
            slot: 'Kinetic',
            ammo: 'Primary',
            isExotic: false,
            sourceStore: 'weapons',
          ),
          CatalogItem(
            hash: 20,
            name: 'Exotic Chest',
            slot: 'Chest',
            classType: 'Titan',
            isExotic: true,
            sourceStore: 'exotic-armor',
          ),
          CatalogItem(
            hash: 30,
            name: 'Aspect Piece',
            itemTypeName: 'Aspect',
            isExotic: false,
            sourceStore: 'aspects',
          ),
        ],
        version: 'modes-1',
      ),
      oauthSession: services.oauthSession,
      profileClient: services.profileClient,
      inventorySync: services.inventorySync,
      writeClient: services.writeClient,
    );

    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(services: mixedServices)),
    );
    await _pumpFrames(tester);

    // Default weapons
    expect(itemKey(10), findsOneWidget);
    expect(itemKey(20), findsNothing);
    expect(itemKey(30), findsNothing);

    await tester.tap(find.byKey(const Key('mode_chip_armor')));
    await _pumpFrames(tester);
    expect(itemKey(20), findsOneWidget);
    expect(itemKey(10), findsNothing);

    await tester.tap(find.byKey(const Key('mode_chip_universal')));
    await _pumpFrames(tester);
    expect(itemKey(10), findsOneWidget);
    expect(itemKey(20), findsOneWidget);
    expect(itemKey(30), findsOneWidget);

    // Select weapon → Universal Set/Synergy CTAs, no Build attach
    await tester.tap(itemKey(10));
    await _pumpFrames(tester);
    expect(
      find.byKey(const Key('universal_actions'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('universal_create_set'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('universal_create_synergy'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('no_build_kit_attach'), skipOffstage: false),
      findsOneWidget,
    );
    expect(find.textContaining('Build kit'), findsNothing);
  });
}
