import 'dart:io';

import 'package:destiny2_app/destiny2_app.dart';
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
import 'package:flutter_test/flutter_test.dart';

import 'catalog_roll_targets_fixtures.dart';
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
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppServices services;
  late AppDatabase db;
  late int userId;
  late OwnedCatalogBridge bridge;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('roll_targets_smoke_');
    final root = StorageRoot(basePath: tempDir.path);
    await root.ensureLayout();
    db = AppDatabase.memory();
    final now = DateTime.now().toUtc();
    final tokenStore = MemoryTokenStore();
    await seedSignedIn(tokenStore, membershipId: 'bungie-rt-smoke');

    services = await HostBootstrap.open(
      storageRoot: root,
      database: db,
      manifestRefresh: _FakeRefresh(),
      offlineCatalog: OfflineCatalog.preloaded(
        storageRoot: root,
        items: rollTargetCatalogItems(),
        version: 'roll-targets-smoke',
        perkColumnsByHash: rollTargetPerkColumns(),
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
      db,
      bungieMembershipId: 'bungie-rt-smoke',
      membershipType: 3,
      displayName: 'RT Smoke',
    );
    userId = user.id;
    await replaceInventoryBatch(
      db,
      userId,
      now: now.toIso8601String(),
      items: rollTargetInventoryItems(syncedAt: now.toIso8601String()),
    );

    bridge = OwnedCatalogBridge(
      db: db,
      offlineCatalog: services.offlineCatalog,
      session: services.oauthSession,
      inventorySync: services.inventorySync,
      plugNameByHash: kRollTargetPlugNames,
      plugNameMapBuilder: (hashes) async => {
        for (final h in hashes)
          if (kRollTargetPlugNames.containsKey(h)) h: kRollTargetPlugNames[h]!,
      },
    );
  });

  tearDown(() async {
    await services.dispose();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> pumpCatalog(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: testMaterialTheme(),
        home: CatalogPage(services: services, bridge: bridge),
      ),
    );
    await _pumpFrames(tester);
  }

  testWidgets(
      'host-fixture: list/setActive/rank + dual segs; Off clears; soft overlap',
      (tester) async {
    // Seed named profile + active.
    await createWeaponRollTarget(
      db,
      userId: userId,
      weaponKey: '$kRollTargetWeaponHash',
      name: 'PvE',
      columns: rollTargetPveColumns(),
      id: 'rt-pve-fixture',
    );
    await setActiveWeaponRollTarget(
      db,
      userId: userId,
      weaponKey: '$kRollTargetWeaponHash',
      targetId: 'rt-pve-fixture',
    );

    await pumpCatalog(tester);

    // Open owned weapon detail.
    final itemFinder =
        find.byKey(const Key('catalog_item_$kRollTargetWeaponHash'));
    expect(itemFinder, findsOneWidget);
    await tester.tap(itemFinder);
    await _pumpFrames(tester);

    expect(find.byKey(const Key('catalog_roll_targets')), findsOneWidget);
    expect(find.text('PVE'), findsOneWidget);
    expect(find.byKey(const Key('roll_target_opt_off')), findsOneWidget);

    // Dual segs: roll quality on scored sockets (equipped + reusables).
    // Perfect fixture: 3 ideal plugs of 6 on barrel/mag/trait → 3/6.
    expect(find.byKey(const Key('instance_score_pref_rt-perfect')), findsOneWidget);
    expect(find.text('3/6'), findsOneWidget);
    expect(find.byKey(const Key('weapon_instance_rank_note')), findsOneWidget);

    // Rank: perfect (ratio 1) before partial (higher power) before dirty.
    // Reading order = top-left first (chips may wrap).
    int readOrder(Offset a, Offset b) {
      final dy = a.dy.compareTo(b.dy);
      if (dy != 0) return dy;
      return a.dx.compareTo(b.dx);
    }

    final perfectPos =
        tester.getTopLeft(find.byKey(const Key('instance_chip_rt-perfect')));
    final partialPos =
        tester.getTopLeft(find.byKey(const Key('instance_chip_rt-partial')));
    final dirtyPos =
        tester.getTopLeft(find.byKey(const Key('instance_chip_rt-dirty')));
    expect(readOrder(perfectPos, partialPos), lessThan(0));
    expect(readOrder(partialPos, dirtyPos), lessThan(0));

    // Base chip power/tier preserved (no MW/Craft; no ChoiceChip score chrome).
    expect(find.text('T3'), findsWidgets);
    expect(find.textContaining('MW'), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);

    // Off clears dual segs + power-desc order note gone.
    await tester.tap(find.byKey(const Key('roll_target_opt_off')));
    await _pumpFrames(tester);
    expect(find.byKey(const Key('instance_score_pref_rt-perfect')), findsNothing);
    expect(find.byKey(const Key('weapon_instance_rank_note')), findsNothing);

    // Power-desc: partial 450 before dirty 420 before perfect 400.
    final pOff =
        tester.getTopLeft(find.byKey(const Key('instance_chip_rt-partial')));
    final dirtyOff =
        tester.getTopLeft(find.byKey(const Key('instance_chip_rt-dirty')));
    final perfectOff =
        tester.getTopLeft(find.byKey(const Key('instance_chip_rt-perfect')));
    expect(readOrder(pOff, dirtyOff), lessThan(0));
    expect(readOrder(dirtyOff, perfectOff), lessThan(0));

    // Re-activate + open editor + force soft overlap via cycle.
    await tester.tap(find.byKey(const Key('roll_target_opt_rt-pve-fixture')));
    await _pumpFrames(tester);
    await tester.tap(find.byKey(const Key('roll_target_edit')));
    await _pumpFrames(tester);
    expect(find.byKey(const Key('catalog_roll_target_editor')), findsOneWidget);
    expect(find.byKey(const Key('catalog_perk_grid_editing')), findsOneWidget);

    // Soft scores never remove outbound stubs (DBR-IDL-008); may be offstage
    // in ListView when editor is open — scroll/search skipOffstage.
    final stubFinder =
        find.byKey(const Key('catalog_stub_set'), skipOffstage: false);
    expect(stubFinder, findsOneWidget);
    await tester.ensureVisible(stubFinder);
    await _pumpFrames(tester);
    final setBtn = tester.widget<FilledButton>(stubFinder);
    // Deferred disabled — still present; soft overlap never gates equip path.
    expect(setBtn.onPressed, isNull);
  });

  testWidgets('unowned: definition pool editor; no dual chips', (tester) async {
    await pumpCatalog(tester);
    final itemFinder =
        find.byKey(const Key('catalog_item_$kRollTargetUnownedHash'));
    expect(itemFinder, findsOneWidget);
    await tester.tap(itemFinder);
    await _pumpFrames(tester);

    expect(find.byKey(const Key('instance_panel_empty')), findsOneWidget);
    expect(find.textContaining('No local copies'), findsOneWidget);
    expect(find.byKey(const Key('weapon_instance_strip')), findsNothing);
    expect(find.byKey(const Key('catalog_roll_targets')), findsOneWidget);
    expect(find.byKey(const Key('instance_score_pref_rt-perfect')), findsNothing);

    await tester.tap(find.byKey(const Key('roll_target_new')));
    await _pumpFrames(tester);
    expect(find.byKey(const Key('catalog_roll_target_editor')), findsOneWidget);
  });
}
