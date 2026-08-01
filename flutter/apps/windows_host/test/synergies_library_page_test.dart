import 'dart:io';

import 'package:destiny2_app/destiny2_app.dart' show SynergyLinkWrite;
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/app.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
import 'package:destiny2_windows_host/synergies/synergies_library_controller.dart';
import 'package:destiny2_windows_host/synergies/synergies_library_page.dart';
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

/// Expand collapsible create form (BUG-20260726-008).
Future<void> _expandSynergiesCreate(WidgetTester tester) async {
  if (find.byKey(const Key('synergies_create_button')).evaluate().isEmpty) {
    await tester.tap(find.byKey(const Key('synergies_create_toggle')));
    await _pumpFrames(tester);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppServices services;
  late AppDatabase db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dart031_syn_');
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
        version: 'fixture-syn-1',
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

  testWidgets('US1 create synergy appears in list and detail with designation',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: SynergiesLibraryPage(
          key: const Key('synergies_library_page'),
          services: services,
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('synergies_list_empty')), findsOneWidget);

    await _expandSynergiesCreate(tester);
    await tester.enterText(
      find.byKey(const Key('synergies_create_name')),
      'Melee Combo',
    );
    await tester.enterText(
      find.byKey(const Key('synergies_create_subtype')),
      'Base',
    );
    await tester.tap(find.byKey(const Key('synergies_create_button')));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('synergies_list')), findsOneWidget);
    expect(find.text('Melee Combo'), findsWidgets);
    expect(find.byKey(const Key('synergies_detail')), findsOneWidget);
    expect(find.byKey(const Key('synergies_detail_designation')), findsOneWidget);
    expect(find.textContaining('Melee: Base'), findsWidgets);
    expect(find.byKey(const Key('synergies_designation_locked')), findsOneWidget);
  });

  testWidgets('US2 rename keeps designation; no type editor on detail',

      (tester) async {
    final controller = SynergiesLibraryController(
      db: services.db,
      session: services.oauthSession,
      inventorySync: services.inventorySync,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: SynergiesLibraryPage(
          services: services,
          controller: controller,
        ),
      ),
    );
    await _pumpFrames(tester);

    final createErr = await controller.createSynergy(
      name: 'Old Name',
      type: 'melee',
      subType: 'Base',
    );
    expect(createErr, isNull);
    await _pumpFrames(tester);

    // Detail must not offer type/subtype edit keys.
    expect(find.byKey(const Key('synergies_edit_type')), findsNothing);
    expect(find.byKey(const Key('synergies_edit_subtype')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('synergies_edit_name')),
      'New Name',
    );
    final saveIdentity = find.byKey(const Key('synergies_save_identity'));
    await tester.ensureVisible(saveIdentity);
    await tester.tap(saveIdentity);
    await _pumpFrames(tester);

    expect(find.text('New Name'), findsWidgets);
    expect(find.textContaining('Melee: Base'), findsWidgets);
    expect(controller.selected!.type, 'melee');
    expect(controller.selected!.subType, 'Base');

    controller.dispose();
  });

  testWidgets('US2 designation change attempt surfaces immutable error',
      (tester) async {
    final controller = SynergiesLibraryController(
      db: services.db,
      session: services.oauthSession,
      inventorySync: services.inventorySync,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: SynergiesLibraryPage(
          services: services,
          controller: controller,
        ),
      ),
    );
    await _pumpFrames(tester);

    final createErr = await controller.createSynergy(
      name: 'Locked',
      type: 'melee',
    );
    expect(createErr, isNull);
    await _pumpFrames(tester);

    final err = await controller.attemptChangeType('grenade');
    expect(err, isNotNull);
    expect(err!.toLowerCase(), contains('cannot be changed'));
    expect(controller.selected!.type, 'melee');

    await _pumpFrames(tester);
    expect(find.byKey(const Key('synergies_status')), findsOneWidget);

    controller.dispose();
  });

  testWidgets('US3 add evidence link and save', (tester) async {
    final controller = SynergiesLibraryController(
      db: services.db,
      session: services.oauthSession,
      inventorySync: services.inventorySync,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: SynergiesLibraryPage(
          services: services,
          controller: controller,
        ),
      ),
    );
    await _pumpFrames(tester);

    final createErr = await controller.createSynergy(
      name: 'Evidence Syn',
      type: 'melee',
    );
    expect(createErr, isNull);
    await _pumpFrames(tester);

    expect(find.byKey(const Key('synergies_links_empty')), findsOneWidget);

    // Prefer controller draft path for kind (dropdown menu is flaky in short VMs).
    controller.addDraftLink(
      const SynergyLinkWrite(
        kind: 'exotic_armor',
        displayName: 'Synthoceps',
        itemHash: 1001,
      ),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('synergies_links_list')), findsOneWidget);
    expect(find.textContaining('Synthoceps'), findsWidgets);

    final saveLinks = find.byKey(const Key('synergies_links_save'));
    await tester.ensureVisible(saveLinks);
    await tester.tap(saveLinks);
    await _pumpFrames(tester);

    expect(controller.selected!.links, hasLength(1));
    expect(controller.selected!.links.single.displayName, 'Synthoceps');
    expect(controller.selected!.links.single.kind, 'exotic_armor');
    expect(find.byKey(const Key('synergies_link_row_0')), findsOneWidget);

    controller.dispose();
  });

  testWidgets('US3 link form add button drafts a weapon link', (tester) async {
    final controller = SynergiesLibraryController(
      db: services.db,
      session: services.oauthSession,
      inventorySync: services.inventorySync,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: SynergiesLibraryPage(
          services: services,
          controller: controller,
        ),
      ),
    );
    await _pumpFrames(tester);

    await controller.createSynergy(name: 'Form Syn', type: 'melee');
    await _pumpFrames(tester);

    await tester.enterText(
      find.byKey(const Key('synergies_link_display_name')),
      'Tractor Cannon',
    );
    await tester.enterText(
      find.byKey(const Key('synergies_link_item_hash')),
      '99',
    );
    final addLink = find.byKey(const Key('synergies_link_add'));
    await tester.ensureVisible(addLink);
    await tester.tap(addLink);
    await _pumpFrames(tester);

    expect(controller.draftLinks, hasLength(1));
    expect(controller.draftLinks.single.displayName, 'Tractor Cannon');
    expect(controller.draftLinks.single.kind, SynergyLinkKind.weapon.wireName);

    controller.dispose();
  });

  testWidgets('US4 Synergies nav destination shows library page',
      (tester) async {
    await tester.pumpWidget(
      Destiny2WindowsApp(services: services),
    );
    await _pumpFrames(tester);

    expect(
      find.byKey(const Key('loadouts_page'), skipOffstage: false),
      findsOneWidget,
    );

    await tester.tap(find.text('Synergy').first);
    await _pumpFrames(tester);

    expect(
      find.byKey(const Key('synergies_library_page'), skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byKey(const Key('synergies_create_toggle')), findsOneWidget);
  });

  testWidgets('dual-pane list and detail present after create', (tester) async {
    final controller = SynergiesLibraryController(
      db: services.db,
      session: services.oauthSession,
      inventorySync: services.inventorySync,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFlapTheme(),
        home: SynergiesLibraryPage(
          services: services,
          controller: controller,
        ),
      ),
    );
    await _pumpFrames(tester);

    await controller.createSynergy(name: 'Pane', type: 'melee');
    await _pumpFrames(tester);

    expect(find.byKey(const Key('synergies_list')), findsOneWidget);
    expect(find.byKey(const Key('synergies_detail')), findsOneWidget);

    controller.dispose();
  });
}
