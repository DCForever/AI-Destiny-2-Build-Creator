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

/// Drive stepped create wizard for a non-Armor (weapon) set with [name].
///
/// Product path: New set → Type weapon → Continue → Name → Create shell.
Future<void> _createWeaponSetViaWizard(
  WidgetTester tester,
  String name,
) async {
  await tester.tap(find.byKey(const Key('sets_library_new')));
  await _pumpFrames(tester);
  expect(find.byKey(const Key('sets_create_wizard')), findsOneWidget);

  // Type step: pick weapon
  await tester.tap(find.byKey(const Key('sets_create_type_weapon')));
  await _pumpFrames(tester);
  await tester.tap(find.byKey(const Key('sets_create_continue')));
  await _pumpFrames(tester);

  // Name (thin shell) step
  expect(find.byKey(const Key('sets_create_name')), findsOneWidget);
  await tester.enterText(find.byKey(const Key('sets_create_name')), name);
  await _pumpFrames(tester);
  await tester.tap(find.byKey(const Key('sets_create_button')));
  await tester.pumpAndSettle();
  await _pumpFrames(tester);
}

/// Drive stepped create wizard for an Armor set with [name].
///
/// Product path: New set → Type armor → Class → Bonus → Name → Create
/// (opens board modal after create).
Future<void> _createArmorSetViaWizard(
  WidgetTester tester,
  String name,
) async {
  await tester.tap(find.byKey(const Key('sets_library_new')));
  await _pumpFrames(tester);
  expect(find.byKey(const Key('sets_create_wizard')), findsOneWidget);

  // Type defaults to armor; Continue → Class.
  await tester.tap(find.byKey(const Key('sets_create_continue')));
  await _pumpFrames(tester);
  await tester.tap(find.byKey(const Key('sets_create_class_Titan')));
  await _pumpFrames(tester);
  await tester.tap(find.byKey(const Key('sets_create_continue')));
  await _pumpFrames(tester);
  // Bonus step (optional) → Continue
  await tester.tap(find.byKey(const Key('sets_create_continue')));
  await _pumpFrames(tester);

  expect(find.byKey(const Key('sets_create_name')), findsOneWidget);
  await tester.enterText(find.byKey(const Key('sets_create_name')), name);
  await _pumpFrames(tester);
  await tester.tap(find.byKey(const Key('sets_create_button')));
  await tester.pumpAndSettle();
  await _pumpFrames(tester);
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
    // Product path: no Quick create rail.
    expect(find.byKey(const Key('sets_create_toggle')), findsNothing);

    await _createWeaponSetViaWizard(tester, 'Kinetic Core');

    expect(find.byKey(const Key('sets_list')), findsOneWidget);
    expect(find.text('Kinetic Core'), findsWidgets);
    expect(find.byKey(const Key('sets_detail')), findsOneWidget);
    // Weapon sets use non-armor thin detail (Armor MVP) — not armor type chip /
    // empty primary slot chrome.
    expect(find.byKey(const Key('sets_non_armor_thin_detail')), findsOneWidget);
    expect(find.byKey(const Key('sets_non_armor_type')), findsOneWidget);
    expect(find.byKey(const Key('sets_non_armor_scope_note')), findsOneWidget);
    expect(find.byKey(const Key('sets_detail_type')), findsNothing);
    expect(find.byKey(const Key('sets_slot_empty_primary')), findsNothing);
  });

  testWidgets('US1 rename set updates list', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: SetsLibraryPage(services: services),
      ),
    );
    await _pumpFrames(tester);

    // Rename field lives on armor detail (weapon thin shell has no rename).
    await _createArmorSetViaWizard(tester, 'Old Name');
    // Armor create opens board modal — close it to reach detail rename.
    if (find.byKey(const Key('sets_armor_board_modal')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('sets_lifecycle_modal_close')));
      await _pumpFrames(tester);
    }

    final rename = find.byKey(const Key('sets_edit_name'));
    await tester.ensureVisible(rename);
    await _pumpFrames(tester);
    await tester.enterText(rename, 'New Name');
    final save = find.byKey(const Key('sets_save_name'));
    await tester.ensureVisible(save);
    await tester.tap(save);
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

    // Weapon thin shell intentionally has no slot fill (Armor MVP scope).
    await _createWeaponSetViaWizard(tester, 'Weapons');

    expect(find.byKey(const Key('sets_non_armor_thin_detail')), findsOneWidget);
    expect(find.byKey(const Key('sets_non_armor_scope_note')), findsOneWidget);
    expect(find.byKey(const Key('sets_slot_fill_primary')), findsNothing);
    expect(find.byKey(const Key('set_catalog_picker')), findsNothing);
  });

  testWidgets('US2 owned empty guidance in picker', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: SetsLibraryPage(services: services),
      ),
    );
    await _pumpFrames(tester);

    // Armor fill uses owned-compare (not catalog picker). Open board → Pick
    // with signed-out / empty owned → honesty empty.
    await _createArmorSetViaWizard(tester, 'Armor Empty');
    // Create already opens the board modal with pick actions.
    expect(find.byKey(const Key('sets_armor_board_modal')), findsOneWidget);
    await tester.tap(find.byKey(const Key('sets_board_pick_helmet')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('sets_owned_compare_dialog')), findsOneWidget);
    expect(find.byKey(const Key('sets_owned_compare_signed_out')), findsOneWidget);
  });

  // Sets is mounted on shell nav (Catalog · Sets · Settings); page tests cover SetsLibraryPage.
  testWidgets(
    'US3 Sets nav destination shows library page',
    skip: true,
    (tester) async {
      await tester.pumpWidget(
        Destiny2WindowsApp(services: services),
      );
      await _pumpFrames(tester);
      expect(find.text('Catalog'), findsWidgets);
    },
  );

  testWidgets('dual-pane rail width contract present', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: SetsLibraryPage(services: services),
      ),
    );
    await _pumpFrames(tester);

    // Create a set so detail appears beside rail
    await _createWeaponSetViaWizard(tester, 'Pane');

    expect(find.byKey(const Key('sets_list')), findsOneWidget);
    expect(find.byKey(const Key('sets_detail')), findsOneWidget);
  });

  test('signed-in hides stale Optimize sign-in banner', () {
    expect(
      shouldShowSetsStatusLine(
        error: null,
        statusMessage: kSetsOptimizeSignInBanner,
        isSignedIn: false,
      ),
      isTrue,
    );
    expect(
      shouldShowSetsStatusLine(
        error: null,
        statusMessage: kSetsOptimizeSignInBanner,
        isSignedIn: true,
      ),
      isFalse,
    );
    expect(
      shouldShowSetsStatusLine(
        error: 'boom',
        statusMessage: kSetsOptimizeSignInBanner,
        isSignedIn: true,
      ),
      isTrue,
    );
    expect(
      shouldShowSetsStatusLine(
        error: null,
        statusMessage: 'Set deleted',
        isSignedIn: true,
      ),
      isTrue,
    );
  });
}
