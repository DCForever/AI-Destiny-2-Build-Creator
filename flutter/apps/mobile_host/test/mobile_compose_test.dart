import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_mobile_host/app.dart';
import 'package:destiny2_mobile_host/builds/builds_controller.dart';
import 'package:destiny2_mobile_host/host_bootstrap.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRefresh implements ManifestRefreshApi {
  @override
  Future<bool> isStale() async => true;

  @override
  Future<ManifestStatus> refresh({
    bool forceFullDownload = false,
    bool rebuildInIsolate = true,
  }) async =>
      status();

  @override
  Future<ManifestStatus> status() async => const ManifestStatus(
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

  late AppDatabase db;
  late MobileAppServices services;
  late BuildsController controller;

  setUp(() async {
    db = AppDatabase.memory();
    services = MobileAppServices(
      storageRoot: StorageRoot(basePath: '/tmp/dart041_unused'),
      db: db,
      manifestRefresh: _FakeRefresh(),
    );
    controller = BuildsController(db: db);
  });

  tearDown(() async {
    controller.dispose();
    await services.dispose();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      Destiny2MobileApp(
        services: services,
        buildsController: controller,
      ),
    );
    await tester.pumpAndSettle();
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
      db,
      userId,
      CreateSetCommand(id: setId, name: name, type: SetType.weapon),
    );
    await upsertUserSetItem(
      db,
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

  Future<void> seedSynergyWithWeaponLink(int userId) async {
    await createUserSynergy(
      db,
      userId,
      const CreateSynergyCommand(
        id: 'syn-mobile-1',
        name: 'Melee Loop',
        type: 'melee',
        subType: 'Base',
        links: [
          SynergyLinkWrite(
            id: 'link-mobile-1',
            kind: 'weapon',
            displayName: 'Needed Gun',
            itemHash: 777001,
          ),
        ],
      ),
    );
  }

  testWidgets('US1 create build via FAB sheet → Focus Swap detail',
      (tester) async {
    await pumpApp(tester);

    expect(find.byKey(const Key('builds_empty')), findsOneWidget);
    expect(find.byKey(const Key('create_build_fab')), findsOneWidget);

    await tester.tap(find.byKey(const Key('create_build_fab')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create_build_sheet')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('create_build_name')),
      'Phone Hunter',
    );
    await tester.enterText(
      find.byKey(const Key('create_build_synergy')),
      'melee',
    );
    await tester.tap(find.byKey(const Key('create_build_submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('build_detail_page')), findsOneWidget);
    expect(find.byKey(const Key('compose_section_identity')), findsOneWidget);
    expect(find.byKey(const Key('compose_section_variants')), findsOneWidget);
    expect(find.byKey(const Key('compose_section_attachments')), findsOneWidget);
    expect(find.byKey(const Key('builds_soft_guidance')), findsOneWidget);
    expect(find.text('Phone Hunter'), findsWidgets);
    expect(controller.builds, hasLength(1));
    expect(controller.selectedVariant?.isDefault, isTrue);
  });

  testWidgets('US2 attach set shows attachment + wishlist pin', (tester) async {
    await pumpApp(tester);

    final err = await controller.createBuild(
      name: 'Attach Build',
      className: GuardianClass.hunter,
      synergyTypes: const [DraftSynergyType(type: 'melee')],
    );
    expect(err, isNull);

    final uid = controller.userId!;
    await seedWeaponSet(uid, 'w-kinetic', 'Kinetic Core', 'primary', 100);
    await controller.refresh();
    await _pumpFrames(tester);

    // Non-default avoids default completeness hard-gate.
    final vErr = await controller.createVariant(name: 'Alt');
    expect(vErr, isNull);

    final aErr = await controller.attachSet('w-kinetic');
    expect(aErr, isNull, reason: controller.error);

    expect(controller.attachments, hasLength(1));
    expect(controller.attachments.single.record.setId, 'w-kinetic');
    expect(controller.slotPins, isNotEmpty);
    final primary = controller.slotPins.firstWhere((p) => p.slot == 'primary');
    expect(primary.pinLabel, 'wishlist');

    final pinErr = await controller.pinSlot(
      setId: 'w-kinetic',
      slot: 'primary',
      instanceId: 'inst-1',
      setItemId: primary.setItemId,
    );
    expect(pinErr, isNull);
    final after = controller.slotPins.firstWhere((p) => p.slot == 'primary');
    expect(after.pinLabel, 'instance');

    final clearErr = await controller.pinSlot(
      setId: 'w-kinetic',
      slot: 'primary',
      instanceId: null,
      setItemId: after.setItemId,
    );
    expect(clearErr, isNull);
    expect(
      controller.slotPins.firstWhere((p) => p.slot == 'primary').pinLabel,
      'wishlist',
    );
  });

  testWidgets('US2 SLOT_CONFLICT surfaces without half-apply', (tester) async {
    await pumpApp(tester);

    await controller.createBuild(
      name: 'Conflict Build',
      className: GuardianClass.hunter,
      synergyTypes: const [DraftSynergyType(type: 'melee')],
    );
    final uid = controller.userId!;
    await seedWeaponSet(uid, 'w-a', 'Set A', 'primary', 101);
    await seedWeaponSet(uid, 'w-b', 'Set B', 'primary', 102);
    await controller.refresh();
    await controller.createVariant(name: 'Alt');

    expect(await controller.attachSet('w-a'), isNull);
    expect(controller.attachments, hasLength(1));

    // Force both sets in one replace by attaching second (merge path).
    final conflict = await controller.attachSet('w-b');
    expect(conflict, isNotNull);
    expect(
      conflict!.toLowerCase().contains('conflict') ||
          conflict.toLowerCase().contains('slot'),
      isTrue,
      reason: conflict,
    );
    expect(controller.attachments, hasLength(1));
    expect(controller.attachments.single.record.setId, 'w-a');
  });

  testWidgets('US3 soft missing chip + never auto-applies + soft targets',
      (tester) async {
    final uid = await controller.resolveLibraryUserId();
    await seedSynergyWithWeaponLink(uid);

    await pumpApp(tester);

    final err = await controller.createBuild(
      name: 'Soft Build',
      className: GuardianClass.hunter,
      synergyTypes: const [DraftSynergyType(type: 'melee', subType: 'Base')],
    );
    expect(err, isNull);
    await _pumpFrames(tester);

    // Open detail so soft UI mounts.
    await tester.tap(find.byKey(Key('build_row_${controller.builds.first.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('builds_soft_guidance')), findsOneWidget);
    expect(
      find.byKey(const Key('builds_soft_guidance_advisory')),
      findsOneWidget,
    );
    expect(find.textContaining('never auto-applies'), findsWidgets);

    expect(controller.synergyCoverageRows, isNotEmpty);
    expect(
      controller.synergyCoverageRows.any((r) => r.tier == CoverageTier.missing),
      isTrue,
    );
    expect(find.byKey(const Key('builds_soft_coverage_chips')), findsOneWidget);
    expect(find.textContaining('missing'), findsWidgets);

    final attachmentsBefore = controller.attachments.length;
    await controller.refreshSoftCoverage();
    expect(controller.attachments.length, attachmentsBefore);

    // Soft miss does not hard-block legal attach on non-default.
    await seedWeaponSet(uid, 'w-other', 'Other Gun', 'special', 200);
    await controller.refresh();
    await controller.createVariant(name: 'Alt');
    final priorAtt = List.of(controller.attachments);
    final aErr = await controller.attachSet('w-other');
    expect(aErr, isNull, reason: controller.error);
    expect(controller.attachments.length, greaterThan(priorAtt.length));

    final saveErr = await controller.saveSoftStatTargets(
      SoftStatTargets({ArmorStatName.health: 100}),
    );
    expect(saveErr, isNull);
    expect(controller.softStatTargets[ArmorStatName.health], 100);
    expect(controller.softStatTargetsSummary, contains('Health:100'));
  });

  testWidgets('US4 linear sections present; list not dual-pane with detail',
      (tester) async {
    await controller.createBuild(
      name: 'Linear',
      className: GuardianClass.titan,
      synergyTypes: const [DraftSynergyType(type: 'grenade')],
    );
    await pumpApp(tester);

    await tester.tap(find.byKey(Key('build_row_${controller.builds.first.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('builds_list')), findsNothing);
    expect(find.byKey(const Key('compose_section_identity')), findsOneWidget);
    expect(find.byKey(const Key('compose_section_variants')), findsOneWidget);
    expect(find.byKey(const Key('compose_section_attachments')), findsOneWidget);
    expect(find.byKey(const Key('builds_soft_guidance')), findsOneWidget);

    // Sections in document order (identity before soft).
    final identityY =
        tester.getTopLeft(find.byKey(const Key('compose_section_identity'))).dy;
    final softY =
        tester.getTopLeft(find.byKey(const Key('builds_soft_guidance'))).dy;
    expect(identityY, lessThan(softY));
  });
}
