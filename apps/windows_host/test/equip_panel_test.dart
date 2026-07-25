import 'dart:io';

import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/builds/builds_library_controller.dart';
import 'package:destiny2_windows_host/builds/builds_library_page.dart';
import 'package:destiny2_windows_host/equip/equip_controller.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppServices services;
  late AppDatabase db;
  late MemoryTokenStore tokenStore;
  late FakeProfileClient profile;
  late List<String> writeLog;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dart038_equip_');
    final root = StorageRoot(basePath: tempDir.path);
    await root.ensureLayout();
    db = AppDatabase.memory();
    tokenStore = MemoryTokenStore();
    profile = FakeProfileClient();
    writeLog = <String>[];

    services = await HostBootstrap.open(
      storageRoot: root,
      database: db,
      manifestRefresh: _FakeRefresh(),
      offlineCatalog: OfflineCatalog.preloaded(
        storageRoot: root,
        items: const [],
        version: 'fixture-equip-1',
      ),
      clientId: 'test-client',
      tokenStore: tokenStore,
      browserLauncher: FakeBrowserLauncher(),
      profileClient: profile,
      writeClient: createMockWriteClient(
        transferItem: (ctx, args) async {
          writeLog.add('transfer:${args.instanceId}');
        },
        equipItem: (ctx, args) async {
          writeLog.add('equip:${args.instanceId}');
        },
      ),
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

  Future<({BuildsLibraryController builds, EquipController equip})> pumpPage(
    WidgetTester tester, {
    bool signedIn = true,
  }) async {
    if (signedIn) {
      await seedSignedIn(tokenStore);
      await services.oauthSession.restore();
    }
    final builds = BuildsLibraryController(
      db: services.db,
      session: services.oauthSession,
      inventorySync: services.inventorySync,
    );
    final equip = EquipController(
      db: services.db,
      session: services.oauthSession,
      profileClient: services.profileClient,
      writeClient: services.writeClient,
      inventorySync: services.inventorySync,
      skipSyncIfStale: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: BuildsLibraryPage(
          key: const Key('builds_library_page'),
          services: services,
          controller: builds,
          equipController: equip,
        ),
      ),
    );
    await _pumpFrames(tester);
    return (builds: builds, equip: equip);
  }

  Future<void> seedWeaponSet(
    int userId,
    String setId,
    String slot,
    int hash, {
    String? instanceId,
  }) async {
    await createUserSet(
      services.db,
      userId,
      CreateSetCommand(id: setId, name: 'Set $setId', type: SetType.weapon),
    );
    await upsertUserSetItem(
      services.db,
      userId,
      setId,
      UpsertSetItemCommand(
        id: '$setId-item',
        slot: slot,
        itemHash: hash,
        itemName: 'Item $hash',
        instanceId: instanceId,
      ),
    );
  }

  Future<void> seedInventory(
    int userId, {
    required String instanceId,
    required int itemHash,
    String location = 'vault',
    String? characterId,
  }) async {
    await replaceInventoryBatch(
      services.db,
      userId,
      items: [
        InventoryItemRecord(
          instanceId: instanceId,
          itemHash: itemHash,
          bucket: 'Kinetic',
          location: location,
          characterId: characterId,
          syncedAt: '2026-07-25T12:00:00.000Z',
        ),
      ],
      now: '2026-07-25T12:00:00.000Z',
    );
  }

  testWidgets('signed out shows sign-in hint; Apply disabled', (tester) async {
    final ctx = await pumpPage(tester, signedIn: false);
    await ctx.builds.createBuild(
      name: 'Local',
      className: GuardianClass.hunter,
      synergyTypes: const [DraftSynergyType(type: 'melee')],
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('equip_panel')), findsOneWidget);
    expect(find.byKey(const Key('equip_sign_in_hint')), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('equip_apply_button')),
    );
    expect(button.onPressed, isNull);
    expect(writeLog, isEmpty);

    ctx.builds.dispose();
    ctx.equip.dispose();
  });

  testWidgets('wishlist pin is not equip-ready; Apply blocked', (tester) async {
    final ctx = await pumpPage(tester);
    await ctx.builds.createBuild(
      name: 'Wish',
      className: GuardianClass.hunter,
      synergyTypes: const [DraftSynergyType(type: 'melee')],
    );
    await _pumpFrames(tester);
    final uid = ctx.builds.userId!;
    await seedWeaponSet(uid, 'w1', 'primary', 100);
    await ctx.builds.refresh();
    await ctx.builds.createVariant(name: 'Alt');
    await _pumpFrames(tester);
    await ctx.builds.attachSet('w1');
    await _pumpFrames(tester);

    // Wait equip bind.
    await tester.pump(const Duration(milliseconds: 100));
    await _pumpFrames(tester);

    expect(ctx.equip.equipReady, isFalse);
    expect(find.byKey(const Key('equip_ready_summary')), findsOneWidget);
    expect(find.textContaining('Not equip-ready'), findsWidgets);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('equip_apply_button')),
    );
    expect(button.onPressed, isNull);

    final blocked = await ctx.equip.requestEquip();
    expect(blocked, isNotNull);
    expect(writeLog, isEmpty);

    ctx.builds.dispose();
    ctx.equip.dispose();
  });

  testWidgets(
      'owned pin equip-ready → gaps confirm cancel prevents write; confirm equips',
      (tester) async {
    final ctx = await pumpPage(tester);
    await ctx.builds.createBuild(
      name: 'Ready',
      className: GuardianClass.hunter,
      synergyTypes: const [DraftSynergyType(type: 'melee')],
    );
    await _pumpFrames(tester);
    final uid = ctx.builds.userId!;
    await seedWeaponSet(uid, 'w1', 'primary', 100, instanceId: 'inst-primary');
    await seedInventory(uid, instanceId: 'inst-primary', itemHash: 100);
    await ctx.builds.refresh();
    await ctx.builds.createVariant(name: 'Alt');
    await _pumpFrames(tester);
    await ctx.builds.attachSet('w1');
    await _pumpFrames(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await _pumpFrames(tester);

    expect(ctx.equip.equipReady, isTrue, reason: ctx.equip.error);
    expect(ctx.equip.emptyCombatSlots, isNotEmpty);

    // Select hunter character.
    ctx.equip.selectCharacter('char-hunter');
    await _pumpFrames(tester);
    expect(ctx.equip.canApply, isTrue);

    // Request equip → gaps confirm pending (empty combat slots).
    final r = await ctx.equip.requestEquip();
    expect(r, isNull);
    expect(ctx.equip.pendingGaps, isNotNull);
    expect(writeLog, isEmpty);

    // Cancel.
    ctx.equip.cancelGapsConfirm();
    expect(ctx.equip.pendingGaps, isNull);
    expect(writeLog, isEmpty);

    // Confirm path via force (simulates dialog OK without dialog flakiness).
    final r2 = await ctx.equip.requestEquip(forceGapsConfirm: true);
    expect(r2, isNull, reason: ctx.equip.error);
    expect(writeLog, isNotEmpty);
    expect(writeLog.any((e) => e.startsWith('equip:')), isTrue);
    expect(ctx.equip.lastStatus, isNotNull);
    expect(ctx.equip.lastStatus!.completed, greaterThan(0));
    await _pumpFrames(tester);
    expect(find.byKey(const Key('equip_step_report_summary')), findsOneWidget);

    ctx.builds.dispose();
    ctx.equip.dispose();
  });

  testWidgets('class mismatch matching list empty for wrong class',
      (tester) async {
    final ctx = await pumpPage(tester);
    // Only titan/hunter in fake profile; use warlock build.
    await ctx.builds.createBuild(
      name: 'Warlock only',
      className: GuardianClass.warlock,
      synergyTypes: const [DraftSynergyType(type: 'melee')],
    );
    await _pumpFrames(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await _pumpFrames(tester);

    expect(ctx.equip.matchingCharacters, isEmpty);
    expect(find.byKey(const Key('equip_no_matching_class')), findsOneWidget);

    ctx.builds.dispose();
    ctx.equip.dispose();
  });
}
