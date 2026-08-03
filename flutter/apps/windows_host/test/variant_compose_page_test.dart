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
    tempDir = await Directory.systemTemp.createTemp('dart033_compose_');
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
        version: 'fixture-compose-1',
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

  Future<void> seedWeaponSet(
    int userId,
    String setId,
    String name,
    String slot,
    int hash, {
    String? instanceId,
  }) async {
    await createUserSet(
      services.db,
      userId,
      CreateSetCommand(id: setId, name: name, type: SetType.weapon),
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
    final second = slot == 'special' ? 'heavy' : 'special';
    await upsertUserSetItem(
      services.db,
      userId,
      setId,
      UpsertSetItemCommand(
        id: '$setId-item-2',
        slot: second,
        itemHash: hash + 1000,
        itemName: 'Item ${hash + 1000}',
      ),
    );
  }

  testWidgets('US4 create non-default variant and select it', (tester) async {
    final controller = await pumpPage(tester);

    final err = await controller.createBuild(
      name: 'Compose Build',
      className: GuardianClass.hunter,
      synergyTypes: const [DraftSynergyType(type: 'melee', subType: 'Base')],
    );
    expect(err, isNull);
    await _pumpFrames(tester);

    expect(find.byKey(const Key('builds_variant_compose')), findsOneWidget);
    expect(controller.variants, hasLength(1));
    expect(controller.selectedVariant?.isDefault, isTrue);

    final vErr = await controller.createVariant(name: 'Raid');
    expect(vErr, isNull);
    await _pumpFrames(tester);

    expect(controller.variants, hasLength(2));
    expect(controller.selectedVariant?.name, 'Raid');
    expect(controller.selectedVariant?.isDefault, isFalse);
    expect(find.textContaining('Raid'), findsWidgets);

    controller.dispose();
  });

  test('three-gate readiness on compose session (pkg-default-three-gates)',
      () async {
    // Controller-level (widget pump hits Material ink_sparkle shader env issue).
    final controller = BuildsLibraryController(
      db: services.db,
      session: services.oauthSession,
      inventorySync: services.inventorySync,
    );
    await controller.refresh();
    final err = await controller.createBuild(
      name: 'Three Gate Build',
      className: GuardianClass.hunter,
      synergyTypes: const [DraftSynergyType(type: 'melee', subType: 'Base')],
    );
    expect(err, isNull);
    expect(controller.threeGate, isNotNull);
    // Soft never hard-blocks non-default; default starts incomplete.
    expect(controller.threeGate!.isDefault, isTrue);
    expect(controller.threeGate!.composeComplete, isFalse);
    expect(controller.threeGate!.chipLabels, hasLength(3));
    expect(controller.threeGate!.hardBlocksSave, isTrue);

    controller.dispose();
  });

  testWidgets('US1 attach set shows attachment and slot pin wishlist',
      (tester) async {
    final controller = await pumpPage(tester);

    await controller.createBuild(
      name: 'Attach Build',
      className: GuardianClass.hunter,
      synergyTypes: const [DraftSynergyType(type: 'melee')],
    );
    await _pumpFrames(tester);

    final uid = controller.userId!;
    await seedWeaponSet(uid, 'w-kinetic', 'Kinetic Core', 'primary', 100);
    await controller.refresh();
    await _pumpFrames(tester);

    // Prefer non-default for attach (default completeness hard-gate).
    await controller.createVariant(name: 'Alt');
    await _pumpFrames(tester);

    final aErr = await controller.attachSet('w-kinetic');
    expect(aErr, isNull, reason: controller.error);
    await _pumpFrames(tester);

    expect(controller.attachments, hasLength(1));
    expect(controller.attachments.single.record.setId, 'w-kinetic');
    expect(find.byKey(const Key('builds_attachments_list')), findsOneWidget);
    expect(find.textContaining('Kinetic Core'), findsWidgets);

    expect(controller.slotPins, isNotEmpty);
    final primary = controller.slotPins.firstWhere((p) => p.slot == 'primary');
    expect(primary.pinLabel, 'wishlist');
    expect(find.byKey(const Key('builds_slot_pins_list')), findsOneWidget);
    expect(find.textContaining('wishlist'), findsWidgets);

    controller.dispose();
  });

  testWidgets('US2 pin slot wishlist → instance → wishlist', (tester) async {
    final controller = await pumpPage(tester);

    await controller.createBuild(
      name: 'Pin Build',
      className: GuardianClass.titan,
      synergyTypes: const [DraftSynergyType(type: 'melee')],
    );
    final uid = controller.userId!;
    await seedWeaponSet(uid, 'w-pin', 'Pin Set', 'primary', 200);
    await controller.refresh();
    await controller.createVariant(name: 'PinVar');
    await controller.attachSet('w-pin');
    await _pumpFrames(tester);

    final primaryPin =
        controller.slotPins.firstWhere((p) => p.slot == 'primary');
    expect(primaryPin.pinLabel, 'wishlist');

    final pinErr = await controller.pinSlot(
      setId: 'w-pin',
      slot: 'primary',
      setItemId: primaryPin.setItemId,
      instanceId: 'inst-1',
    );
    expect(pinErr, isNull, reason: controller.error);
    await _pumpFrames(tester);

    final afterPin =
        controller.slotPins.firstWhere((p) => p.slot == 'primary');
    expect(afterPin.pinLabel, 'instance');
    expect(afterPin.instanceId, 'inst-1');
    expect(find.textContaining('instance · inst-1'), findsWidgets);

    final clearErr = await controller.pinSlot(
      setId: 'w-pin',
      slot: 'primary',
      setItemId: afterPin.setItemId,
      instanceId: null,
    );
    expect(clearErr, isNull);
    await _pumpFrames(tester);

    final afterClear =
        controller.slotPins.firstWhere((p) => p.slot == 'primary');
    expect(afterClear.pinLabel, 'wishlist');
    expect(afterClear.instanceId, isNull);

    controller.dispose();
  });

  testWidgets('US3 slot conflict is surfaced and prior attach retained',
      (tester) async {
    final controller = await pumpPage(tester);

    await controller.createBuild(
      name: 'Conflict Build',
      className: GuardianClass.warlock,
      synergyTypes: const [DraftSynergyType(type: 'grenade')],
    );
    final uid = controller.userId!;
    await seedWeaponSet(uid, 'w1', 'Weapons A', 'primary', 100);
    await seedWeaponSet(uid, 'w2', 'Weapons B', 'primary', 200);
    await controller.refresh();
    await controller.createVariant(name: 'Conflict');
    await _pumpFrames(tester);

    final ok = await controller.attachSet('w1');
    expect(ok, isNull, reason: controller.error);
    expect(controller.attachments, hasLength(1));

    final conflict = await controller.attachSet('w2');
    expect(conflict, isNotNull);
    expect(
      conflict!.toLowerCase(),
      anyOf(contains('slot'), contains('conflict')),
    );
    await _pumpFrames(tester);

    // Rolled back: still only first set.
    expect(controller.attachments, hasLength(1));
    expect(controller.attachments.single.record.setId, 'w1');
    expect(find.byKey(const Key('builds_status')), findsOneWidget);
    expect(controller.error, isNotNull);

    controller.dispose();
  });
}
