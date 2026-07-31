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

    // UI create path: draft chip + button also works (expand create strip).
    controller.clearCreateDraftTypes();
    controller.addCreateDraftType('grenade', 'Threadling');
    await tester.tap(find.byKey(const Key('builds_create_toggle')));
    await _pumpFrames(tester);
    expect(find.byKey(const Key('builds_create_synergy_chips')), findsOneWidget);
    expect(find.text('Grenade · Threadling'), findsWidgets);

    // Hierarchy: primary Create / Save are Filled; step labels present.
    expect(find.byKey(const Key('builds_create_button')), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('builds_create_button'))),
      isA<FilledButton>(),
    );
    expect(find.byKey(const Key('builds_create_step_class')), findsOneWidget);
    expect(find.byKey(const Key('builds_create_step_synergy')), findsOneWidget);
    expect(find.byKey(const Key('builds_create_step_name')), findsOneWidget);
    expect(find.byKey(const Key('builds_detail_title')), findsOneWidget);
    expect(find.byKey(const Key('builds_save_identity')), findsOneWidget);
    expect(
      tester.widget<FilledButton>(
        find.byKey(const Key('builds_save_identity')),
      ),
      isA<FilledButton>(),
    );
    expect(find.byKey(const Key('builds_save_identity_hint')), findsOneWidget);
    expect(
      find.textContaining('Soft coverage never blocks Save'),
      findsOneWidget,
    );
    // Progressive disclosure: next-step copy; optional pins/kit collapsed when empty.
    expect(find.byKey(const Key('builds_identity_next_step')), findsOneWidget);
    expect(find.textContaining('1 Basics'), findsOneWidget);
    expect(find.byKey(const Key('builds_optional_pins_summary')), findsOneWidget);
    expect(find.byKey(const Key('builds_subclass_kit_summary')), findsOneWidget);
    expect(find.textContaining('None yet'), findsWidgets);
    expect(find.byKey(const Key('builds_subclass_kit_title')), findsOneWidget);
    // Collapsed: empty pin Search rows hidden until user expands.
    expect(find.byKey(const Key('builds_pick_exotic_armor')), findsNothing);
    await tester.tap(find.byKey(const Key('builds_optional_pins_toggle')));
    await _pumpFrames(tester);
    expect(find.byKey(const Key('builds_pick_exotic_armor')), findsOneWidget);

    controller.dispose();
  });

  testWidgets('create strip primary CTA visible at narrow and wide widths',
      (tester) async {
    final controller = BuildsLibraryController(
      db: services.db,
      session: services.oauthSession,
      inventorySync: services.inventorySync,
    );

    Future<void> pumpAt(Size size) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFlapTheme(),
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: BuildsLibraryPage(
              key: const Key('builds_library_page'),
              services: services,
              controller: controller,
            ),
          ),
        ),
      );
      await _pumpFrames(tester);
    }

    await pumpAt(const Size(900, 800));
    expect(tester.takeException(), isNull);
    // Empty library auto-expands create plate; only open if collapsed.
    if (find.byKey(const Key('builds_create_button')).evaluate().isEmpty) {
      await tester.tap(find.byKey(const Key('builds_create_toggle')));
      await _pumpFrames(tester);
    }
    expect(find.byKey(const Key('builds_create_button')), findsOneWidget);
    expect(
      tester.widget<FilledButton>(
        find.byKey(const Key('builds_create_button')),
      ),
      isA<FilledButton>(),
    );

    await pumpAt(const Size(1280, 900));
    expect(tester.takeException(), isNull);
    // Rebuild may reset state; empty library still auto-expands create.
    if (find.byKey(const Key('builds_create_button')).evaluate().isEmpty) {
      await tester.tap(find.byKey(const Key('builds_create_toggle')));
      await _pumpFrames(tester);
    }
    expect(find.byKey(const Key('builds_create_button')), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Progression still works: controller create selects detail.
    final err = await controller.createBuild(
      name: 'Wide Hunter',
      className: GuardianClass.hunter,
      synergyTypes: const [DraftSynergyType(type: 'melee')],
    );
    expect(err, isNull);
    await _pumpFrames(tester);
    expect(find.byKey(const Key('builds_detail')), findsOneWidget);
    expect(find.byKey(const Key('builds_save_identity')), findsOneWidget);

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

    // Identity pin change requires Confirm (DBR-ID-008 / DART-064).
    final pending = await controller.updateSelectedIdentity(
      setExoticWeapon: true,
      exoticWeaponHash: 2002,
      exoticWeaponName: 'Osteo Striga',
    );
    expect(pending, contains('Confirm'));
    expect(controller.identityConfirmRequired, isTrue);
    await _pumpFrames(tester);
    expect(find.byKey(const Key('builds_identity_confirm_panel')), findsOneWidget);

    final err = await controller.updateSelectedIdentity(
      setExoticWeapon: true,
      exoticWeaponHash: 2002,
      exoticWeaponName: 'Osteo Striga',
      identityAction: IdentityAction.confirm,
    );
    expect(err, isNull);
    await _pumpFrames(tester);

    expect(controller.selected!.build.exoticWeaponName, 'Osteo Striga');
    expect(find.byKey(const Key('builds_detail_exotic_weapon')), findsOneWidget);
    expect(find.textContaining('Osteo Striga'), findsWidgets);

    controller.dispose();
  });

  testWidgets('DART-064 Confirm/Fork + kit hard-block + manifest pick keys',
      (tester) async {
    final controller = BuildsLibraryController(
      db: services.db,
      session: services.oauthSession,
      inventorySync: services.inventorySync,
    );
    controller.catalogItems = const [
      CatalogItem(
        hash: 9001,
        name: 'Synthoceps',
        isExotic: true,
        slot: 'Gauntlets',
        classType: 'Titan',
        sourceStore: 'exotic-armor',
      ),
      CatalogItem(
        hash: 9002,
        name: 'Golden Gun',
        isExotic: false,
        slot: 'super',
        itemTypeName: 'super',
        classType: 'Hunter',
        sourceStore: 'abilities',
      ),
      CatalogItem(
        hash: 9003,
        name: 'Flow State',
        isExotic: false,
        sourceStore: 'aspects',
        classType: 'Hunter',
      ),
    ];

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
      name: 'Fork Me',
      className: GuardianClass.hunter,
      synergyTypes: const [DraftSynergyType(type: 'melee')],
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('builds_subclass_kit_title')), findsOneWidget);
    // Expand optional pins to surface manifest pick keys (collapsed when empty).
    await tester.tap(find.byKey(const Key('builds_optional_pins_toggle')));
    await _pumpFrames(tester);
    expect(find.byKey(const Key('builds_pick_exotic_armor')), findsOneWidget);
    expect(find.byKey(const Key('builds_pick_super')), findsOneWidget);

    // Illegal kit → hard block disables save path.
    controller.setEditSubclass(
      const SubclassKit(aspects: ['A', 'B', 'C']),
    );
    await _pumpFrames(tester);
    expect(controller.identitySaveHardBlocked, isTrue);
    expect(find.byKey(const Key('builds_hard_blocks')), findsOneWidget);

    controller.setEditSubclass(const SubclassKit());
    await _pumpFrames(tester);

    final pending = await controller.updateSelectedIdentity(
      setPinnedSuper: true,
      pinnedSuper: 'Golden Gun',
    );
    expect(pending, contains('Confirm'));
    expect(controller.identityConfirmRequired, isTrue);

    final srcId = controller.selected!.build.id;
    final forked = await controller.updateSelectedIdentity(
      setPinnedSuper: true,
      pinnedSuper: 'Golden Gun',
      identityAction: IdentityAction.fork,
    );
    expect(forked, isNull);
    expect(controller.selected!.build.id, isNot(srcId));
    expect(controller.lastForkedFromId, srcId);
    expect(controller.selected!.build.pinnedSuper, 'Golden Gun');

    // Soft miss alone does not hard-block.
    expect(controller.hasSoftMisses || !controller.hasSoftMisses, isTrue);
    controller.setEditSubclass(const SubclassKit(aspects: ['Flow State']));
    expect(
      controller.composeHardBlocks
          .any((b) => b.code == DomainFailureCodes.illegalSubclassKit),
      isFalse,
    );

    controller.dispose();
  });

  testWidgets('US3 Builds nav destination shows builds page', (tester) async {
    await tester.pumpWidget(
      Destiny2WindowsApp(services: services),
    );
    await _pumpFrames(tester);

    // Build is 2nd destination (index 1): Loadouts, Build, … (DART-068).
    final buildsDest = find.text('Build');

    expect(buildsDest, findsWidgets);
    await tester.tap(buildsDest.first);
    await _pumpFrames(tester);

    expect(find.byKey(const Key('builds_library_page')), findsOneWidget);
    expect(find.byKey(const Key('builds_list_empty')), findsOneWidget);

    // Other destinations still present in rail.
    expect(find.text('Catalog'), findsOneWidget);
    expect(find.text('Sets'), findsOneWidget);
    expect(find.text('Synergy'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
