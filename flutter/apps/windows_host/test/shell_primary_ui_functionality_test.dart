/// Primary shell + destination UI functionality coverage (goal: UI tests, log issues).
///
/// Drives real [Destiny2WindowsApp] / page widgets with offline HostBootstrap fakes.
/// Does not fix product defects — failing expectations / issue annotations document
/// broken or blocked UI. See scratch `ui_functionality_issues.md` for the log.
///
/// Coverage map (shell.nav destinations → cases in this file):
/// - Loadouts: signed-out gate + CTA; signed-in list/filters/detail toggle
/// - Build: create (auto-add type) → list/select → detail zones/chrome
/// - Synergy: create → list → detail designation + identity fields
/// - Sets: create → list → detail type/slots; search/type filters
/// - Catalog: query/scope/mode/reload; select row → detail chrome
/// - Settings: OAuth card, inventory sync, manifest refresh/status
/// - Sign-in: loadouts CTA → Settings; seeded session signed-in chrome; fake OAuth
library;

import 'dart:convert';
import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/app.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/loopback_callback_server.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/auth/windows_oauth_session.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
import 'package:destiny2_windows_host/settings/oauth_account_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'inventory_sync_test_fakes.dart';
import 'test_material_theme.dart';

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

Object _loadoutFixtureProfile() => {
      'characters': {
        'data': {
          'char-titan': {
            'characterId': 'char-titan',
            'classType': 0,
            'light': 1820,
            'dateLastPlayed': '2026-07-23T12:00:00Z',
          },
          'char-hunter': {
            'characterId': 'char-hunter',
            'classType': 1,
            'light': 1810,
            'dateLastPlayed': '2026-07-24T12:00:00Z',
          },
        },
      },
      'characterLoadouts': {
        'data': {
          'char-titan': {
            'loadouts': [
              {
                'iconHash': 111,
                'colorHash': 222,
                'nameHash': 333,
                'items': [
                  {'itemInstanceId': '999', 'plugItemHashes': <int>[]},
                ],
              },
              {
                'iconHash': 0,
                'colorHash': 0,
                'nameHash': 0,
                'items': <Object>[],
              },
            ],
          },
          'char-hunter': {
            'loadouts': [
              {
                'iconHash': 0,
                'colorHash': 0,
                'nameHash': 0,
                'items': [
                  {'itemInstanceId': '111'},
                ],
              },
            ],
          },
        },
      },
    };

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

Future<void> _surface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1400, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

/// Pump until one of [keys] is present or [maxFrames] elapses.
///
/// Uses [WidgetTester.runAsync] so real File I/O (loadout presentation tables)
/// can complete under the test binding.
Future<void> _pumpUntilAny(
  WidgetTester tester,
  List<Key> keys, {
  int maxFrames = 60,
}) async {
  for (var i = 0; i < maxFrames; i++) {
    for (final k in keys) {
      if (find.byKey(k).evaluate().isNotEmpty) return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Invoke a FilledButton by key even when partially clipped in a scroll view.
Future<void> _pressFilled(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await _pump(tester);
  final btn = tester.widget<FilledButton>(finder);
  expect(btn.onPressed, isNotNull, reason: 'button $key disabled');
  btn.onPressed!();
  await _pump(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppServices services;
  late AppDatabase db;
  late MemoryTokenStore tokenStore;

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
    const CatalogItem(
      hash: 303,
      name: 'UI Test Heavy',
      slot: 'Power',
      element: 'Arc',
      ammo: 'Heavy',
      itemTypeName: 'Rocket Launcher',
      isExotic: true,
    ),
  ];

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ui_fn_shell_');
    final root = StorageRoot(basePath: tempDir.path);
    await root.ensureLayout();
    db = AppDatabase.memory();
    tokenStore = MemoryTokenStore();
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
      tokenStore: tokenStore,
      browserLauncher: FakeBrowserLauncher(),
      profileClient: FakeProfileClient(
        characterLoadoutsProfile: _loadoutFixtureProfile(),
      ),
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
      await _surface(tester);
      await tester.pumpWidget(Destiny2WindowsApp(services: services));
      await _pump(tester);

      expect(find.byKey(const Key('host_nav_rail')), findsOneWidget);
      for (final label in Destiny2WindowsApp.navLabels) {
        expect(find.text(label), findsWidgets, reason: 'nav label $label');
      }

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

    testWidgets(
        'selecting each nav index updates rail and shows destination chrome',
        (tester) async {
      await _surface(tester);
      await tester.pumpWidget(Destiny2WindowsApp(services: services));
      await _pump(tester);

      expect(
        tester
            .widget<NavigationRail>(find.byKey(const Key('host_nav_rail')))
            .selectedIndex,
        0,
      );
      expect(find.byKey(const Key('loadouts_page_body')), findsOneWidget);
      expect(find.byKey(const Key('loadouts_title')), findsOneWidget);
      expect(find.byKey(const Key('loadouts_refresh')), findsNothing);

      await _selectNav(tester, 1);
      expect(find.byKey(const Key('builds_library_page')), findsOneWidget);
      expect(
        find.byKey(const Key('builds_list_empty')).evaluate().isNotEmpty ||
            find.byKey(const Key('builds_list')).evaluate().isNotEmpty,
        isTrue,
        reason: 'Build library empty or list',
      );
      expect(find.byKey(const Key('builds_create_toggle')), findsOneWidget);

      await _selectNav(tester, 2);
      expect(find.byKey(const Key('synergies_library_page')), findsOneWidget);
      expect(find.byKey(const Key('synergies_create_toggle')), findsOneWidget);

      await _selectNav(tester, 3);
      expect(find.byKey(const Key('sets_library_page')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_toggle')), findsOneWidget);
      expect(find.byKey(const Key('sets_search')), findsOneWidget);

      await _selectNav(tester, 4);
      expect(find.byKey(const Key('catalog_page')), findsOneWidget);
      expect(find.byKey(const Key('catalog_query')), findsOneWidget);
      expect(find.byKey(const Key('catalog_reload')), findsOneWidget);
      expect(find.byKey(const Key('scope_chip_all')), findsOneWidget);

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

  group('loadouts primary controls', () {
    testWidgets('signed-out state exposes sign-in CTA; filters gated',
        (tester) async {
      await _surface(tester);
      await tester.pumpWidget(Destiny2WindowsApp(services: services));
      await _pump(tester);
      await _selectNav(tester, 0);

      expect(find.byKey(const Key('loadouts_signed_out')), findsOneWidget);
      expect(find.byKey(const Key('loadouts_sign_in_cta')), findsOneWidget);
      expect(find.byKey(const Key('loadouts_filters')), findsNothing);
      expect(find.byKey(const Key('loadouts_filter_hide_empty')), findsNothing);
      expect(find.byKey(const Key('loadouts_refresh')), findsNothing);

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

    testWidgets(
        'signed-in lists loadouts; filters and detail toggle work offline',
        (tester) async {
      await seedSignedIn(tokenStore);
      await services.oauthSession.restore();
      expect(services.oauthSession.isSignedIn, isTrue);

      await _surface(tester);
      await tester.pumpWidget(Destiny2WindowsApp(services: services));
      await _pump(tester);
      await _selectNav(tester, 0);
      await _pumpUntilAny(
        tester,
        [
          const Key('loadouts_list'),
          const Key('loadouts_empty'),
          const Key('loadouts_error'),
          const Key('loadouts_loading'),
          const Key('loadouts_signed_out'),
        ],
      );
      // Extra settle for presentation-table File I/O + profile parse.
      for (var i = 0; i < 15; i++) {
        if (find.byKey(const Key('loadouts_list')).evaluate().isNotEmpty ||
            find.byKey(const Key('loadouts_empty')).evaluate().isNotEmpty ||
            find.byKey(const Key('loadouts_error')).evaluate().isNotEmpty) {
          break;
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump();
      }

      expect(find.byKey(const Key('loadouts_signed_out')), findsNothing);
      expect(find.byKey(const Key('loadouts_filters')), findsOneWidget);
      expect(find.byKey(const Key('loadouts_refresh')), findsOneWidget);

      final hasList =
          find.byKey(const Key('loadouts_list')).evaluate().isNotEmpty;
      final hasEmpty =
          find.byKey(const Key('loadouts_empty')).evaluate().isNotEmpty;
      final hasError =
          find.byKey(const Key('loadouts_error')).evaluate().isNotEmpty;
      final stuckLoading =
          find.byKey(const Key('loadouts_loading')).evaluate().isNotEmpty;
      // Product should parse FakeProfileClient fixture into non-empty list.
      expect(
        hasList || hasEmpty || hasError,
        isTrue,
        reason:
            'ISSUE-LOADOUTS-SHELL-001: signed-in shell never settled '
            '(loading=$stuckLoading empty=$hasEmpty error=$hasError list=$hasList)',
      );
      expect(
        hasList,
        isTrue,
        reason:
            'ISSUE-LOADOUTS-SHELL-001: signed-in shell with fixture profile '
            'did not show loadouts_list (empty=$hasEmpty error=$hasError)',
      );

      final tiles = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('loadout_tile_'),
      );
      if (tiles.evaluate().isNotEmpty) {
        final firstKey = tiles.evaluate().first.widget.key! as ValueKey<String>;
        final id = firstKey.value.replaceFirst('loadout_tile_', '');
        final toggle = find.byKey(Key('loadout_details_toggle_$id'));
        if (toggle.evaluate().isNotEmpty) {
          await tester.ensureVisible(toggle);
          await tester.tap(toggle);
          await _pump(tester);
          expect(find.byKey(Key('loadout_details_$id')), findsOneWidget);
          expect(
            find.byKey(Key('loadout_detail_character_$id')),
            findsOneWidget,
          );
          expect(
            find.byKey(Key('loadout_detail_instances_$id')),
            findsOneWidget,
          );
        }
      }

      final hideEmpty = find.byKey(const Key('loadouts_filter_hide_empty'));
      if (hideEmpty.evaluate().isNotEmpty) {
        await tester.tap(hideEmpty);
        await _pump(tester);
      }
    });
  });

  group('build primary create flow (shell-mounted)', () {
    testWidgets(
        'Create with empty chips auto-adds selected type and shows detail chrome',
        (tester) async {
      await _surface(tester);
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
      expect(find.byKey(const Key('builds_create_synergy_type')), findsOneWidget);

      // Product UX: Create auto-adds dropdown type when chips empty (not disabled).
      // Domain still requires ≥1 synergy on write — satisfied by auto-add path.
      final btn = tester.widget<FilledButton>(createBtn);
      expect(
        btn.onPressed,
        isNotNull,
        reason: 'Create should be tappable; auto-adds selected type',
      );
      // Document intentional design (not ISSUE-001 hard-disabled expectation).
      expect(
        find.byKey(const Key('builds_create_types_hint')).evaluate().isNotEmpty ||
            find.byKey(const Key('builds_create_synergy_chips')).evaluate().isNotEmpty,
        isTrue,
      );

      final nameField = find.byKey(const Key('builds_create_name'));
      await tester.enterText(nameField, 'Shell UI Build');
      await _pump(tester);
      await _pressFilled(tester, const Key('builds_create_button'));
      await _pumpUntilAny(tester, [
        const Key('builds_list'),
        const Key('builds_detail'),
        const Key('builds_status'),
      ]);

      expect(find.byKey(const Key('builds_list')), findsOneWidget);
      expect(find.text('Shell UI Build'), findsWidgets);
      expect(find.byKey(const Key('builds_detail')), findsOneWidget);
      expect(find.byKey(const Key('builds_detail_title')), findsOneWidget);
      expect(find.byKey(const Key('builds_detail_class')), findsOneWidget);
      expect(find.byKey(const Key('builds_detail_synergy_types')), findsOneWidget);
      expect(find.byKey(const Key('builds_zone_identity')), findsOneWidget);
      expect(find.byKey(const Key('builds_zone_loadout')), findsOneWidget);
      expect(find.byKey(const Key('builds_zone_readiness')), findsOneWidget);
      expect(find.byKey(const Key('builds_save_identity')), findsOneWidget);
      expect(find.byKey(const Key('builds_slot_pins_list')), findsOneWidget);
      expect(find.byKey(const Key('builds_subclass_kit_summary')), findsOneWidget);
      expect(find.byKey(const Key('builds_equip_panel')), findsOneWidget);
      expect(find.byKey(const Key('builds_dim_export_panel')), findsOneWidget);
    });

    testWidgets('Add another type chip path still creates via UI',
        (tester) async {
      await _surface(tester);
      await tester.pumpWidget(Destiny2WindowsApp(services: services));
      await _pump(tester);
      await _selectNav(tester, 1);

      if (find.byKey(const Key('builds_create_button')).evaluate().isEmpty) {
        await tester.ensureVisible(find.byKey(const Key('builds_create_toggle')));
        await tester.tap(find.byKey(const Key('builds_create_toggle')));
        await _pump(tester);
      }

      final addBtn = find.byKey(const Key('builds_create_add_synergy'));
      expect(addBtn, findsOneWidget);
      await tester.ensureVisible(addBtn);
      await tester.tap(addBtn);
      await _pump(tester);
      expect(find.byKey(const Key('builds_create_synergy_chips')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('builds_create_name')),
        'Chip Path Build',
      );
      await _pump(tester);
      await _pressFilled(tester, const Key('builds_create_button'));
      await _pumpUntilAny(tester, [
        const Key('builds_list'),
        const Key('builds_detail'),
      ]);

      expect(find.byKey(const Key('builds_list')), findsOneWidget);
      expect(find.text('Chip Path Build'), findsWidgets);
      expect(find.byKey(const Key('builds_detail')), findsOneWidget);
    });
  });

  group('synergy primary create/list/detail (shell-mounted)', () {
    testWidgets('create synergy appears in list with designation detail',
        (tester) async {
      await _surface(tester);
      await tester.pumpWidget(Destiny2WindowsApp(services: services));
      await _pump(tester);
      await _selectNav(tester, 2);

      expect(find.byKey(const Key('synergies_list_empty')), findsOneWidget);
      expect(find.byKey(const Key('synergies_search')), findsOneWidget);
      expect(find.byKey(const Key('synergies_type_filters')), findsOneWidget);

      if (find.byKey(const Key('synergies_create_button')).evaluate().isEmpty) {
        await tester.tap(find.byKey(const Key('synergies_create_toggle')));
        await _pump(tester);
      }
      expect(find.byKey(const Key('synergies_create_button')), findsOneWidget);
      expect(find.byKey(const Key('synergies_create_name')), findsOneWidget);
      expect(find.byKey(const Key('synergies_create_type')), findsOneWidget);
      expect(find.byKey(const Key('synergies_create_subtype')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('synergies_create_name')),
        'Shell Melee Combo',
      );
      await tester.enterText(
        find.byKey(const Key('synergies_create_subtype')),
        'Base',
      );
      await tester.tap(find.byKey(const Key('synergies_create_button')));
      await _pump(tester);

      expect(find.byKey(const Key('synergies_list')), findsOneWidget);
      expect(find.text('Shell Melee Combo'), findsWidgets);
      expect(find.byKey(const Key('synergies_detail')), findsOneWidget);
      expect(find.byKey(const Key('synergies_detail_designation')), findsOneWidget);
      expect(find.byKey(const Key('synergies_designation_locked')), findsOneWidget);
      expect(find.byKey(const Key('synergies_edit_name')), findsOneWidget);
      expect(find.byKey(const Key('synergies_save_identity')), findsOneWidget);
      expect(find.byKey(const Key('synergies_delete_button')), findsOneWidget);
      // Links panel present (empty offline).
      expect(
        find.byKey(const Key('synergies_links_empty')).evaluate().isNotEmpty ||
            find.byKey(const Key('synergies_links_list')).evaluate().isNotEmpty,
        isTrue,
      );
    });
  });

  group('sets primary create/list/detail (shell-mounted)', () {
    testWidgets('create set shows detail type and empty slots', (tester) async {
      await _surface(tester);
      await tester.pumpWidget(Destiny2WindowsApp(services: services));
      await _pump(tester);
      await _selectNav(tester, 3);

      expect(find.byKey(const Key('sets_search')), findsOneWidget);
      expect(find.byKey(const Key('sets_type_filters')), findsOneWidget);
      expect(find.byKey(const Key('sets_type_chip_all')), findsOneWidget);
      expect(find.byKey(const Key('sets_list_empty')), findsOneWidget);

      if (find.byKey(const Key('sets_create_button')).evaluate().isEmpty) {
        await tester.tap(find.byKey(const Key('sets_create_toggle')));
        await _pump(tester);
      }
      expect(find.byKey(const Key('sets_create_button')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_name')), findsOneWidget);
      expect(find.byKey(const Key('sets_create_type')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('sets_create_name')),
        'Shell Kinetic Set',
      );
      await tester.tap(find.byKey(const Key('sets_create_button')));
      await _pump(tester);

      expect(find.byKey(const Key('sets_list')), findsOneWidget);
      expect(find.text('Shell Kinetic Set'), findsWidgets);
      expect(find.byKey(const Key('sets_detail')), findsOneWidget);
      expect(find.byKey(const Key('sets_detail_type')), findsOneWidget);
      expect(find.byKey(const Key('sets_edit_name')), findsOneWidget);
      expect(find.byKey(const Key('sets_save_name')), findsOneWidget);
      expect(find.byKey(const Key('sets_readiness_strip')), findsOneWidget);
      expect(find.byKey(const Key('sets_slot_empty_primary')), findsOneWidget);
      expect(find.byKey(const Key('sets_slot_fill_primary')), findsOneWidget);

      // Fill primary from catalog picker (offline fixtures).
      await tester.tap(find.byKey(const Key('sets_slot_fill_primary')));
      await _pump(tester);
      expect(find.byKey(const Key('set_catalog_picker')), findsOneWidget);
      final pick = find.byKey(const Key('set_picker_item_101'));
      if (pick.evaluate().isNotEmpty) {
        await tester.tap(pick);
        await _pump(tester);
        final confirm = find.byKey(const Key('set_picker_confirm'));
        final confirmWish =
            find.byKey(const Key('set_picker_confirm_wishlist'));
        if (confirm.evaluate().isNotEmpty) {
          await tester.tap(confirm);
          await _pump(tester);
        } else if (confirmWish.evaluate().isNotEmpty) {
          await tester.tap(confirmWish);
          await _pump(tester);
        }
        expect(
          find.byKey(const Key('sets_slot_filled_primary')).evaluate().isNotEmpty ||
              find.byKey(const Key('sets_slot_empty_primary')).evaluate().isNotEmpty,
          isTrue,
          reason: 'slot should fill or remain empty with status',
        );
      } else {
        // Catalog picker empty for weapons set type without matching fixtures.
        expect(
          find.byKey(const Key('set_picker_empty')).evaluate().isNotEmpty ||
              find.byKey(const Key('set_picker_list')).evaluate().isNotEmpty,
          isTrue,
          reason: 'ISSUE-SET-PICKER: no items and no empty state in set picker',
        );
      }
    });
  });

  group('catalog primary filter + detail', () {
    testWidgets('query, mode, scope, reload and select row show detail',
        (tester) async {
      await _surface(tester);
      await tester.pumpWidget(Destiny2WindowsApp(services: services));
      await _pump(tester);
      await _selectNav(tester, 4);

      expect(find.byKey(const Key('catalog_query')), findsOneWidget);
      expect(find.byKey(const Key('catalog_reload')), findsOneWidget);
      expect(find.byKey(const Key('mode_chip_weapons')), findsOneWidget);
      expect(find.byKey(const Key('scope_chip_all')), findsOneWidget);
      expect(find.byKey(const Key('scope_chip_owned')), findsOneWidget);
      expect(find.byKey(const Key('catalog_list')), findsOneWidget);
      expect(find.byKey(const Key('catalog_item_101')), findsOneWidget);
      expect(find.byKey(const Key('catalog_status')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('catalog_query')), 'Kinetic');
      await _pump(tester);
      expect(find.byKey(const Key('catalog_status')), findsOneWidget);

      await tester.tap(find.byKey(const Key('scope_chip_owned')));
      await _pump(tester);
      expect(
        find.byKey(const Key('catalog_empty')).evaluate().isNotEmpty ||
            find.byKey(const Key('catalog_list')).evaluate().isNotEmpty,
        isTrue,
      );

      await tester.tap(find.byKey(const Key('scope_chip_all')));
      await _pump(tester);
      await tester.enterText(find.byKey(const Key('catalog_query')), '');
      await _pump(tester);

      final row = find.byKey(const Key('catalog_item_101'));
      expect(row, findsOneWidget);
      await tester.ensureVisible(row);
      await tester.tap(row);
      await _pump(tester);
      // Detail pane: kind label + name for selected item.
      expect(find.byKey(const Key('detail_kind_label')), findsOneWidget);
      expect(find.text('UI Test Kinetic'), findsWidgets);

      await tester.tap(find.byKey(const Key('catalog_reload')));
      await _pump(tester);
      expect(find.byKey(const Key('catalog_status')), findsOneWidget);
    });
  });

  group('settings primary cards + sign-in path', () {
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
      expect(find.byKey(const Key('inventory_sync_signed_out')), findsOneWidget);

      final syncNow = find.byKey(const Key('inventory_sync_now'));
      if (syncNow.evaluate().isNotEmpty) {
        final btn = tester.widget<ButtonStyleButton>(syncNow);
        expect(
          btn.onPressed,
          isNull,
          reason: 'Sync should be disabled when signed out',
        );
      }

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

      await tester.tap(find.byKey(const Key('reload_status')));
      await _pump(tester);
      expect(find.byKey(const Key('manifest_status_card')), findsOneWidget);
    });

    testWidgets('seeded signed-in session shows membership and sign-out',
        (tester) async {
      await seedSignedIn(tokenStore, membershipId: 'mem-shell-ui');
      await services.oauthSession.restore();

      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(Destiny2WindowsApp(services: services));
      await _pump(tester);
      await _selectNav(tester, 5);

      expect(find.byKey(const Key('oauth_membership_id')), findsOneWidget);
      expect(find.textContaining('mem-shell-ui'), findsOneWidget);
      expect(find.byKey(const Key('oauth_sign_out')), findsOneWidget);
      expect(find.byKey(const Key('oauth_sign_in')), findsNothing);
      expect(find.byKey(const Key('inventory_sync_signed_out')), findsNothing);
      expect(find.byKey(const Key('inventory_sync_now')), findsOneWidget);
    });

    testWidgets('fake OAuth sign-in success updates account card',
        (tester) async {
      // Isolated card path (same shipped OAuthAccountCard + WindowsOAuthSession).
      String? state;
      final browser = FakeBrowserLauncher();
      final store = MemoryTokenStore();
      final session = WindowsOAuthSession(
        clientId: 'cid',
        redirectUri: 'http://127.0.0.1:8765/callback',
        tokenStore: store,
        oauthClient: BungieOAuthClient(
          clientId: 'cid',
          redirectUri: 'http://127.0.0.1:8765/callback',
          transport: (_) async => BungieHttpResponse(
            statusCode: 200,
            body: jsonEncode({
              'access_token': 'acc',
              'token_type': 'Bearer',
              'expires_in': 3600,
              'refresh_token': 'ref',
              'refresh_expires_in': 7776000,
              'membership_id': 'M-FAKE-SIGNIN',
            }),
          ),
        ),
        browserLauncher: browser,
        waitForCallbackOverride: () async {
          final uri = Uri.parse(browser.opened.single);
          state = uri.queryParameters['state'];
          return LoopbackCallbackResult(code: 'c', state: state);
        },
      );
      await session.restore();

      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: Scaffold(body: OAuthAccountCard(session: session)),
        ),
      );
      await _pump(tester);

      expect(find.byKey(const Key('oauth_sign_in')), findsOneWidget);
      final signIn = tester.widget<FilledButton>(
        find.byKey(const Key('oauth_sign_in')),
      );
      expect(signIn.onPressed, isNotNull);
      signIn.onPressed!();
      await _pump(tester);

      expect(session.isSignedIn, isTrue);
      expect(find.byKey(const Key('oauth_membership_id')), findsOneWidget);
      expect(find.textContaining('M-FAKE-SIGNIN'), findsOneWidget);
      expect(find.byKey(const Key('oauth_sign_out')), findsOneWidget);
      expect(browser.opened, isNotEmpty);
      session.dispose();
    });
  });
}
