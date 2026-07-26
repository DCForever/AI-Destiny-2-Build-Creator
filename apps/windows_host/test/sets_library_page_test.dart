import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/app.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
import 'package:destiny2_windows_host/sets/sets_library_page.dart';
import 'package:destiny2_windows_host/theme/flap_theme.dart';
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

/// Expand collapsible create form (BUG-20260726-008).
Future<void> _expandSetsCreate(WidgetTester tester) async {
  if (find.byKey(const Key('sets_create_button')).evaluate().isEmpty) {
    await tester.tap(find.byKey(const Key('sets_create_toggle')));
    await _pumpFrames(tester);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppServices services;
  late AppDatabase db;

  final fixtureItems = <CatalogItem>[
    const CatalogItem(
      hash: 1001,
      name: 'Test Kinetic HC',
      slot: 'Kinetic',
      element: 'Kinetic',
      ammo: 'Primary',
      itemTypeName: 'Hand Cannon',
      isExotic: false,
    ),
    const CatalogItem(
      hash: 1002,
      name: 'Test Energy Fusion',
      slot: 'Energy',
      element: 'Solar',
      ammo: 'Special',
      itemTypeName: 'Fusion Rifle',
      isExotic: false,
    ),
    const CatalogItem(
      hash: 1003,
      name: 'Test Heavy RL',
      slot: 'Power',
      element: 'Arc',
      ammo: 'Heavy',
      itemTypeName: 'Rocket Launcher',
      isExotic: true,
    ),
  ];

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dart030_sets_');
    final root = StorageRoot(basePath: tempDir.path);
    await root.ensureLayout();
    db = AppDatabase.memory();
    final tokenStore = MemoryTokenStore();

    services = await HostBootstrap.open(
      storageRoot: root,
      database: db,
      manifestRefresh: _FakeRefresh(),
      offlineCatalog: OfflineCatalog.preloaded(
        storageRoot: root,
        items: fixtureItems,
        version: 'fixture-sets-1',
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
  });

  tearDown(() async {
    await services.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('US1 create set appears in list and detail', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: SetsLibraryPage(
          key: const Key('sets_library_page'),
          services: services,
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('sets_list_empty')), findsOneWidget);

    await _expandSetsCreate(tester);
    await tester.enterText(find.byKey(const Key('sets_create_name')), 'Kinetic Core');
    await tester.tap(find.byKey(const Key('sets_create_button')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('sets_list')), findsOneWidget);
    expect(find.text('Kinetic Core'), findsWidgets);
    expect(find.byKey(const Key('sets_detail')), findsOneWidget);
    expect(find.byKey(const Key('sets_detail_type')), findsOneWidget);
    expect(find.byKey(const Key('sets_slot_empty_primary')), findsOneWidget);
  });

  testWidgets('US1 rename set updates list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: SetsLibraryPage(services: services),
      ),
    );
    await _pumpFrames(tester);

    await _expandSetsCreate(tester);
    await tester.enterText(find.byKey(const Key('sets_create_name')), 'Old Name');
    await tester.tap(find.byKey(const Key('sets_create_button')));
    await _pumpFrames(tester);

    await tester.enterText(find.byKey(const Key('sets_edit_name')), 'New Name');
    await tester.tap(find.byKey(const Key('sets_save_name')));
    await _pumpFrames(tester);

    expect(find.text('New Name'), findsWidgets);
    expect(find.byKey(const Key('sets_status')), findsOneWidget);
  });

  testWidgets('US2 fill primary from catalog picker', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: SetsLibraryPage(services: services),
      ),
    );
    await _pumpFrames(tester);

    await _expandSetsCreate(tester);
    await tester.enterText(find.byKey(const Key('sets_create_name')), 'Weapons');
    await tester.tap(find.byKey(const Key('sets_create_button')));
    await _pumpFrames(tester);

    await tester.tap(find.byKey(const Key('sets_slot_fill_primary')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('set_catalog_picker')), findsOneWidget);
    expect(find.byKey(const Key('set_picker_item_1001')), findsOneWidget);

    await tester.tap(find.byKey(const Key('set_picker_item_1001')));
    await _pumpFrames(tester);

    // Wishlist path (no owned instances): definition-only confirm.
    final confirm = find.byKey(const Key('set_picker_confirm_wishlist'));
    expect(confirm, findsOneWidget);
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('set_catalog_picker')), findsNothing);
    expect(find.byKey(const Key('sets_slot_filled_primary')), findsOneWidget);
    expect(find.textContaining('Test Kinetic HC'), findsWidgets);
  });

  testWidgets('US2 owned empty guidance in picker', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: SetsLibraryPage(services: services),
      ),
    );
    await _pumpFrames(tester);

    await _expandSetsCreate(tester);
    await tester.enterText(find.byKey(const Key('sets_create_name')), 'W');
    await tester.tap(find.byKey(const Key('sets_create_button')));
    await _pumpFrames(tester);

    await tester.tap(find.byKey(const Key('sets_slot_fill_primary')));
    await _pumpFrames(tester);

    await tester.tap(find.byKey(const Key('set_picker_scope_owned')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('set_picker_empty')), findsOneWidget);
  });

  testWidgets('US3 Sets nav destination shows library page', (tester) async {
    await tester.pumpWidget(
      Destiny2WindowsApp(services: services),
    );
    await _pumpFrames(tester);

    // Shell default is Loadouts (DART-068); Sets is index 3.
    expect(
      find.byKey(const Key('loadouts_page'), skipOffstage: false),
      findsOneWidget,
    );

    final rail = find.byKey(const Key('host_nav_rail'));
    expect(rail, findsOneWidget);

    await tester.tap(find.text('Sets'));
    await _pumpFrames(tester);

    expect(
      find.byKey(const Key('sets_library_page'), skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byKey(const Key('sets_create_toggle')), findsOneWidget);
  });

  testWidgets('dual-pane rail width contract present', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: SetsLibraryPage(services: services),
      ),
    );
    await _pumpFrames(tester);

    // Create a set so detail appears beside rail
    await _expandSetsCreate(tester);
    await tester.enterText(find.byKey(const Key('sets_create_name')), 'Pane');
    await tester.tap(find.byKey(const Key('sets_create_button')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('sets_list')), findsOneWidget);
    expect(find.byKey(const Key('sets_detail')), findsOneWidget);
  });
}
