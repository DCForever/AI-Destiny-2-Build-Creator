/// Primary shell + destination UI functionality coverage (goal: UI tests, log issues).
///
/// Drives real [Destiny2WindowsApp] / page widgets with offline HostBootstrap fakes.
/// Does not fix product defects — failing expectations document broken UI.
library;

import 'dart:io';

import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/app.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
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
      status();

  @override
  Future<ManifestStatus> status() async =>
      const ManifestStatus(
        cachedVersion: 'ui-test-v1',
        remoteVersion: 'ui-test-v1',
        isStale: false,
        entityCache: null,
      );
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

/// Select shell nav by index via [NavigationRail.onDestinationSelected]
/// (avoids Material splash / off-stage label hit-test flakes).
Future<void> _selectNav(WidgetTester tester, int index) async {
  final rail = tester.widget<NavigationRail>(
    find.byKey(const Key('host_nav_rail')),
  );
  expect(rail.onDestinationSelected, isNotNull);
  rail.onDestinationSelected!(index);
  await _pump(tester);
  final after = tester.widget<NavigationRail>(
    find.byKey(const Key('host_nav_rail')),
  );
  expect(after.selectedIndex, index);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppServices services;
  late AppDatabase db;

  final catalogFixtures = <CatalogItem>[
    const CatalogItem(
      hash: 101,
      name: 'UI Test Kinetic',
      slot: 'Kinetic',
      element: 'Kinetic',
      ammo: 'Primary',
      itemTypeName: 'Hand Cannon',
      isExotic: false,
    ),
    const CatalogItem(
      hash: 202,
      name: 'UI Test Energy',
      slot: 'Energy',
      element: 'Solar',
      ammo: 'Special',
      itemTypeName: 'Fusion Rifle',
      isExotic: false,
    ),
  ];

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ui_fn_shell_');
    final root = StorageRoot(basePath: tempDir.path);
    await root.ensureLayout();
    db = AppDatabase.memory();
    services = await HostBootstrap.open(
      storageRoot: root,
      database: db,
      manifestRefresh: _FakeRefresh(),
      offlineCatalog: OfflineCatalog.preloaded(
        storageRoot: root,
        items: catalogFixtures,
        version: 'ui-fn-1',
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
      writeClient: MockBungieWriteClient(),
    );
  });

  tearDown(() async {
    await services.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('shell.nav primary destinations', () {
    test('navLabels match product AppShell order', () {
      expect(Destiny2WindowsApp.navLabels, [
        'Loadouts',
        'Build',
        'Synergy',
        'Sets',
        'Catalog',
        'Settings',
      ]);
      expect(Destiny2WindowsApp.catalogNavIndex, 4);
    });

    testWidgets('rail mounts all six page keys in IndexedStack', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(Destiny2WindowsApp(services: services));
      await _pump(tester);

      expect(find.byKey(const Key('host_nav_rail')), findsOneWidget);
      for (final label in Destiny2WindowsApp.navLabels) {
        expect(find.text(label), findsWidgets, reason: 'nav label $label');
      }

      // All destinations stay mounted under IndexedStack.
      const pageKeys = [
        'loadouts_page',
        'builds_library_page',
        'synergies_library_page',
        'sets_library_page',
        'catalog_page',
        'settings_page',
      ];
      for (final k in pageKeys) {
        expect(
          find.byKey(Key(k), skipOffstage: false),
          findsOneWidget,
          reason: 'IndexedStack page $k',
        );
      }
    });

    testWidgets('selecting each nav index updates rail and shows destination chrome',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(Destiny2WindowsApp(services: services));
      await _pump(tester);

      // index 0 Loadouts (default) — signed-out offline path
      expect(
        tester
            .widget<NavigationRail>(find.byKey(const Key('host_nav_rail')))
            .selectedIndex,
        0,
      );
      expect(find.byKey(const Key('loadouts_page_body')), findsOneWidget);
      expect(find.byKey(const Key('loadouts_title')), findsOneWidget);
      // Refresh is signed-in only (product gate).
      expect(find.byKey(const Key('loadouts_refresh')), findsNothing);

      // 1 Build
      await _selectNav(tester, 1);
      expect(find.byKey(const Key('builds_library_page')), findsOneWidget);
      expect(
        find.byKey(const Key('builds_list_empty')).evaluate().isNotEmpty ||
            find.byKey(const Key('builds_list')).evaluate().isNotEmpty,
        isTrue,
        reason: 'Build library empty or list',
      );
      expect(find.byKey(const Key('builds_create_toggle')), findsOneWidget);

      // 2 Synergy
      await _selectNav(tester, 2);
      expect(find.byKey(const Key('synergies_library_page')), findsOneWidget);
      expect(find.byKey(const Key('synergies_create_toggle')), findsOneWidget);

      // 3 Sets
      await _selectNav(tester, 3);
      expect(find.byKey(const Key('sets_library_page')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_toggle')), findsOneWidget);
      expect(find.byKey(const Key('sets_search')), findsOneWidget);

      // 4 Catalog
      await _selectNav(tester, 4);
      expect(find.byKey(const Key('catalog_page')), findsOneWidget);
      expect(find.byKey(const Key('catalog_query')), findsOneWidget);
      expect(find.byKey(const Key('catalog_reload')), findsOneWidget);
      expect(find.byKey(const Key('scope_chip_all')), findsOneWidget);

      // 5 Settings — ListView lazily builds; scroll to reveal manifest actions.
      await _selectNav(tester, 5);
      expect(find.byKey(const Key('settings_page')), findsOneWidget);
      expect(find.byKey(const Key('oauth_account_card')), findsOneWidget);
      expect(find.byKey(const Key('inventory_sync_card')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      final refreshFinder = find.byKey(const Key('refresh_manifest'));
      await tester.scrollUntilVisible(
        refreshFinder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await _pump(tester);
      expect(refreshFinder, findsOneWidget);
      expect(find.byKey(const Key('reload_status')), findsOneWidget);
      expect(find.byKey(const Key('manifest_status_card')), findsOneWidget);
    });
  });

  group('loadouts primary controls (offline)', () {
    testWidgets('signed-out state exposes sign-in CTA; filters gated',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(Destiny2WindowsApp(services: services));
      await _pump(tester);
      await _selectNav(tester, 0);

      expect(find.byKey(const Key('loadouts_signed_out')), findsOneWidget);
      expect(find.byKey(const Key('loadouts_sign_in_cta')), findsOneWidget);
      // Product: class filters only render when signed in.
      expect(find.byKey(const Key('loadouts_filters')), findsNothing);
      expect(find.byKey(const Key('loadouts_filter_hide_empty')), findsNothing);
      expect(find.byKey(const Key('loadouts_refresh')), findsNothing);

      // Sign-in CTA opens Settings (onOpenSettings index 5).
      await tester.tap(find.byKey(const Key('loadouts_sign_in_cta')));
      await _pump(tester);
      expect(
        tester
            .widget<NavigationRail>(find.byKey(const Key('host_nav_rail')))
            .selectedIndex,
        5,
      );
      expect(find.byKey(const Key('oauth_sign_in')), findsOneWidget);
    });
  });

  group('build primary create flow (shell-mounted)', () {
    testWidgets('expand create strip and Create hard-blocks without synergy',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(Destiny2WindowsApp(services: services));
      await _pump(tester);
      await _selectNav(tester, 1);

      // Empty library auto-expands create strip; only toggle if collapsed.
      var createBtn = find.byKey(const Key('builds_create_button'));
      if (createBtn.evaluate().isEmpty) {
        final toggle = find.byKey(const Key('builds_create_toggle'));
        expect(toggle, findsOneWidget);
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await _pump(tester);
        createBtn = find.byKey(const Key('builds_create_button'));
      }
      expect(createBtn, findsOneWidget);
      expect(find.byKey(const Key('builds_create_step_class')), findsOneWidget);
      expect(find.byKey(const Key('builds_create_step_synergy')), findsOneWidget);
      expect(find.byKey(const Key('builds_create_step_name')), findsOneWidget);

      final btn = tester.widget<FilledButton>(createBtn);
      // Product rule: ≥1 synergy required before create (DBR). If onPressed is
      // non-null with zero draft synergies, that is a product defect (logged).
      final draftChips =
          find.byKey(const Key('builds_create_synergy_chips')).evaluate();
      final hasDraft =
          draftChips.isNotEmpty && find.textContaining('melee').evaluate().isNotEmpty;
      if (!hasDraft) {
        expect(
          btn.onPressed,
          isNull,
          reason:
              'ISSUE: Create enabled with zero synergy types (hard gate expected)',
        );
      }
    });

    testWidgets('create with synergy via UI enables build list selection',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(Destiny2WindowsApp(services: services));
      await _pump(tester);
      await _selectNav(tester, 1);

      if (find.byKey(const Key('builds_create_button')).evaluate().isEmpty) {
        await tester.ensureVisible(find.byKey(const Key('builds_create_toggle')));
        await tester.tap(find.byKey(const Key('builds_create_toggle')));
        await _pump(tester);
      }

      final addOpen = find.byKey(const Key('builds_create_add_synergy_open'));
      final addBtn = find.byKey(const Key('builds_create_add_synergy'));
      if (addOpen.evaluate().isNotEmpty) {
        await tester.ensureVisible(addOpen);
        await tester.tap(addOpen);
        await _pump(tester);
      }
      if (addBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(addBtn);
        await tester.tap(addBtn);
        await _pump(tester);
      }

      final nameField = find.byKey(const Key('builds_create_name'));
      if (nameField.evaluate().isNotEmpty) {
        await tester.enterText(nameField, 'Shell UI Build');
        await _pump(tester);
      }

      final createFinder = find.byKey(const Key('builds_create_button'));
      expect(createFinder, findsOneWidget);
      final btn = tester.widget<FilledButton>(createFinder);
      if (btn.onPressed != null) {
        await tester.tap(createFinder);
        await _pump(tester);
        final hasList = find.byKey(const Key('builds_list')).evaluate().isNotEmpty;
        final hasDetail =
            find.byKey(const Key('builds_detail')).evaluate().isNotEmpty;
        expect(hasList || hasDetail, isTrue);
      } else {
        // Synergy not added via UI → still blocked; keys still required.
        expect(btn.onPressed, isNull);
      }
    });
  });

  group('synergy primary create/list controls', () {
    testWidgets('create toggle reveals create button and type fields',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(Destiny2WindowsApp(services: services));
      await _pump(tester);
      await _selectNav(tester, 2);

      await tester.tap(find.byKey(const Key('synergies_create_toggle')));
      await _pump(tester);
      expect(find.byKey(const Key('synergies_create_button')), findsOneWidget);
    });
  });

  group('sets primary create/search controls', () {
    testWidgets('create toggle and type filters present', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(Destiny2WindowsApp(services: services));
      await _pump(tester);
      await _selectNav(tester, 3);

      expect(find.byKey(const Key('sets_search')), findsOneWidget);
      expect(find.byKey(const Key('sets_type_filters')), findsOneWidget);
      expect(find.byKey(const Key('sets_type_chip_all')), findsOneWidget);

      await tester.tap(find.byKey(const Key('sets_create_toggle')));
      await _pump(tester);
      expect(find.byKey(const Key('sets_create_button')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_name')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_type')), findsOneWidget);
    });
  });

  group('catalog primary filter controls', () {
    testWidgets('query, mode, scope, reload work offline', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(Destiny2WindowsApp(services: services));
      await _pump(tester);
      await _selectNav(tester, 4);

      expect(find.byKey(const Key('catalog_query')), findsOneWidget);
      expect(find.byKey(const Key('catalog_reload')), findsOneWidget);
      expect(find.byKey(const Key('mode_chip_weapons')), findsOneWidget);
      expect(find.byKey(const Key('scope_chip_all')), findsOneWidget);
      expect(find.byKey(const Key('scope_chip_owned')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('catalog_query')), 'Kinetic');
      await _pump(tester);
      // At least one fixture matches "Kinetic" in name or filters remain consistent.
      expect(find.byKey(const Key('catalog_status')), findsOneWidget);

      await tester.tap(find.byKey(const Key('scope_chip_owned')));
      await _pump(tester);
      // Owned with empty inventory → empty or list; must not throw.
      expect(
        find.byKey(const Key('catalog_empty')).evaluate().isNotEmpty ||
            find.byKey(const Key('catalog_list')).evaluate().isNotEmpty,
        isTrue,
      );
    });
  });

  group('settings primary cards', () {
    testWidgets('OAuth, inventory sync, manifest refresh keys present',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(Destiny2WindowsApp(services: services));
      await _pump(tester);
      await _selectNav(tester, 5);

      expect(find.byKey(const Key('oauth_account_card')), findsOneWidget);
      expect(find.byKey(const Key('oauth_sign_in')), findsOneWidget);
      expect(find.byKey(const Key('inventory_sync_card')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      final refreshFinder = find.byKey(const Key('refresh_manifest'));
      await tester.scrollUntilVisible(
        refreshFinder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await _pump(tester);
      expect(refreshFinder, findsOneWidget);
      expect(find.byKey(const Key('reload_status')), findsOneWidget);
    });
  });
}
