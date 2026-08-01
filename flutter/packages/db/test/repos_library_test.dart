import 'package:destiny2_db/destiny2_db.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  const now = '2026-07-24T12:00:00.000Z';
  const later = '2026-07-24T13:00:00.000Z';

  Future<int> seedUser({String membershipId = 'm-lib-1'}) {
    return insertUser(
      db,
      bungieMembershipId: membershipId,
      membershipType: 3,
      displayName: 'Tester',
    );
  }

  group('US1 round-trips', () {
    test('build create → get → update → delete', () async {
      final userId = await seedUser();

      final created = await createBuildRecord(
        db,
        userId,
        id: 'b1',
        name: 'Strand Titan',
        className: 'Titan',
        subclass: {'super': 'frenzy'},
        exoticArmorHash: 1001,
        exoticArmorName: 'Synthoceps',
        pinnedSuper: 'Frenzied Blade',
        softStatTargets: {'mobility': 50},
        tagIds: ['tag-a', 'tag-b'],
        synergyTypes: const [
          SynergyTypeDesignationRecord(type: 'element', subType: 'strand'),
          SynergyTypeDesignationRecord(type: 'melee'),
        ],
        now: now,
      );

      expect(created.id, 'b1');
      expect(created.name, 'Strand Titan');
      expect(created.className, 'Titan');
      expect(created.exoticArmorHash, 1001);
      expect(created.pinnedSuper, 'Frenzied Blade');
      expect(created.softStatTargets['mobility'], 50);
      expect(created.tagIds, ['tag-a', 'tag-b']);
      expect(created.synergyTypes, [
        const SynergyTypeDesignationRecord(type: 'element', subType: 'strand'),
        const SynergyTypeDesignationRecord(type: 'melee'),
      ]);
      expect(created.createdAt, now);

      final got = await getBuild(db, userId, 'b1');
      expect(got, isNotNull);
      expect(got!.name, created.name);
      expect(got.tagIds, created.tagIds);
      expect(got.synergyTypes, created.synergyTypes);

      final updated = await updateBuildRecord(
        db,
        userId,
        'b1',
        name: 'Strand Titan v2',
        tagIds: ['tag-c'],
        synergyTypes: const [
          SynergyTypeDesignationRecord(type: 'grenade', subType: 'threadling'),
        ],
        now: later,
      );
      expect(updated!.name, 'Strand Titan v2');
      expect(updated.tagIds, ['tag-c']);
      expect(updated.synergyTypes.single.type, 'grenade');
      expect(updated.updatedAt, later);

      expect(await deleteBuildRecord(db, userId, 'b1'), isTrue);
      expect(await getBuild(db, userId, 'b1'), isNull);
    });

    test('set + set item create → list → update → soft remove', () async {
      final userId = await seedUser();

      final set = await createSetRecord(
        db,
        userId,
        id: 's1',
        name: 'Kinetic Kit',
        type: 'weapon',
        tagIds: ['pve'],
        optimizerConstraints: '{"max":3}',
        now: now,
      );
      expect(set.name, 'Kinetic Kit');
      expect(set.tagIds, ['pve']);
      expect(set.optimizerConstraints, '{"max":3}');

      final item = await upsertSetItemRecord(
        db,
        id: 'si1',
        setId: 's1',
        slot: 'kinetic',
        itemHash: 42,
        itemName: 'Aisha\'s Embrace',
        selectedPerks: [1, 2],
        instanceId: 'inst-9',
        now: now,
      );
      expect(item.itemHash, 42);
      expect(item.selectedPerks, [1, 2]);
      expect(item.isActive, isTrue);

      final active = await listActiveSetItems(db, 's1');
      expect(active, hasLength(1));
      expect(active.single.instanceId, 'inst-9');

      final replaced = await upsertSetItemRecord(
        db,
        id: 'si2',
        setId: 's1',
        slot: 'kinetic',
        itemHash: 43,
        itemName: 'Other',
        replaceExisting: true,
        now: later,
      );
      expect(replaced.itemHash, 43);
      expect(await listActiveSetItems(db, 's1'), hasLength(1));
      expect(await listSetItems(db, 's1'), hasLength(2));

      await softRemoveSetItem(
        db,
        setId: 's1',
        itemId: 'si2',
        now: later,
      );
      expect(await listActiveSetItems(db, 's1'), isEmpty);

      final updated = await updateSetRecord(
        db,
        userId,
        's1',
        name: 'Kinetic Kit 2',
        tagIds: ['pvp'],
        now: later,
      );
      expect(updated!.name, 'Kinetic Kit 2');
      expect(updated.tagIds, ['pvp']);

      expect(await deleteSetRecord(db, userId, 's1'), isTrue);
      expect(await getSet(db, userId, 's1'), isNull);
    });

    test('synergy + links create → get → update → delete', () async {
      final userId = await seedUser();

      final created = await createSynergyRecord(
        db,
        userId,
        id: 'syn1',
        name: 'Melee Combo',
        type: 'melee',
        subType: 'Base',
        description: 'Punch things',
        links: const [
          SynergyLinkInput(
            id: 'l1',
            kind: 'exotic_armor',
            displayName: 'Synthoceps',
            itemHash: 1001,
          ),
        ],
        now: now,
      );
      expect(created.name, 'Melee Combo');
      expect(created.links, hasLength(1));
      expect(created.links.single.itemHash, 1001);

      final updated = await updateSynergyRecord(
        db,
        userId,
        'syn1',
        name: 'Melee Combo+',
        links: const [
          SynergyLinkInput(
            id: 'l2',
            kind: 'weapon',
            displayName: 'Tractor Cannon',
            itemHash: 99,
          ),
        ],
        now: later,
      );
      expect(updated!.name, 'Melee Combo+');
      expect(updated.links.single.displayName, 'Tractor Cannon');

      expect(await deleteSynergyRecord(db, userId, 'syn1'), isTrue);
      expect(await getSynergy(db, userId, 'syn1'), isNull);
    });

    test('variant + attachments create → replace → list', () async {
      final userId = await seedUser();
      await createBuildRecord(
        db,
        userId,
        id: 'b1',
        name: 'B',
        className: 'Hunter',
        now: now,
      );
      await createSetRecord(
        db,
        userId,
        id: 's1',
        name: 'Armor',
        type: 'armor',
        now: now,
      );
      await createSetRecord(
        db,
        userId,
        id: 's2',
        name: 'Mods',
        type: 'mod',
        now: now,
      );

      final v = await createVariantRecord(
        db,
        id: 'v1',
        buildId: 'b1',
        name: 'Default',
        isDefault: true,
        exoticWeaponHash: 777,
        exoticWeaponName: 'W',
        artifactConfig: [1, 2, 3],
        now: now,
      );
      expect(v.isDefault, isTrue);
      expect(v.artifactConfig, [1, 2, 3]);

      final atts = await replaceAttachments(
        db,
        'v1',
        const [
          AttachmentWrite(id: 'a1', setId: 's1', mode: 'live'),
          AttachmentWrite(
            id: 'a2',
            setId: 's2',
            mode: 'snapshot',
            snapshotConfigs: [
              {'slot': 'helmet', 'itemHash': 1, 'itemName': 'H'},
            ],
          ),
        ],
        now,
      );
      expect(atts, hasLength(2));
      expect(atts.map((a) => a.setId).toSet(), {'s1', 's2'});
      expect(atts.firstWhere((a) => a.mode == 'snapshot').snapshotConfigs, isNotNull);

      final listed = await listAttachments(db, 'v1');
      expect(listed, hasLength(2));

      await replaceAttachments(db, 'v1', const [
        AttachmentWrite(id: 'a3', setId: 's1', mode: 'live'),
      ], later);
      expect(await listAttachments(db, 'v1'), hasLength(1));

      // BUG-20260726-016: kept id `…-att-0` must not collide with auto id.
      await replaceAttachments(
        db,
        'v1',
        const [
          AttachmentWrite(id: 'v1-att-0', setId: 's1', mode: 'live'),
          AttachmentWrite(setId: 's2', mode: 'live'),
        ],
        later,
      );
      final mixed = await listAttachments(db, 'v1');
      expect(mixed, hasLength(2));
      expect(mixed.map((a) => a.id).toSet(), {'v1-att-0', 'v1-att-1'});
      expect(mixed.map((a) => a.setId).toSet(), {'s1', 's2'});

      final updated = await updateVariantRecord(
        db,
        'b1',
        'v1',
        name: 'Alt',
        now: later,
      );
      expect(updated!.name, 'Alt');
    });
  });

  group('US2 RESTRICT attach semantics', () {
    test('deleteSet throws SetInUseException when attached', () async {
      final userId = await seedUser();
      await createBuildRecord(
        db,
        userId,
        id: 'b-r',
        name: 'Build R',
        className: 'Warlock',
        now: now,
      );
      await createSetRecord(
        db,
        userId,
        id: 'set-r',
        name: 'Restricted',
        type: 'weapon',
        now: now,
      );
      await createVariantRecord(
        db,
        id: 'v-r',
        buildId: 'b-r',
        name: 'Default',
        now: now,
      );
      await replaceAttachments(
        db,
        'v-r',
        const [AttachmentWrite(id: 'att-r', setId: 'set-r', mode: 'live')],
        now,
      );

      final refs = await findAttachmentsBySetId(db, 'set-r');
      expect(refs, hasLength(1));
      expect(refs.single.buildId, 'b-r');
      expect(refs.single.variantId, 'v-r');
      expect(refs.single.buildName, 'Build R');

      await expectLater(
        deleteSetRecord(db, userId, 'set-r'),
        throwsA(
          isA<SetInUseException>()
              .having((e) => e.setId, 'setId', 'set-r')
              .having((e) => e.attachments, 'attachments', hasLength(1)),
        ),
      );
      expect(await getSet(db, userId, 'set-r'), isNotNull);
    });

    test('deleteSet succeeds after detach; raw RESTRICT still holds', () async {
      final userId = await seedUser();
      await createBuildRecord(
        db,
        userId,
        id: 'b2',
        name: 'B2',
        className: 'Hunter',
        now: now,
      );
      await createSetRecord(
        db,
        userId,
        id: 'set-ok',
        name: 'Free',
        type: 'armor',
        now: now,
      );
      await createVariantRecord(
        db,
        id: 'v2',
        buildId: 'b2',
        name: 'V',
        now: now,
      );
      await replaceAttachments(
        db,
        'v2',
        const [AttachmentWrite(setId: 'set-ok', mode: 'live')],
        now,
      );

      // Detach via replace empty
      await replaceAttachments(db, 'v2', const [], later);
      expect(await findAttachmentsBySetId(db, 'set-ok'), isEmpty);
      expect(await deleteSetRecord(db, userId, 'set-ok'), isTrue);
      expect(await getSet(db, userId, 'set-ok'), isNull);
    });

    test('raw FK RESTRICT blocks set delete when still attached', () async {
      final userId = await seedUser();
      await createBuildRecord(
        db,
        userId,
        id: 'b3',
        name: 'B3',
        className: 'Titan',
        now: now,
      );
      await createSetRecord(
        db,
        userId,
        id: 'set-fk',
        name: 'FK',
        type: 'mod',
        now: now,
      );
      await createVariantRecord(
        db,
        id: 'v3',
        buildId: 'b3',
        name: 'V',
        now: now,
      );
      await replaceAttachments(
        db,
        'v3',
        const [AttachmentWrite(setId: 'set-fk', mode: 'live')],
        now,
      );

      // Bypass repo pre-check — schema RESTRICT must still fail.
      await expectLater(
        (db.delete(db.sets)..where((t) => t.id.equals('set-fk'))).go(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('US3 user scope', () {
    test('list/get do not leak across users', () async {
      final userA = await seedUser(membershipId: 'm-a');
      final userB = await seedUser(membershipId: 'm-b');

      await createBuildRecord(
        db,
        userA,
        id: 'ba',
        name: 'A build',
        className: 'Hunter',
        now: now,
      );
      await createBuildRecord(
        db,
        userB,
        id: 'bb',
        name: 'B build',
        className: 'Titan',
        now: now,
      );
      await createSetRecord(
        db,
        userA,
        id: 'sa',
        name: 'A set',
        type: 'weapon',
        now: now,
      );
      await createSetRecord(
        db,
        userB,
        id: 'sb',
        name: 'B set',
        type: 'weapon',
        now: now,
      );
      await createSynergyRecord(
        db,
        userA,
        id: 'sya',
        name: 'A syn',
        type: 'melee',
        now: now,
      );
      await createSynergyRecord(
        db,
        userB,
        id: 'syb',
        name: 'B syn',
        type: 'melee',
        now: now,
      );

      final buildsA = await listBuilds(db, userA);
      expect(buildsA.map((b) => b.id), ['ba']);
      expect(await getBuild(db, userB, 'ba'), isNull);

      final setsA = await listSets(db, userA);
      expect(setsA.map((s) => s.id), ['sa']);
      expect(await getSet(db, userB, 'sa'), isNull);

      final synA = await listSynergies(db, userA);
      expect(synA.map((s) => s.id), ['sya']);
      expect(await getSynergy(db, userB, 'sya'), isNull);
    });
  });

  group('helpers', () {
    test('findDuplicateSetName', () async {
      final userId = await seedUser();
      await createSetRecord(
        db,
        userId,
        id: 's1',
        name: 'Dup',
        type: 'weapon',
        now: now,
      );
      expect(
        await findDuplicateSetName(
          db,
          userId,
          type: 'weapon',
          name: 'Dup',
        ),
        isTrue,
      );
      expect(
        await findDuplicateSetName(
          db,
          userId,
          type: 'weapon',
          name: 'Dup',
          excludeId: 's1',
        ),
        isFalse,
      );
      expect(
        await findDuplicateSetName(
          db,
          userId,
          type: 'armor',
          name: 'Dup',
        ),
        isFalse,
      );
    });

    test('json_codec soft stats and int arrays', () {
      expect(parseIntJsonArray('[1,2,3]'), [1, 2, 3]);
      expect(encodeIntJsonArray([4, 5]), '[4,5]');
      expect(parseSoftStatTargetsJson('{"x":1}')['x'], 1);
      expect(encodeSoftStatTargetsJson(null), '{}');
    });
  });
}
