import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/catalog/catalog_page.dart';
import 'package:destiny2_windows_host/catalog/owned_catalog_bridge.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'catalog_residual_polish_fixtures.dart';
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
    tempDir = await Directory.systemTemp.createTemp('weapons_smoke_');
    final root = StorageRoot(basePath: tempDir.path);
    await root.ensureLayout();
    services = await HostBootstrap.open(
      storageRoot: root,
      database: AppDatabase.memory(),
      manifestRefresh: _FakeRefresh(),
      offlineCatalog: OfflineCatalog.preloaded(
        storageRoot: root,
        items: fixtureItems,
        version: 'smoke-1',
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

  testWidgets('signed-out All grid + not-owned honesty', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: testMaterialTheme(),
        home: CatalogPage(services: services),
      ),
    );
    await _pumpFrames(tester);

    expect(services.oauthSession.isSignedIn, isFalse);
    expect(find.byKey(const Key('catalog_list')), findsOneWidget);
    expect(itemKey(1), findsOneWidget);
    expect(itemKey(2), findsOneWidget);
    expect(itemKey(3), findsOneWidget);
    // Never fake owned badges when signed out.
    expect(find.byKey(const Key('owned_badge_1')), findsNothing);
    expect(find.byKey(const Key('owned_badge_2')), findsNothing);
    // Primary filter chips visible without double-expand ListTile.
    expect(find.byKey(const Key('element_chip_Solar')), findsOneWidget);
    expect(find.byKey(const Key('slot_chip_Kinetic')), findsOneWidget);
    expect(find.byKey(const Key('catalog_scope_control')), findsOneWidget);
    expect(find.byKey(const Key('catalog_filters_toggle')), findsNothing);
  });

  testWidgets('facet refilter + RESET + zero empty Clear', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: testMaterialTheme(),
        home: CatalogPage(services: services),
      ),
    );
    await _pumpFrames(tester);

    // Primary chips always on — no expand required.
    await tester.tap(find.byKey(const Key('element_chip_Solar')));
    await _pumpFrames(tester);
    expect(itemKey(2), findsOneWidget);
    expect(itemKey(1), findsNothing);

    await tester.tap(find.byKey(const Key('catalog_clear_filters')));
    await _pumpFrames(tester);
    expect(itemKey(1), findsOneWidget);
    expect(itemKey(3), findsOneWidget);

    await tester.enterText(find.byKey(const Key('catalog_query')), 'zzzz-none');
    await _pumpFrames(tester);
    expect(find.byKey(const Key('catalog_empty')), findsOneWidget);
    expect(find.byKey(const Key('catalog_empty_clear_filters')), findsOneWidget);

    await tester.tap(find.byKey(const Key('catalog_empty_clear_filters')));
    await _pumpFrames(tester);
    expect(find.byKey(const Key('catalog_list')), findsOneWidget);
  });

  testWidgets('select unowned weapon opens ~400px detail; POSSIBLE ROLLS; stubs disabled',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: testMaterialTheme(),
        home: CatalogPage(services: services),
      ),
    );
    await _pumpFrames(tester);

    await tester.tap(itemKey(2));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('catalog_detail_pane')), findsOneWidget);
    final detail = tester.getSize(find.byKey(const Key('catalog_detail_pane')));
    expect(detail.width, 400);

    // Unowned: full definition pools as POSSIBLE ROLLS — can-roll/craft toggles
    // are owned-only (selected-until-can-roll does not apply without a copy).
    expect(
      find.byKey(const Key('catalog_perk_section_possible_rolls')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('catalog_toggle_can_roll')), findsNothing);
    expect(find.byKey(const Key('catalog_toggle_craft')), findsNothing);
    expect(find.byKey(const Key('instance_panel_empty')), findsOneWidget);

    final setBtn =
        tester.widget<FilledButton>(find.byKey(const Key('catalog_stub_set')));
    final synBtn = tester
        .widget<FilledButton>(find.byKey(const Key('catalog_stub_synergy')));
    expect(setBtn.onPressed, isNull);
    expect(synBtn.onPressed, isNull);

    // Live create keys must not appear on weapons path.
    expect(find.byKey(const Key('detail_create_set')), findsNothing);
    expect(find.byKey(const Key('universal_create_set')), findsNothing);
  });

  testWidgets('missing-manifest empty CTAs still wired', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var openedSettings = false;
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
      MaterialApp(
        theme: testMaterialTheme(),
        home: CatalogPage(
          services: emptyServices,
          onOpenSettings: () => openedSettings = true,
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('catalog_empty')), findsOneWidget);
    expect(find.byKey(const Key('catalog_empty_reload')), findsOneWidget);
    final settings = find.byKey(const Key('catalog_empty_settings'));
    expect(settings, findsOneWidget);
    await tester.ensureVisible(settings);
    await _pumpFrames(tester);
    await tester.tap(settings, warnIfMissed: false);
    await _pumpFrames(tester);
    expect(openedSettings, isTrue);
  });

  // Owned can-roll OFF default + craft hidden when no craft pool data is
  // covered in catalog_owned_page_test (signed-in inventory bootstrap).

  group('residual-polish host fixtures', () {
    late Directory residualDir;
    late AppServices residualServices;
    late AppDatabase residualDb;
    late OwnedCatalogBridge residualBridge;

    setUp(() async {
      residualDir =
          await Directory.systemTemp.createTemp('weapons_residual_');
      final root = StorageRoot(basePath: residualDir.path);
      await root.ensureLayout();
      residualDb = AppDatabase.memory();
      final tokenStore = MemoryTokenStore();
      await seedSignedIn(tokenStore, membershipId: 'bungie-residual');

      residualServices = await HostBootstrap.open(
        storageRoot: root,
        database: residualDb,
        manifestRefresh: _FakeRefresh(),
        offlineCatalog: OfflineCatalog.preloaded(
          storageRoot: root,
          items: residualPolishCatalogItems(),
          version: 'residual-polish-1',
          perkColumnsByHash: residualPolishPerkColumns(),
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

      final user = await ensureUser(
        residualDb,
        bungieMembershipId: 'bungie-residual',
        membershipType: 3,
        displayName: 'Residual Guardian',
      );
      await replaceInventoryBatch(
        residualDb,
        user.id,
        now: '2026-08-04T12:00:00.000Z',
        items: [residualEnhancedInventoryRow()],
      );

      residualBridge = OwnedCatalogBridge(
        db: residualDb,
        offlineCatalog: residualServices.offlineCatalog,
        session: residualServices.oauthSession,
        inventorySync: residualServices.inventorySync,
        plugNameByHash: kResidualPlugNameByHash,
        plugEnhancedByHash: kResidualPlugEnhancedByHash,
        plugNameMapBuilder: (hashes) async => {
          for (final h in hashes)
            if (kResidualPlugNameByHash.containsKey(h))
              h: kResidualPlugNameByHash[h]!,
        },
        plugEnhancedMapBuilder: (hashes) async => {
          for (final h in hashes)
            if (kResidualPlugEnhancedByHash[h] == true) h: true,
        },
      );
    });

    tearDown(() async {
      await residualServices.dispose();
      if (residualDir.existsSync()) {
        await residualDir.delete(recursive: true);
      }
    });

    Future<void> pumpResidualCatalog(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: CatalogPage(
            services: residualServices,
            bridge: residualBridge,
          ),
        ),
      );
      await _pumpFrames(tester);
      // Allow inventory annotate + plug resolve.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> tapItem(WidgetTester tester, int hash) async {
      final finder = itemKey(hash);
      expect(finder, findsOneWidget);
      final listScrollable = find.descendant(
        of: find.byKey(const Key('catalog_list')),
        matching: find.byType(Scrollable),
      );
      if (listScrollable.evaluate().isNotEmpty) {
        await tester.scrollUntilVisible(
          finder,
          64,
          scrollable: listScrollable,
        );
        await _pumpFrames(tester);
      }
      await tester.tap(finder);
      await _pumpFrames(tester);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets(
      'desktop-enhanced-live: plugEnhancedByHash → gold+E on ① only; no E on ②',
      (tester) async {
        await pumpResidualCatalog(tester);
        await tapItem(tester, kResidualEnhancedWeaponHash);

        expect(find.byKey(const Key('catalog_detail_pane')), findsOneWidget);
        expect(
          find.byKey(const Key('catalog_perk_section_perks')),
          findsOneWidget,
        );
        // ① Enhanced Frenzy marked.
        expect(
          find.byKey(
            const Key('perk_enhanced_mark_$kResidualEnhancedPlugHash'),
          ),
          findsOneWidget,
        );
        // ② Overflow not enhanced.
        expect(
          find.byKey(const Key('perk_enhanced_mark_$kResidualBasePlugHash')),
          findsNothing,
        );
        // Possible rolls OFF default — mock view-toggle (not FilterChip on toggle key).
        expect(
          find.ancestor(
            of: find.byKey(const Key('catalog_toggle_can_roll')),
            matching: find.byType(FilterChip),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('catalog_toggle_can_roll')),
            matching: find.byType(FilterChip),
          ),
          findsNothing,
        );
        expect(
          tester
              .getSemantics(find.byKey(const Key('catalog_toggle_can_roll')))
              .hasFlag(SemanticsFlag.isToggled),
          isFalse,
        );
        expect(find.byKey(const Key('catalog_toggle_craft')), findsNothing);
        // Tier chrome: ① badge + ② chevron on residual HC.
        expect(
          find.byKey(const Key('perk_tier_badge_$kResidualEnhancedPlugHash')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('perk_chevron_$kResidualBasePlugHash')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'desktop-enhanced-live ③ ON: no E on pool cells; enhance note when pool can enhance',
      (tester) async {
        await pumpResidualCatalog(tester);
        await tapItem(tester, kResidualEnhancedWeaponHash);

        await tester.tap(find.byKey(const Key('catalog_toggle_can_roll')));
        await _pumpFrames(tester);
        await tester.pump(const Duration(milliseconds: 50));

        // ① still has E.
        expect(
          find.byKey(
            const Key('perk_enhanced_mark_$kResidualEnhancedPlugHash'),
          ),
          findsOneWidget,
        );
        // Pool enhanced identity must not get E cell chrome.
        expect(
          find.byKey(
            const Key('perk_enhanced_mark_$kResidualPoolEnhancedPlugHash'),
          ),
          findsNothing,
        );
        expect(find.byKey(const Key('catalog_enhance_note')), findsOneWidget);
      },
    );

    testWidgets(
      'desktop-catalyst-present: soft catalyst display-only; no equip gate',
      (tester) async {
        await pumpResidualCatalog(tester);
        await tapItem(tester, kResidualCatalystExoticHash);

        expect(find.byKey(const Key('catalog_detail_pane')), findsOneWidget);
        expect(find.byKey(const Key('exotic_catalyst_name')), findsOneWidget);
        expect(
          find.byKey(const Key('exotic_catalyst_display_only')),
          findsOneWidget,
        );
        // Unowned exotic: no fake selected / no can-roll toggle.
        expect(find.byKey(const Key('catalog_toggle_can_roll')), findsNothing);
        expect(find.byKey(const Key('instance_panel_empty')), findsOneWidget);
      },
    );

    testWidgets(
      'desktop-enhance-note: unowned definition pool note; one cell; no E',
      (tester) async {
        await pumpResidualCatalog(tester);
        await tapItem(tester, kResidualEnhanceNoteWeaponHash);

        expect(
          find.byKey(const Key('catalog_perk_section_possible_rolls')),
          findsOneWidget,
        );
        // Identity collapse: base Rapid Hit + Enhanced Kill Clip → note, no E.
        expect(find.byKey(const Key('catalog_enhance_note')), findsOneWidget);
        expect(
          find.byKey(
            const Key('perk_enhanced_mark_$kResidualPoolEnhancedPlugHash'),
          ),
          findsNothing,
        );
        expect(
          find.byKey(const Key('perk_cell_$kResidualPoolBasePlugHash')),
          findsOneWidget,
        );
      },
    );
  });
}



