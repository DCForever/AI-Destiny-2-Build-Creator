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
import 'package:destiny2_windows_host/builds/soft_guidance_format.dart';
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

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dart034_soft_');
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
        version: 'fixture-soft-1',
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

  Future<BuildsLibraryController> pumpPage(WidgetTester tester) async {
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
    return controller;
  }

  Future<void> seedSynergyWithWeaponLink(int userId) async {
    await createUserSynergy(
      services.db,
      userId,
      const CreateSynergyCommand(
        id: 'syn-soft-1',
        name: 'Melee Loop',
        type: 'melee',
        subType: 'Base',
        links: [
          SynergyLinkWrite(
            id: 'link-soft-1',
            kind: 'weapon',
            displayName: 'Needed Gun',
            itemHash: 777001,
          ),
        ],
      ),
    );
  }

  testWidgets('US1 soft coverage missing chip without matching kit',
      (tester) async {
    final controller = await pumpPage(tester);
    final uid = await controller.resolveLibraryUserId();
    await seedSynergyWithWeaponLink(uid);

    final err = await controller.createBuild(
      name: 'Soft Build',
      className: GuardianClass.hunter,
      synergyTypes: const [DraftSynergyType(type: 'melee', subType: 'Base')],
    );
    expect(err, isNull);
    await _pumpFrames(tester);

    expect(find.byKey(const Key('builds_soft_guidance')), findsOneWidget);
    expect(
      find.byKey(const Key('builds_soft_guidance_advisory')),
      findsOneWidget,
    );
    expect(
      find.textContaining('never auto-applies'),
      findsWidgets,
    );

    expect(controller.synergyCoverageRows, isNotEmpty);
    expect(
      controller.synergyCoverageRows.any((r) => r.tier == CoverageTier.missing),
      isTrue,
    );
    expect(find.byKey(const Key('builds_soft_coverage_chips')), findsOneWidget);
    expect(find.textContaining('missing'), findsWidgets);
    controller.dispose();
  });

  testWidgets('US1 soft miss does not hard-block legal attach', (tester) async {
    final controller = await pumpPage(tester);
    final uid = await controller.resolveLibraryUserId();
    await seedSynergyWithWeaponLink(uid);

    await controller.createBuild(
      name: 'Attach Soft',
      className: GuardianClass.hunter,
      synergyTypes: const [DraftSynergyType(type: 'melee', subType: 'Base')],
    );
    await createUserSet(
      services.db,
      uid,
      const CreateSetCommand(
        id: 'set-other',
        name: 'Other Gun',
        type: SetType.weapon,
      ),
    );
    await upsertUserSetItem(
      services.db,
      uid,
      'set-other',
      const UpsertSetItemCommand(
        id: 'item-other',
        slot: 'primary',
        itemHash: 1,
        itemName: 'Not the gun',
      ),
    );
    await upsertUserSetItem(
      services.db,
      uid,
      'set-other',
      const UpsertSetItemCommand(
        id: 'item-other-2',
        slot: 'special',
        itemHash: 2,
        itemName: 'Also not',
      ),
    );
    await controller.refresh();
    await _pumpFrames(tester);

    // Non-default variant: soft miss must not block attach (default completeness is hard).
    await controller.createVariant(name: 'Alt Soft');
    await _pumpFrames(tester);

    final beforeAtts = controller.attachments.length;
    expect(controller.hasSoftMisses, isTrue);

    final attachErr = await controller.attachSet('set-other');
    expect(attachErr, isNull, reason: controller.error);
    expect(controller.attachments.length, beforeAtts + 1);
    // Soft miss may still be present after attach of non-matching set.
    expect(controller.hasSoftMisses, isTrue);
    controller.dispose();
  });

  testWidgets('US2 explicit soft stat targets save', (tester) async {
    final controller = await pumpPage(tester);

    final err = await controller.createBuild(
      name: 'Targets Build',
      className: GuardianClass.warlock,
      synergyTypes: const [DraftSynergyType(type: 'grenade', subType: 'Base')],
    );
    expect(err, isNull);
    await _pumpFrames(tester);

    final saveErr = await controller.saveSoftStatTargets(
      SoftStatTargets({
        ArmorStatName.health: 100,
        ArmorStatName.melee: 80,
      }),
    );
    expect(saveErr, isNull);
    expect(controller.softStatTargets[ArmorStatName.health], 100);
    expect(controller.softStatTargets[ArmorStatName.melee], 80);
    expect(
      controller.softStatTargetsSummary,
      formatSoftStatTargetsSummary(controller.softStatTargets),
    );

    await _pumpFrames(tester);
    expect(find.byKey(const Key('builds_soft_stat_save')), findsOneWidget);
    expect(
      find.byKey(const Key('builds_soft_stat_saved_summary')),
      findsOneWidget,
    );
    controller.dispose();
  });

  testWidgets('US3 coverage refresh does not auto-apply attachments',
      (tester) async {
    final controller = await pumpPage(tester);
    final uid = await controller.resolveLibraryUserId();
    await seedSynergyWithWeaponLink(uid);

    await controller.createBuild(
      name: 'No Auto',
      className: GuardianClass.hunter,
      synergyTypes: const [DraftSynergyType(type: 'melee', subType: 'Base')],
    );
    await _pumpFrames(tester);

    expect(controller.attachments, isEmpty);
    final missBefore = controller.hasSoftMisses;
    expect(missBefore, isTrue);

    await controller.refreshSoftCoverage();
    await _pumpFrames(tester);

    expect(controller.attachments, isEmpty);
    expect(controller.slotPins, isEmpty);
    expect(controller.hasSoftMisses, isTrue);
    // Targets not auto-written from coverage.
    expect(controller.softStatTargets.isEmpty, isTrue);
    controller.dispose();
  });

  testWidgets('US1 matching attach can raise coverage tier', (tester) async {
    final controller = await pumpPage(tester);
    final uid = await controller.resolveLibraryUserId();
    await seedSynergyWithWeaponLink(uid);

    await controller.createBuild(
      name: 'Supported Path',
      className: GuardianClass.hunter,
      synergyTypes: const [DraftSynergyType(type: 'melee', subType: 'Base')],
    );
    await createUserSet(
      services.db,
      uid,
      const CreateSetCommand(
        id: 'set-match',
        name: 'Needed Set',
        type: SetType.weapon,
      ),
    );
    await upsertUserSetItem(
      services.db,
      uid,
      'set-match',
      const UpsertSetItemCommand(
        id: 'item-match',
        slot: 'primary',
        itemHash: 777001,
        itemName: 'Needed Gun',
      ),
    );
    await upsertUserSetItem(
      services.db,
      uid,
      'set-match',
      const UpsertSetItemCommand(
        id: 'item-match-2',
        slot: 'special',
        itemHash: 777002,
        itemName: 'Filler',
      ),
    );
    await controller.refresh();
    await _pumpFrames(tester);

    await controller.createVariant(name: 'Covered');
    await _pumpFrames(tester);

    expect(
      controller.synergyCoverageRows.any((r) => r.tier == CoverageTier.missing),
      isTrue,
    );

    final attachErr = await controller.attachSet('set-match');
    expect(attachErr, isNull, reason: controller.error);
    await _pumpFrames(tester);

    expect(
      controller.synergyCoverageRows.any(
        (r) => r.tier == CoverageTier.supported,
      ),
      isTrue,
    );
    controller.dispose();
  });
}
