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
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppServices services;
  late AppDatabase db;

  final fixtureItems = <CatalogItem>[
    const CatalogItem(
      hash: 100,
      name: 'Owned Kinetic',
      slot: 'Kinetic',
      element: 'Kinetic',
      ammo: 'Primary',
      itemTypeName: 'Hand Cannon',
      isExotic: false,
    ),
    const CatalogItem(
      hash: 200,
      name: 'Owned Energy',
      slot: 'Energy',
      element: 'Solar',
      ammo: 'Special',
      itemTypeName: 'Fusion Rifle',
      isExotic: false,
    ),
    const CatalogItem(
      hash: 300,
      name: 'Unowned Exotic',
      slot: 'Power',
      element: 'Arc',
      ammo: 'Heavy',
      itemTypeName: 'Rocket Launcher',
      isExotic: true,
    ),
  ];

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dart026_catalog_owned_');
    final root = StorageRoot(basePath: tempDir.path);
    await root.ensureLayout();
    db = AppDatabase.memory();
    final tokenStore = MemoryTokenStore();
    await seedSignedIn(tokenStore, membershipId: 'bungie-net-26');

    services = await HostBootstrap.open(
      storageRoot: root,
      database: db,
      manifestRefresh: _FakeRefresh(),
      offlineCatalog: OfflineCatalog.preloaded(
        storageRoot: root,
        items: fixtureItems,
        version: 'fixture-owned-1',
      ),
      clientId: 'test-client',
      tokenStore: tokenStore,
      browserLauncher: FakeBrowserLauncher(),
      profileClient: FakeProfileClient(),
      oauthClient: BungieOAuthClient(
        clientId: 'test-client',
        redirectUri: kDefaultWindowsRedirectUri,
        transport: (_) async => throw StateError('unused'),
      ),
    );

    // Seed local user + inventory (post-sync shape).
    final user = await ensureUser(
      db,
      bungieMembershipId: 'bungie-net-26',
      membershipType: 3,
      displayName: 'Guardian',
    );
    await replaceInventoryBatch(
      db,
      user.id,
      now: '2026-07-24T12:00:00.000Z',
      items: [
        const InventoryItemRecord(
          instanceId: 'inst-hi',
          itemHash: 100,
          bucket: 'Kinetic',
          location: 'vault',
          power: 1810,
          isMasterwork: true,
          plugHashes: [9, 8],
          syncedAt: '2026-07-24T12:00:00.000Z',
        ),
        const InventoryItemRecord(
          instanceId: 'inst-lo',
          itemHash: 100,
          bucket: 'Kinetic',
          location: 'character',
          characterId: 'char1',
          power: 1790,
          syncedAt: '2026-07-24T12:00:00.000Z',
        ),
        const InventoryItemRecord(
          instanceId: 'inst-energy',
          itemHash: 200,
          bucket: 'Energy',
          location: 'equipped',
          characterId: 'char1',
          power: 1800,
          syncedAt: '2026-07-24T12:00:00.000Z',
        ),
      ],
    );
  });

  tearDown(() async {
    await services.dispose();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('All scope shows owned and unowned; owned badge on copies',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(services: services)),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('catalog_list')), findsOneWidget);
    expect(
      find.byKey(const Key('catalog_item_100'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('catalog_item_200'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('catalog_item_300'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('owned_badge_100'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('owned_badge_300'), skipOffstage: false),
      findsNothing,
    );
  });

  testWidgets('Owned scope filters to synced inventory hashes only',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(services: services)),
    );
    await _pumpFrames(tester);

    await tester.tap(find.byKey(const Key('scope_chip_owned')));
    await _pumpFrames(tester);

    expect(
      find.byKey(const Key('catalog_item_100'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('catalog_item_200'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('catalog_item_300'), skipOffstage: false),
      findsNothing,
    );
    final status = tester.widget<Text>(find.byKey(const Key('catalog_status')));
    expect(status.data, contains('OWNED'));
  });

  testWidgets('select owned row shows instance projections power-desc',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(services: services)),
    );
    await _pumpFrames(tester);

    final itemFinder =
        find.byKey(const Key('catalog_item_100'), skipOffstage: false);
    expect(itemFinder, findsOneWidget);
    // Catalog list is the primary vertical scrollable (filters use horizontal).
    final listScrollable = find.descendant(
      of: find.byKey(const Key('catalog_list')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      itemFinder,
      64,
      scrollable: listScrollable,
    );
    await _pumpFrames(tester);
    await tester.tap(itemFinder);
    await _pumpFrames(tester);

    expect(find.byKey(const Key('instance_panel_title')), findsOneWidget);
    expect(find.byKey(const Key('instance_list')), findsOneWidget);
    expect(find.byKey(const Key('instance_inst-hi')), findsOneWidget);
    expect(find.byKey(const Key('instance_inst-lo')), findsOneWidget);

    // Power-desc: higher power tile appears first in list.
    final hi = tester.getTopLeft(find.byKey(const Key('instance_inst-hi')));
    final lo = tester.getTopLeft(find.byKey(const Key('instance_inst-lo')));
    expect(hi.dy, lessThan(lo.dy));
  });

  testWidgets('Owned empty when inventory cleared', (tester) async {
    final user = await getUserByMembership(
      db,
      bungieMembershipId: 'bungie-net-26',
    );
    await replaceInventoryBatch(
      db,
      user!.id,
      now: '2026-07-24T13:00:00.000Z',
      items: const [],
    );

    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(services: services)),
    );
    await _pumpFrames(tester);

    await tester.tap(find.byKey(const Key('scope_chip_owned')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('catalog_empty')), findsOneWidget);
    expect(find.textContaining('Sync inventory'), findsOneWidget);
  });
}
