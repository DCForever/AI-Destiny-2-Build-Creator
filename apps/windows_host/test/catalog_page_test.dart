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

  testWidgets('shows fixture item names offline', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(services: services)),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('catalog_list')), findsOneWidget);
    expect(find.text('Edge Transit'), findsOneWidget);
    expect(find.text("Dragon's Breath"), findsOneWidget);
    expect(find.text('Arc Logic'), findsOneWidget);
    expect(find.byKey(const Key('catalog_status')), findsOneWidget);
  });

  testWidgets('element include chip narrows list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(services: services)),
    );
    await _pumpFrames(tester);

    await tester.tap(find.byKey(const Key('element_chip_Solar')));
    await _pumpFrames(tester);

    expect(find.text("Dragon's Breath"), findsOneWidget);
    expect(find.text('Edge Transit'), findsNothing);
    expect(find.text('Arc Logic'), findsNothing);
  });

  testWidgets('free-text filters by name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(services: services)),
    );
    await _pumpFrames(tester);

    await tester.enterText(find.byKey(const Key('catalog_query')), 'arc');
    await _pumpFrames(tester);

    expect(find.text('Arc Logic'), findsOneWidget);
    expect(find.text('Edge Transit'), findsNothing);
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
    );

    await tester.pumpWidget(
      MaterialApp(home: CatalogPage(services: emptyServices)),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('catalog_empty')), findsOneWidget);
    expect(find.textContaining('entity cache'), findsOneWidget);
    // Do not dispose emptyServices — shares services.db closed in tearDown.
  });
}
