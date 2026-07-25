import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart'
    hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_web_host/builds/builds_controller.dart';
import 'package:destiny2_web_host/compose/soft_guidance_format.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late BuildsController controller;

  setUp(() async {
    db = AppDatabase.memory();
    controller = BuildsController(db: db);
  });

  tearDown(() async {
    await db.close();
  });

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
        id: 'syn-web-1',
        name: 'Melee Loop',
        type: 'melee',
        subType: 'Base',
        links: [
          SynergyLinkWrite(
            id: 'link-web-1',
            kind: 'weapon',
            displayName: 'Needed Gun',
            itemHash: 777001,
          ),
        ],
      ),
    );
  }

  test('US1 create build requires synergy type and selects default variant',
      () async {
    final errEmpty = await controller.createBuild(
      name: 'No types',
      className: GuardianClass.hunter,
      synergyTypes: const [],
    );
    expect(errEmpty, contains('synergy type'));
    expect(controller.builds, isEmpty);

    final err = await controller.createBuild(
      name: 'Web Hunter',
      className: GuardianClass.hunter,
      synergyTypes: const [DraftSynergyType(type: 'melee')],
    );
    expect(err, isNull);
    expect(controller.builds, hasLength(1));
    expect(controller.selected, isNotNull);
    expect(controller.selectedVariant?.isDefault, isTrue);
    expect(controller.titleOf(controller.builds.single), 'Web Hunter');
  });

  test('US3 attach on non-default + pin wishlist/instance + hard conflict',
      () async {
    final uid = await controller.resolveLibraryUserId();
    await seedWeaponSet(uid, 'set-a', 'Kinetic Core', 'primary', 1001);
    await seedWeaponSet(uid, 'set-b', 'Kinetic Alt', 'primary', 1002);

    await controller.createBuild(
      name: 'Compose',
      className: GuardianClass.hunter,
      synergyTypes: const [DraftSynergyType(type: 'melee')],
    );
    final createVar = await controller.createVariant(name: 'Alt');
    expect(createVar, isNull);
    expect(controller.selectedVariant?.isDefault, isFalse);

    final attach = await controller.attachSet('set-a');
    expect(attach, isNull);
    expect(controller.attachments, hasLength(1));
    expect(controller.slotPins, isNotEmpty);
    expect(controller.slotPins.first.pinLabel, 'wishlist');

    final pin = controller.slotPins.first;
    final pinErr = await controller.pinSlot(
      setId: pin.setId,
      slot: pin.slot,
      instanceId: 'inst-1',
      setItemId: pin.setItemId,
    );
    expect(pinErr, isNull);
    expect(controller.slotPins.first.pinLabel, 'instance');

    final clear = await controller.pinSlot(
      setId: pin.setId,
      slot: pin.slot,
      instanceId: null,
      setItemId: pin.setItemId,
    );
    expect(clear, isNull);
    expect(controller.slotPins.first.pinLabel, 'wishlist');

    final conflict = await controller.attachSet('set-b');
    expect(conflict, isNotNull);
    expect(
      conflict!.toLowerCase(),
      anyOf(contains('conflict'), contains('slot'), contains('primary')),
    );
    expect(controller.attachments, hasLength(1));
    expect(controller.attachments.single.record.setId, 'set-a');
  });

  test('US4 soft guidance display-only + soft targets explicit save', () async {
    final uid = await controller.resolveLibraryUserId();
    await seedSynergyWithWeaponLink(uid);

    await controller.createBuild(
      name: 'Soft',
      className: GuardianClass.hunter,
      synergyTypes: const [DraftSynergyType(type: 'melee', subType: 'Base')],
    );
    await controller.createVariant(name: 'Work');

    // Coverage should surface a soft miss without mutating attachments.
    await controller.refreshSoftCoverage();
    expect(controller.softGuidanceAdvisory, kSoftGuidanceAdvisoryCaption);
    expect(controller.attachments, isEmpty);

    final tiers = controller.synergyCoverageRows.map((r) => r.tier).toList();
    expect(
      tiers.any(
        (t) => t == CoverageTier.missing || t == CoverageTier.weak,
      ),
      isTrue,
      reason: 'unmatched designated synergy should soft-miss',
    );

    final priorAttachments = List.of(controller.attachments);
    await controller.refreshSoftCoverage();
    expect(controller.attachments.length, priorAttachments.length);

    final save = await controller.saveSoftStatTargets(
      const SoftStatTargets({ArmorStatName.health: 100}),
    );
    expect(save, isNull);
    expect(controller.softStatTargets[ArmorStatName.health], 100);

    // Soft miss must not block legal attach on non-default.
    await seedWeaponSet(uid, 'set-soft', 'Soft Gun', 'primary', 2001);
    final attach = await controller.attachSet('set-soft');
    expect(attach, isNull);
    expect(controller.attachments, hasLength(1));
  });

  test('no CLIENT_SECRET in controller surface', () {
    expect(controller.softGuidanceAdvisory, isNot(contains('CLIENT_SECRET')));
  });
}
