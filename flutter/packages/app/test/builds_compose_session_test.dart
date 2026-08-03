import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  test('createBuild requires synergy type then lists the build', () async {
    final db = AppDatabase.memory();
    final session = BuildsComposeSession(db: db);

    final blocked = await session.createBuild(
      name: 'Empty types',
      className: GuardianClass.hunter,
    );
    expect(blocked, isNotNull);
    expect(blocked!.toLowerCase(), contains('synergy'));

    session.addCreateDraftType('melee', 'Base');
    expect(session.createDraftTypes, hasLength(1));
    expect(session.createDraftTypes.single.designationKey, 'melee::Base');

    final err = await session.createBuild(
      name: 'Hunter Melee',
      className: GuardianClass.hunter,
    );
    expect(err, isNull);
    expect(session.builds, isNotEmpty);
    expect(session.selected, isNotNull);
    expect(session.selected!.build.name, 'Hunter Melee');
    expect(session.softGuidanceAdvisory.toLowerCase(), contains('never auto-applies'));

    await db.close();
  });

  test('attachSet and detachSet update session attachments (shared state machine)',
      () async {
    final db = AppDatabase.memory();
    final session = BuildsComposeSession(db: db);

    session.addCreateDraftType('melee');
    final createErr = await session.createBuild(
      name: 'Attach path',
      className: GuardianClass.warlock,
    );
    expect(createErr, isNull);
    expect(session.selectedVariant, isNotNull);

    // Partial loadouts only allowed on non-default variants (DBR-CMPL-001).
    final variantErr = await session.createVariant(name: 'Alt loadout');
    expect(variantErr, isNull, reason: variantErr);
    expect(session.selectedVariant?.name, 'Alt loadout');

    final uid = session.userId!;
    await createUserSet(
      db,
      uid,
      const CreateSetCommand(id: 'armor-set', name: 'Armor A', type: SetType.armor),
    );
    await upsertUserSetItem(
      db,
      uid,
      'armor-set',
      const UpsertSetItemCommand(
        slot: 'helmet',
        itemHash: 1,
        itemName: 'Helm',
      ),
    );
    await upsertUserSetItem(
      db,
      uid,
      'armor-set',
      const UpsertSetItemCommand(
        slot: 'arms',
        itemHash: 2,
        itemName: 'Arms',
      ),
    );
    await createUserSet(
      db,
      uid,
      const CreateSetCommand(id: 'mod-set', name: 'Mods', type: SetType.mod),
    );
    await upsertUserSetItem(
      db,
      uid,
      'mod-set',
      const UpsertSetItemCommand(
        slot: 'helmet:1',
        itemHash: 3,
        itemName: 'Mod H',
      ),
    );
    await upsertUserSetItem(
      db,
      uid,
      'mod-set',
      const UpsertSetItemCommand(
        slot: 'arms:2',
        itemHash: 4,
        itemName: 'Mod A',
      ),
    );
    // Under-min scaffold must not appear in attachableSets (BR-ATT-006).
    await createUserSet(
      db,
      uid,
      const CreateSetCommand(id: 'sparse', name: 'Sparse', type: SetType.weapon),
    );
    await upsertUserSetItem(
      db,
      uid,
      'sparse',
      const UpsertSetItemCommand(
        slot: 'primary',
        itemHash: 9,
        itemName: 'Only one',
      ),
    );

    // Reload attachable list while keeping the non-default selection.
    final altId = session.selectedVariant!.id;
    await session.refresh();
    await session.openBuild(session.selected!.build.id);
    await session.selectVariant(altId);

    expect(
      session.attachableSets.map((s) => s.id),
      containsAll(['armor-set', 'mod-set']),
    );
    expect(session.attachableSets.map((s) => s.id), isNot(contains('sparse')));

    final attachErr = await session.attachSet('armor-set');
    expect(attachErr, isNull, reason: attachErr);
    expect(session.attachments.map((a) => a.record.setId), contains('armor-set'));
    expect(
      session.attachments.singleWhere((a) => a.record.setId == 'armor-set').record.mode,
      AttachmentMode.live.wireName,
    );

    final attachMod = await session.attachSet('mod-set');
    expect(attachMod, isNull, reason: attachMod);
    expect(session.attachments, hasLength(2));

    final dup = await session.attachSet('armor-set');
    expect(dup, isNotNull);
    expect(dup!.toLowerCase(), contains('already'));

    final detachErr = await session.detachSet('mod-set');
    expect(detachErr, isNull, reason: detachErr);
    expect(session.attachments.map((a) => a.record.setId), ['armor-set']);

    await db.close();
  });

  test('pinSlot requires live attachment and updates slot pin instance', () async {
    final db = AppDatabase.memory();
    final session = BuildsComposeSession(db: db);

    session.addCreateDraftType('ability');
    expect(await session.createBuild(name: 'Pin path', className: GuardianClass.titan),
        isNull);

    final variantErr = await session.createVariant(name: 'Pin alt');
    expect(variantErr, isNull, reason: variantErr);
    final altId = session.selectedVariant!.id;

    final uid = session.userId!;
    await createUserSet(
      db,
      uid,
      const CreateSetCommand(id: 'w-set', name: 'Weapons', type: SetType.weapon),
    );
    await upsertUserSetItem(
      db,
      uid,
      'w-set',
      const UpsertSetItemCommand(
        slot: 'primary',
        itemHash: 9001,
        itemName: 'Hand Cannon',
      ),
    );
    await upsertUserSetItem(
      db,
      uid,
      'w-set',
      const UpsertSetItemCommand(
        slot: 'special',
        itemHash: 9002,
        itemName: 'Fusion',
      ),
    );

    await session.refresh();
    await session.openBuild(session.selected!.build.id);
    await session.selectVariant(altId);
    expect(await session.attachSet('w-set'), isNull);

    final noItem = await session.pinSlot(
      setId: 'w-set',
      slot: 'heavy',
      instanceId: 'inst-x',
    );
    expect(noItem, isNotNull);
    expect(noItem!.toLowerCase(), contains('not found'));

    final pinErr = await session.pinSlot(
      setId: 'w-set',
      slot: 'primary',
      instanceId: 'inst-42',
    );
    expect(pinErr, isNull, reason: pinErr);

    final primary = session.slotPins.where((p) => p.slot == 'primary').toList();
    expect(primary, isNotEmpty);
    expect(primary.single.instanceId, 'inst-42');
    expect(primary.single.itemHash, 9001);
    expect(primary.single.pinLabel, isNotEmpty);

    await db.close();
  });

  test('refreshSoftCoverage and saveSoftStatTargets stay display-only (no auto-apply)',
      () async {
    final db = AppDatabase.memory();
    final session = BuildsComposeSession(db: db);

    session.addCreateDraftType('melee', 'Base');
    expect(
      await session.createBuild(name: 'Soft path', className: GuardianClass.hunter),
      isNull,
    );

    // Soft targets save via shared session, not host-local maps.
    final saveErr = await session.saveSoftStatTargets(
      SoftStatTargets({
        ArmorStatName.weapons: 70,
        ArmorStatName.health: 40,
      }),
    );
    expect(saveErr, isNull, reason: saveErr);
    expect(session.softStatTargets[ArmorStatName.weapons], 70);
    expect(session.softStatTargets[ArmorStatName.health], 40);
    expect(session.softStatTargetsSummary, isNotEmpty);

    // Coverage refresh must not throw and must leave advisory unchanged.
    await session.refreshSoftCoverage();
    expect(session.softGuidanceAdvisory.toLowerCase(), contains('never auto-applies'));
    // Coverage result object is present after load (may be empty without indexes).
    expect(session.coverageResult, isA<CoverageResult>());

    // Field map path also goes through shared session.
    final fieldsErr = await session.saveSoftStatTargetsFromFields({
      'Weapons': '80',
      'Health': '50',
    });
    expect(fieldsErr, isNull, reason: fieldsErr);
    expect(session.softStatTargets[ArmorStatName.weapons], 80);
    expect(session.softStatTargets[ArmorStatName.health], 50);

    await db.close();
  });

  test('selectVariant clears compose when null and reloads for valid id', () async {
    final db = AppDatabase.memory();
    final session = BuildsComposeSession(db: db);

    session.addCreateDraftType('super');
    expect(
      await session.createBuild(name: 'Variant path', className: GuardianClass.hunter),
      isNull,
    );
    final defaultId = session.selectedVariant!.id;

    final createV = await session.createVariant(name: 'Alt');
    expect(createV, isNull, reason: createV);
    expect(session.variants.length, greaterThanOrEqualTo(2));
    expect(session.selectedVariant?.name, 'Alt');

    await session.selectVariant(null);
    expect(session.selectedVariant, isNull);
    expect(session.attachments, isEmpty);
    expect(session.slotPins, isEmpty);

    await session.selectVariant(defaultId);
    expect(session.selectedVariant?.id, defaultId);

    await db.close();
  });
}
