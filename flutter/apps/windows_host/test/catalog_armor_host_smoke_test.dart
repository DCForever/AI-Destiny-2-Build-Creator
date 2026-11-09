import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/catalog/armor_detail_projection.dart';
import 'package:destiny2_windows_host/catalog/catalog_page.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'catalog_armor_fixtures.dart';
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
  await tester.pump(const Duration(milliseconds: 50));
}

Finder itemKey(int hash) =>
    find.byKey(Key('catalog_item_$hash'), skipOffstage: false);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('armor mode signed-out + fixtures', () {
    late Directory tempDir;
    late AppServices services;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('armor_smoke_');
      final root = StorageRoot(basePath: tempDir.path);
      await root.ensureLayout();
      services = await HostBootstrap.open(
        storageRoot: root,
        database: AppDatabase.memory(),
        manifestRefresh: _FakeRefresh(),
        offlineCatalog: OfflineCatalog.preloaded(
          storageRoot: root,
          items: kArmorFixtureItems,
          version: 'armor-smoke-1',
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

    Future<void> openArmorMode(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: CatalogPage(services: services),
        ),
      );
      await _pumpFrames(tester);

      await tester.tap(find.byKey(const Key('mode_chip_armor')));
      await _pumpFrames(tester);
    }

    testWidgets('armor mode grid + facets + signed-out honesty', (tester) async {
      await openArmorMode(tester);

      expect(find.byKey(const Key('catalog_list')), findsOneWidget);
      expect(itemKey(kArmorSynthoceps.hash), findsOneWidget);
      expect(itemKey(kArmorFieldPlate.hash), findsOneWidget);
      expect(itemKey(kArmorClassItem.hash), findsOneWidget);
      expect(
        find.byKey(Key('owned_badge_${kArmorSynthoceps.hash}')),
        findsNothing,
      );
      expect(find.byKey(const Key('class_chip_Titan')), findsOneWidget);
      expect(find.byKey(const Key('slot_chip_Helmet')), findsOneWidget);
      expect(find.byKey(const Key('exotic_chip')), findsOneWidget);
      expect(find.byKey(const Key('element_chip_Solar')), findsNothing);
      expect(find.byKey(const Key('catalog_sort_group_open')), findsNothing);
      expect(find.byKey(const Key('catalog_toggle_can_roll')), findsNothing);
    });

    testWidgets('Capture fixture keys: dual boards + strip rebind + mods',
        (tester) async {
      final map = armorCaptureFixtureMap();
      expect(map.keys, containsAll([
        'desktop-detail-owned',
        'desktop-instance-strip',
        'desktop-mods-energy',
        'desktop-live-null-copy',
        'desktop-grid',
        'desktop-detail-unowned',
        'desktop-set-bonus',
        'desktop-exotic-callout',
        'desktop-owned-empty',
        'desktop-signed-out-owned',
        'desktop-soft-error',
      ]));

      final owned = map['desktop-detail-owned']!;
      expect(owned, isNotEmpty);
      expect(owned.first.instanceId, 'syn-high');
      expect(owned.first.baseBoard, isNotNull);
      expect(owned.first.liveBoard, isNotNull);

      final liveNull = map['desktop-live-null-copy']!;
      expect(liveNull.single.liveUnavailable, isTrue);
      expect(liveNull.single.liveBoard, isNull);
      expect(liveNull.single.baseBoard, isNotNull);

      final mods = map['desktop-mods-energy']!;
      expect(mods.single.mods, isNotEmpty);
      expect(mods.single.energy, isNotNull);

      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      String? selectedId = owned.first.instanceId;
      ArmorInstanceStripItem selected = owned.first;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              theme: testMaterialTheme(),
              home: Scaffold(
                body: CatalogWeaponsWorkspace(
                  main: CatalogArmorGrid(
                    items: kArmorFixtureItems,
                    selectedHash: kArmorSynthoceps.hash,
                    showOwned: true,
                  ),
                  detail: CatalogArmorDetail(
                    item: kArmorSynthoceps,
                    instances: owned,
                    selectedInstanceId: selectedId,
                    onSelectInstance: (c) {
                      setState(() {
                        selectedId = c.instanceId;
                        selected = c;
                      });
                    },
                    setBonus: kArmorSetBonusTechsec,
                    exoticPerk: kSynthocepsExoticPerk(),
                  ),
                ),
              ),
            );
          },
        ),
      );
      await _pumpFrames(tester);

      expect(find.byKey(const Key('catalog_detail_pane')), findsOneWidget);
      final detail =
          tester.getSize(find.byKey(const Key('catalog_detail_pane')));
      expect(detail.width, 400);

      expect(find.byKey(const Key('armor_base_live_stat_board')), findsOneWidget);
      expect(find.byKey(const Key('armor_base_board')), findsOneWidget);
      expect(find.byKey(const Key('armor_live_board')), findsOneWidget);
      expect(find.byKey(const Key('armor_instance_strip')), findsOneWidget);
      expect(find.byKey(const Key('armor_set_bonus_callout')), findsOneWidget);
      expect(find.byKey(const Key('armor_exotic_perk_callout')), findsOneWidget);
      expect(find.byKey(const Key('catalog_outbound_stubs')), findsOneWidget);

      await tester.tap(find.byKey(const Key('armor_instance_syn-low')));
      await _pumpFrames(tester);
      expect(selectedId, 'syn-low');
      expect(selected.baseBoard?.total, 66);
    });

    testWidgets('signed-out Owned scope → sign-in empty', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: CatalogPage(
            services: services,
            onOpenSettings: () {},
          ),
        ),
      );
      await _pumpFrames(tester);
      await tester.tap(find.byKey(const Key('mode_chip_armor')));
      await _pumpFrames(tester);

      await tester.tap(find.byKey(const Key('scope_chip_owned')));
      await _pumpFrames(tester);

      expect(find.byKey(const Key('catalog_empty')), findsOneWidget);
      expect(find.byKey(const Key('catalog_empty_settings')), findsOneWidget);
      expect(find.byKey(const Key('catalog_empty_sync_hint')), findsOneWidget);
    });

    test('projection dual boards and set/exotic helpers', () {
      final projected = projectArmorInstances(kSynthocepsInstances());
      expect(projected.first.instanceId, 'syn-high');
      expect(projected.first.baseBoard?.total, 138);
      expect(projected.first.liveBoard, isNotNull);
      final liveNull =
          projected.firstWhere((p) => p.instanceId == 'syn-live-null');
      expect(liveNull.liveUnavailable, isTrue);
      expect(liveNull.liveBoard, isNull);
      expect(liveNull.baseBoard, isNotNull);

      expect(
        armorSetBonusFromDefinition(knownNone: true)?.explicitNone,
        isTrue,
      );
      expect(
        armorExoticPerkFromItem(
          isExotic: true,
          intrinsicName: 'Biotic Enhancements',
        )?.name,
        'Biotic Enhancements',
      );
      expect(
        armorExoticPerkFromItem(isExotic: true, intrinsicName: null),
        isNull,
      );
    });
  });

  group('armor mode signed-in owned', () {
    late Directory tempDir;
    late AppServices services;
    late AppDatabase db;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('armor_smoke_owned_');
      final root = StorageRoot(basePath: tempDir.path);
      await root.ensureLayout();
      db = AppDatabase.memory();
      final tokenStore = MemoryTokenStore();
      await seedSignedIn(tokenStore, membershipId: 'bungie-armor-1');

      final user = await ensureUser(
        db,
        bungieMembershipId: 'bungie-armor-1',
        membershipType: 3,
        displayName: 'Guardian',
      );
      await replaceInventoryBatch(
        db,
        user.id,
        now: '2026-08-01T00:00:00.000Z',
        items: [
          InventoryItemRecord(
            instanceId: 'syn-low',
            itemHash: kArmorSynthoceps.hash,
            bucket: 'Gauntlets',
            location: 'vault',
            power: 2000,
            gearTier: 3,
            statValues: const {
              'Health': 15,
              'Melee': 15,
              'Grenade': 10,
              'Super': 10,
              'Class': 10,
              'Weapons': 10,
              'energyUsed': 2,
              'energyCapacity': 10,
            },
            plugHashes: const [7001],
            socketPlugs: const [
              {
                'columnKind': 'mod',
                'columnLabel': 'Armor Mod',
                'equippedPlugHash': 7001,
                'reusablePlugHashes': <int>[],
              },
            ],
            syncedAt: '2026-08-01T00:00:00.000Z',
          ),
          InventoryItemRecord(
            instanceId: 'syn-high',
            itemHash: kArmorSynthoceps.hash,
            bucket: 'Gauntlets',
            location: 'character',
            power: 1995,
            gearTier: 5,
            statValues: const {
              'Health': 40,
              'Melee': 50,
              'Grenade': 20,
              'Super': 25,
              'Class': 22,
              'Weapons': 18,
              'energyUsed': 5,
              'energyCapacity': 10,
            },
            plugHashes: const [7001],
            syncedAt: '2026-08-01T00:00:00.000Z',
          ),
        ],
      );

      services = await HostBootstrap.open(
        storageRoot: root,
        database: db,
        manifestRefresh: _FakeRefresh(),
        offlineCatalog: OfflineCatalog.preloaded(
          storageRoot: root,
          items: kArmorFixtureItems,
          version: 'armor-smoke-owned',
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
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('owned detail dual boards; unowned omits live/mods',
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

      await tester.tap(find.byKey(const Key('mode_chip_armor')));
      await _pumpFrames(tester);

      expect(
        find.byKey(Key('owned_badge_${kArmorSynthoceps.hash}')),
        findsOneWidget,
      );

      await tester.tap(itemKey(kArmorSynthoceps.hash));
      await _pumpFrames(tester);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('catalog_detail_pane')), findsOneWidget);
      expect(find.byKey(const Key('armor_instance_strip')), findsOneWidget);
      expect(find.byKey(const Key('armor_base_live_stat_board')), findsOneWidget);
      expect(find.byKey(const Key('catalog_toggle_can_roll')), findsNothing);
      expect(find.byKey(const Key('catalog_stub_set')), findsOneWidget);

      await tester.tap(itemKey(kArmorFieldPlate.hash));
      await _pumpFrames(tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('armor_instance_strip')), findsNothing);
      expect(find.byKey(const Key('armor_mods_energy_block')), findsNothing);
      expect(find.byKey(const Key('armor_live_board')), findsNothing);
    });
  });
}
