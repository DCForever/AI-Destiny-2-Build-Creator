import 'dart:convert';
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
import 'package:destiny2_windows_host/dim_export/dim_export_controller.dart';
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
  late List<String> clipboardLog;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dart039_dim_');
    final root = StorageRoot(basePath: tempDir.path);
    await root.ensureLayout();
    db = AppDatabase.memory();
    tokenStore = MemoryTokenStore();
    profile = FakeProfileClient();
    clipboardLog = <String>[];

    services = await HostBootstrap.open(
      storageRoot: root,
      database: db,
      manifestRefresh: _FakeRefresh(),
      offlineCatalog: OfflineCatalog.preloaded(
        storageRoot: root,
        items: const [],
        version: 'fixture-dim-1',
      ),
      clientId: 'test-client',
      tokenStore: tokenStore,
      browserLauncher: FakeBrowserLauncher(),
      profileClient: profile,
      writeClient: createMockWriteClient(),
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

  Future<({BuildsLibraryController builds, DimExportController dim})>
      pumpPage(WidgetTester tester) async {
    final builds = BuildsLibraryController(
      db: services.db,
      session: services.oauthSession,
      inventorySync: services.inventorySync,
    );
    final dim = DimExportController(
      db: services.db,
      clipboardWriter: (text) async {
        clipboardLog.add(text);
      },
      loadoutIdFactory: () => 'test-loadout-id',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: BuildsLibraryPage(
          key: const Key('builds_library_page'),
          services: services,
          controller: builds,
          dimExportController: dim,
        ),
      ),
    );
    await _pumpFrames(tester);
    return (builds: builds, dim: dim);
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
  }) async {
    await replaceInventoryBatch(
      services.db,
      userId,
      items: [
        InventoryItemRecord(
          instanceId: instanceId,
          itemHash: itemHash,
          bucket: 'Kinetic',
          location: 'vault',
          characterId: null,
          syncedAt: '2026-07-25T12:00:00.000Z',
        ),
      ],
      now: '2026-07-25T12:00:00.000Z',
    );
  }

  testWidgets('panel renders; wishlist not equip-ready blocks export',
      (tester) async {
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
    await tester.pump(const Duration(milliseconds: 100));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('dim_export_panel')), findsOneWidget);
    expect(ctx.dim.equipReady, isFalse);
    expect(find.byKey(const Key('dim_export_ready_summary')), findsOneWidget);
    expect(find.textContaining('export blocked'), findsWidgets);

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('dim_export_copy_button')),
    );
    expect(button.onPressed, isNull);

    final blocked = await ctx.dim.requestExport();
    expect(blocked, isNotNull);
    expect(clipboardLog, isEmpty);
    expect(ctx.dim.clipboardWrites, 0);

    ctx.builds.dispose();
    ctx.dim.dispose();
  });

  testWidgets('owned pin equip-ready exports jsonOnly to clipboard',
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

    expect(ctx.dim.equipReady, isTrue, reason: ctx.dim.error);
    expect(ctx.dim.canExport, isTrue);

    final err = await ctx.dim.requestExport();
    expect(err, isNull, reason: ctx.dim.error);
    expect(clipboardLog, hasLength(1));
    expect(ctx.dim.clipboardWrites, 1);
    expect(ctx.dim.statusMessage, contains('Copied'));

    final decoded = jsonDecode(clipboardLog.single) as Map<String, dynamic>;
    expect(decoded.containsKey('loadout'), isTrue);
    final loadout = decoded['loadout'] as Map<String, dynamic>;
    expect(loadout['id'], 'test-loadout-id');
    expect(loadout['classType'], 1); // Hunter
    final equipped = loadout['equipped'] as List<dynamic>;
    expect(equipped, isNotEmpty);
    expect(equipped.first['hash'], 100);
    expect(equipped.first['id'], 'inst-primary');

    await _pumpFrames(tester);
    expect(find.byKey(const Key('dim_export_json_preview')), findsOneWidget);
    expect(find.byKey(const Key('dim_export_status_message')), findsOneWidget);

    ctx.builds.dispose();
    ctx.dim.dispose();
  });

  testWidgets('soft advisory caption present', (tester) async {
    final ctx = await pumpPage(tester);
    await ctx.builds.createBuild(
      name: 'Soft',
      className: GuardianClass.titan,
      synergyTypes: const [DraftSynergyType(type: 'melee')],
    );
    await _pumpFrames(tester);
    expect(find.byKey(const Key('dim_export_soft_advisory')), findsOneWidget);
    expect(find.textContaining('never auto-apply'), findsWidgets);
    ctx.builds.dispose();
    ctx.dim.dispose();
  });
}
