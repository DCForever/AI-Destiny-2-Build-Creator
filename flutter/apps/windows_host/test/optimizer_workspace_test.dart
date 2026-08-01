import 'dart:io';

import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
import 'package:destiny2_windows_host/optimizer/optimizer_controller.dart';
import 'package:destiny2_windows_host/optimizer/optimizer_format.dart';
import 'package:destiny2_windows_host/optimizer/optimizer_workspace.dart';
import 'package:destiny2_windows_host/sets/sets_library_controller.dart';
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

CandidatePiece _piece({
  required EquipmentSlot slot,
  required int itemHash,
  required String instanceId,
  Map<ArmorStatName, int>? stats,
}) {
  return CandidatePiece(
    slot: slot,
    itemHash: itemHash,
    instanceId: instanceId,
    itemName: 'Item $itemHash',
    isExotic: false,
    statValues: stats ??
        const {
          ArmorStatName.health: 10,
          ArmorStatName.melee: 10,
          ArmorStatName.grenade: 10,
          ArmorStatName.superStat: 10,
          ArmorStatName.classStat: 10,
          ArmorStatName.weapons: 10,
        },
  );
}

List<CandidatePiece> fixtureBoard() => [
      _piece(slot: EquipmentSlot.helmet, itemHash: 101, instanceId: 'h1'),
      _piece(slot: EquipmentSlot.helmet, itemHash: 111, instanceId: 'h2'),
      _piece(slot: EquipmentSlot.arms, itemHash: 102, instanceId: 'a1'),
      _piece(slot: EquipmentSlot.chest, itemHash: 103, instanceId: 'c1'),
      _piece(slot: EquipmentSlot.legs, itemHash: 104, instanceId: 'l1'),
      _piece(
        slot: EquipmentSlot.classItem,
        itemHash: 105,
        instanceId: 'ci1',
      ),
    ];

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

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dart036_opt_');
    final root = StorageRoot(basePath: tempDir.path);
    await root.ensureLayout();
    final db = AppDatabase.memory();
    final tokenStore = MemoryTokenStore();

    services = await HostBootstrap.open(
      storageRoot: root,
      database: db,
      manifestRefresh: _FakeRefresh(),
      offlineCatalog: OfflineCatalog.preloaded(
        storageRoot: root,
        items: const [],
        version: 'fixture-opt-1',
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

  Future<
      ({
        SetsLibraryController sets,
        OptimizerController optimizer,
      })> pumpSetsWithOptimizer(WidgetTester tester) async {
    final sets = SetsLibraryController(
      db: services.db,
      session: services.oauthSession,
      inventorySync: services.inventorySync,
    );
    final optimizer = OptimizerController(
      db: services.db,
      resolveUserId: () => sets.resolveLibraryUserId(),
      optimizeRunner: (req) async => optimizeArmorLocal(req),
      initialCandidates: fixtureBoard(),
      initialHasInventory: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: SetsLibraryPage(
          key: const Key('sets_library_page'),
          services: services,
          controller: sets,
          optimizerController: optimizer,
        ),
      ),
    );
    await _pumpFrames(tester);
    return (sets: sets, optimizer: optimizer);
  }

  group('US1 Find kits never writes', () {
    testWidgets('advisory caption present on armor set', (tester) async {
      final pair = await pumpSetsWithOptimizer(tester);
      final uid = await pair.sets.resolveLibraryUserId();
      await createUserSet(
        services.db,
        uid,
        const CreateSetCommand(
          id: 'armor-1',
          name: 'Empty Armor',
          type: SetType.armor,
        ),
      );
      await pair.sets.refresh(keepSelection: false);
      await pair.sets.selectSet('armor-1');
      await _pumpFrames(tester);

      expect(find.byKey(const Key('optimizer_workspace')), findsOneWidget);
      expect(find.byKey(const Key('optimizer_advisory')), findsOneWidget);
      expect(find.textContaining('never'), findsWidgets);
      expect(find.text(kOptimizerAdvisoryCaption), findsOneWidget);
    });

    testWidgets('Find kits shows suggestions without writing set items',
        (tester) async {
      final pair = await pumpSetsWithOptimizer(tester);
      final uid = await pair.sets.resolveLibraryUserId();
      await createUserSet(
        services.db,
        uid,
        const CreateSetCommand(
          id: 'armor-empty',
          name: 'Empty Armor',
          type: SetType.armor,
        ),
      );
      await pair.sets.refresh(keepSelection: false);
      await pair.sets.selectSet('armor-empty');
      await _pumpFrames(tester);

      // Scroll dual-pane detail so Find kits is hittable.
      await tester.ensureVisible(find.byKey(const Key('optimizer_find_kits')));
      await _pumpFrames(tester);
      await tester.tap(find.byKey(const Key('optimizer_find_kits')));
      await _pumpFrames(tester);
      await tester.pump(const Duration(milliseconds: 100));
      await _pumpFrames(tester);

      expect(pair.optimizer.combinations, isNotEmpty);
      await tester.ensureVisible(
        find.byKey(const Key('optimizer_suggestion_0')),
      );
      expect(find.byKey(const Key('optimizer_suggestion_0')), findsOneWidget);

      final detail = await getSetDetail(services.db, uid, 'armor-empty');
      expect(detail!.activeItems, isEmpty);
      expect(
        pair.optimizer.status,
        contains('nothing written yet'),
      );
    });

    testWidgets('weapon set hides optimizer workspace', (tester) async {
      final pair = await pumpSetsWithOptimizer(tester);
      final uid = await pair.sets.resolveLibraryUserId();
      await createUserSet(
        services.db,
        uid,
        const CreateSetCommand(
          id: 'wep-1',
          name: 'Guns',
          type: SetType.weapon,
        ),
      );
      await pair.sets.refresh(keepSelection: false);
      await pair.sets.selectSet('wep-1');
      await _pumpFrames(tester);

      expect(find.byKey(const Key('optimizer_workspace')), findsNothing);
    });
  });

  group('US2 confirm apply / cancel', () {
    testWidgets('cancel confirm leaves set unchanged', (tester) async {
      final pair = await pumpSetsWithOptimizer(tester);
      final uid = await pair.sets.resolveLibraryUserId();
      await createUserSet(
        services.db,
        uid,
        const CreateSetCommand(
          id: 'armor-cancel',
          name: 'Cancel Armor',
          type: SetType.armor,
        ),
      );
      await pair.sets.refresh(keepSelection: false);
      await pair.sets.selectSet('armor-cancel');
      await _pumpFrames(tester);

      // Drive find via controller (no write), then confirm UI path.
      await pair.optimizer.findKits();
      await _pumpFrames(tester);
      expect(pair.optimizer.combinations, isNotEmpty);

      final detailBefore =
          await getSetDetail(services.db, uid, 'armor-cancel');
      expect(detailBefore!.activeItems, isEmpty);

      await tester.ensureVisible(find.byKey(const Key('optimizer_apply_0')));
      await tester.tap(find.byKey(const Key('optimizer_apply_0')));
      await _pumpFrames(tester);
      expect(find.byKey(const Key('optimizer_confirm_dialog')), findsOneWidget);

      await tester.tap(find.byKey(const Key('optimizer_confirm_cancel')));
      await _pumpFrames(tester);

      final detail = await getSetDetail(services.db, uid, 'armor-cancel');
      expect(detail!.activeItems, isEmpty);
      expect(pair.optimizer.pending, isNull);
      expect(pair.optimizer.status, contains('unchanged'));
    });

    testWidgets('confirm apply writes five armor slots', (tester) async {
      final pair = await pumpSetsWithOptimizer(tester);
      final uid = await pair.sets.resolveLibraryUserId();
      await createUserSet(
        services.db,
        uid,
        const CreateSetCommand(
          id: 'armor-apply',
          name: 'Apply Armor',
          type: SetType.armor,
        ),
      );
      await pair.sets.refresh(keepSelection: false);
      await pair.sets.selectSet('armor-apply');
      await _pumpFrames(tester);

      await pair.optimizer.findKits();
      await _pumpFrames(tester);

      // Pre-confirm: still empty
      var detail = await getSetDetail(services.db, uid, 'armor-apply');
      expect(detail!.activeItems, isEmpty);

      await tester.ensureVisible(find.byKey(const Key('optimizer_apply_0')));
      await tester.tap(find.byKey(const Key('optimizer_apply_0')));
      await _pumpFrames(tester);

      await tester.tap(find.byKey(const Key('optimizer_confirm_accept')));
      await _pumpFrames(tester);
      await tester.pump(const Duration(milliseconds: 100));
      await _pumpFrames(tester);

      detail = await getSetDetail(services.db, uid, 'armor-apply');
      expect(detail!.activeItems, hasLength(5));
      final slots = detail.activeItems.map((i) => i.slot).toSet();
      expect(slots, {
        'helmet',
        'arms',
        'chest',
        'legs',
        'class_item',
      });
      expect(pair.optimizer.status, contains('Applied'));
    });

    test('controller confirm-only: findKits does not write; confirm does',
        () async {
      final sets = SetsLibraryController(
        db: services.db,
        session: services.oauthSession,
        inventorySync: services.inventorySync,
      );
      final optimizer = OptimizerController(
        db: services.db,
        resolveUserId: () => sets.resolveLibraryUserId(),
        optimizeRunner: (req) async => optimizeArmorLocal(req),
        initialCandidates: fixtureBoard(),
        initialHasInventory: true,
      );
      final uid = await sets.resolveLibraryUserId();
      await createUserSet(
        services.db,
        uid,
        const CreateSetCommand(
          id: 'armor-ctrl',
          name: 'Ctrl Armor',
          type: SetType.armor,
        ),
      );
      optimizer.bindTargetSet(setId: 'armor-ctrl', setName: 'Ctrl Armor');

      await optimizer.findKits();
      expect(optimizer.combinations, isNotEmpty);
      var detail = await getSetDetail(services.db, uid, 'armor-ctrl');
      expect(detail!.activeItems, isEmpty);

      final stageErr = optimizer.requestApplyInPlace(0);
      expect(stageErr, isNull);
      expect(optimizer.pending, isNotNull);

      // Cancel path
      optimizer.cancelPending();
      detail = await getSetDetail(services.db, uid, 'armor-ctrl');
      expect(detail!.activeItems, isEmpty);

      optimizer.requestApplyInPlace(0);
      final applyErr = await optimizer.confirmPending();
      expect(applyErr, isNull);
      detail = await getSetDetail(services.db, uid, 'armor-ctrl');
      expect(detail!.activeItems, hasLength(5));

      optimizer.dispose();
      sets.dispose();
    });

    test('apply with userId 0 fails; library resolveUserId succeeds', () async {
      // BUG-20260726-015: Finish embed used localUserId ?? 0 → Armor set not found.
      final sets = SetsLibraryController(
        db: services.db,
        session: services.oauthSession,
        inventorySync: services.inventorySync,
      );
      final uid = await sets.resolveLibraryUserId();
      await createUserSet(
        services.db,
        uid,
        const CreateSetCommand(
          id: 'armor-uid',
          name: 'Uid Armor',
          type: SetType.armor,
        ),
      );

      final bad = OptimizerController(
        db: services.db,
        resolveUserId: () async => 0,
        optimizeRunner: (req) async => optimizeArmorLocal(req),
        initialCandidates: fixtureBoard(),
        initialHasInventory: true,
      );
      bad.bindTargetSet(setId: 'armor-uid', setName: 'Uid Armor');
      await bad.findKits();
      expect(bad.combinations, isNotEmpty);
      bad.requestApplyInPlace(0);
      expect(await bad.confirmPending(), 'Armor set not found');
      bad.dispose();

      final good = OptimizerController(
        db: services.db,
        resolveUserId: () => sets.resolveLibraryUserId(),
        optimizeRunner: (req) async => optimizeArmorLocal(req),
        initialCandidates: fixtureBoard(),
        initialHasInventory: true,
      );
      good.bindTargetSet(setId: 'armor-uid', setName: 'Uid Armor');
      await good.findKits();
      good.requestApplyInPlace(0);
      expect(await good.confirmPending(), isNull);
      final detail = await getSetDetail(services.db, uid, 'armor-uid');
      expect(detail!.activeItems, hasLength(5));
      good.dispose();
      sets.dispose();
    });
  });

  group('US3 soft never auto-apply', () {
    test('requireThresholds toggle alone does not write', () async {
      final sets = SetsLibraryController(
        db: services.db,
        session: services.oauthSession,
        inventorySync: services.inventorySync,
      );
      final optimizer = OptimizerController(
        db: services.db,
        resolveUserId: () => sets.resolveLibraryUserId(),
        optimizeRunner: (req) async => optimizeArmorLocal(req),
        initialCandidates: fixtureBoard(),
        initialHasInventory: true,
      );
      final uid = await sets.resolveLibraryUserId();
      await createUserSet(
        services.db,
        uid,
        const CreateSetCommand(
          id: 'armor-soft',
          name: 'Soft Armor',
          type: SetType.armor,
        ),
      );
      optimizer.bindTargetSet(setId: 'armor-soft', setName: 'Soft Armor');
      optimizer.setRequireThresholds(true);
      optimizer.setPreferReuse(true);
      // No findKits, no confirm
      final detail = await getSetDetail(services.db, uid, 'armor-soft');
      expect(detail!.activeItems, isEmpty);
      expect(optimizer.combinations, isEmpty);
      optimizer.dispose();
      sets.dispose();
    });

    testWidgets('empty candidates surfaces empty guidance without write',
        (tester) async {
      final sets = SetsLibraryController(
        db: services.db,
        session: services.oauthSession,
        inventorySync: services.inventorySync,
      );
      final optimizer = OptimizerController(
        db: services.db,
        resolveUserId: () => sets.resolveLibraryUserId(),
        optimizeRunner: (req) async => optimizeArmorLocal(req),
        initialCandidates: const [],
        initialHasInventory: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildFlapTheme(),
          home: Scaffold(
            body: OptimizerWorkspace(controller: optimizer),
          ),
        ),
      );
      await _pumpFrames(tester);

      await tester.tap(find.byKey(const Key('optimizer_find_kits')));
      await _pumpFrames(tester);
      await tester.pump(const Duration(milliseconds: 50));
      await _pumpFrames(tester);

      expect(optimizer.combinations, isEmpty);
      expect(optimizer.status, isNotNull);
      expect(
        optimizer.status!.toUpperCase(),
        anyOf(contains('NO_INVENTORY'), contains('NO_')),
      );

      final uid = await sets.resolveLibraryUserId();
      final listed = await listUserSets(services.db, uid);
      expect(listed, isEmpty);

      optimizer.dispose();
      sets.dispose();
    });
  });
}
