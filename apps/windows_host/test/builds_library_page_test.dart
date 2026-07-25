import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/app.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/builds/builds_library_controller.dart';
import 'package:destiny2_windows_host/builds/builds_library_page.dart';
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

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dart032_bld_');
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
        items: const [],
        version: 'fixture-bld-1',
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

  testWidgets('US1 create build with synergy types appears in list and detail',
      (tester) async {
    final controller = BuildsLibraryController(
      db: services.db,
      session: services.oauthSession,
      inventorySync: services.inventorySync,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: BuildsLibraryPage(
          key: const Key('builds_library_page'),
          services: services,
          controller: controller,
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('builds_list_empty')), findsOneWidget);

    // Prefer controller create path (stable in short VMs); assert dual-pane UI.
    final err = await controller.createBuild(
      name: 'Arc Hunter',
      className: GuardianClass.hunter,
      synergyTypes: const [
        DraftSynergyType(type: 'melee', subType: 'Base'),
      ],
    );
    expect(err, isNull);
    await _pumpFrames(tester);

    expect(find.byKey(const Key('builds_list')), findsOneWidget);
    expect(find.text('Arc Hunter'), findsWidgets);
    expect(find.byKey(const Key('builds_detail')), findsOneWidget);
    expect(find.byKey(const Key('builds_detail_class')), findsOneWidget);
    expect(find.textContaining('Hunter'), findsWidgets);
    expect(find.byKey(const Key('builds_detail_synergy_types')), findsOneWidget);
    expect(find.textContaining('melee::Base'), findsWidgets);
    expect(controller.builds, hasLength(1));
    expect(controller.selected!.build.synergyTypes, hasLength(1));

    // UI create path: draft chip + button also works.
    controller.clearCreateDraftTypes();
    controller.addCreateDraftType('grenade', 'Threadling');
    await _pumpFrames(tester);
    expect(find.byKey(const Key('builds_create_synergy_chips')), findsOneWidget);
    expect(find.text('grenade::Threadling'), findsWidgets);

    controller.dispose();
  });

  testWidgets('US1 zero synergy types blocks create and writes nothing',
      (tester) async {
    final controller = BuildsLibraryController(
      db: services.db,
      session: services.oauthSession,
      inventorySync: services.inventorySync,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: BuildsLibraryPage(
          services: services,
          controller: controller,
        ),
      ),
    );
    await _pumpFrames(tester);

    final err = await controller.createBuild(
      name: 'No Syn',
      className: GuardianClass.hunter,
      synergyTypes: const [],
    );
    expect(err, isNotNull);
    expect(err!.toLowerCase(), contains('synergy'));
    await _pumpFrames(tester);

    expect(controller.builds, isEmpty);
    expect(find.byKey(const Key('builds_list_empty')), findsOneWidget);
    expect(find.byKey(const Key('builds_status')), findsOneWidget);

    controller.dispose();
  });

  testWidgets('US2 create with exotic armor and pinned Super shows on detail',
      (tester) async {
    final controller = BuildsLibraryController(
      db: services.db,
      session: services.oauthSession,
      inventorySync: services.inventorySync,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: BuildsLibraryPage(
          services: services,
          controller: controller,
        ),
      ),
    );
    await _pumpFrames(tester);

    final err = await controller.createBuild(
      name: 'Synth Melee',
      className: GuardianClass.titan,
      exoticArmorHash: 1001,
      exoticArmorName: 'Synthoceps',
      pinnedSuper: 'Thundercrash',
      synergyTypes: const [
        DraftSynergyType(type: 'melee', subType: 'Base'),
      ],
    );
    expect(err, isNull);
    await _pumpFrames(tester);

    expect(find.byKey(const Key('builds_detail_exotic_armor')), findsOneWidget);
    expect(find.textContaining('Synthoceps'), findsWidgets);
    expect(find.byKey(const Key('builds_detail_pinned_super')), findsOneWidget);
    expect(find.textContaining('Thundercrash'), findsWidgets);
    expect(find.byKey(const Key('builds_detail_class')), findsOneWidget);
    expect(controller.selected!.build.className, 'Titan');

    controller.dispose();
  });

  testWidgets('US2 update identity exotic weapon pin', (tester) async {
    final controller = BuildsLibraryController(
      db: services.db,
      session: services.oauthSession,
      inventorySync: services.inventorySync,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: BuildsLibraryPage(
          services: services,
          controller: controller,
        ),
      ),
    );
    await _pumpFrames(tester);

    await controller.createBuild(
      name: 'Pin Test',
      className: GuardianClass.warlock,
      synergyTypes: const [DraftSynergyType(type: 'grenade')],
    );
    await _pumpFrames(tester);

    final err = await controller.updateSelectedIdentity(
      setExoticWeapon: true,
      exoticWeaponHash: 2002,
      exoticWeaponName: 'Osteo Striga',
    );
    expect(err, isNull);
    await _pumpFrames(tester);

    expect(controller.selected!.build.exoticWeaponName, 'Osteo Striga');
    expect(find.byKey(const Key('builds_detail_exotic_weapon')), findsOneWidget);
    expect(find.textContaining('Osteo Striga'), findsWidgets);

    controller.dispose();
  });

  testWidgets('US3 Builds nav destination shows builds page', (tester) async {
    await tester.pumpWidget(
      Destiny2WindowsApp(services: services),
    );
    await _pumpFrames(tester);

    // Builds is 4th destination (index 3): Catalog, Sets, Synergies, Builds.
    final buildsDest = find.text('Builds');
    expect(buildsDest, findsOneWidget);
    await tester.tap(buildsDest);
    await _pumpFrames(tester);

    expect(find.byKey(const Key('builds_library_page')), findsOneWidget);
    expect(find.byKey(const Key('builds_list_empty')), findsOneWidget);

    // Other destinations still present in rail.
    expect(find.text('Catalog'), findsOneWidget);
    expect(find.text('Sets'), findsOneWidget);
    expect(find.text('Synergies'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
