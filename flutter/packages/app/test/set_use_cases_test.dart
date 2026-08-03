import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  const now = '2026-07-24T12:00:00.000Z';
  const later = '2026-07-24T13:00:00.000Z';
  final clock = fixedNow(now);
  final ids = sequentialIds('set');

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedUser() => insertUser(
        db,
        bungieMembershipId: 'm-app-set',
        membershipType: 3,
        displayName: 'Tester',
      );

  group('US1 set library CRUD', () {
    test('create → list → get detail domain map', () async {
      final userId = await seedUser();
      final detail = await createUserSet(
        db,
        userId,
        const CreateSetCommand(
          id: 's-weapon-1',
          name: 'Kinetic',
          type: SetType.weapon,
          tagIds: ['pve'],
        ),
        now: clock,
        newId: ids,
      );

      expect(detail.set.id, 's-weapon-1');
      expect(detail.set.name, 'Kinetic');
      expect(detail.set.type, 'weapon');
      expect(detail.domain, isA<GearSet>());
      expect(detail.domain.type, SetType.weapon);
      expect(detail.domain.tagIds, ['pve']);

      final listed = await listUserSets(db, userId, type: SetType.weapon);
      expect(listed, hasLength(1));
      expect(listed.single.id, 's-weapon-1');

      final got = await getSetDetail(db, userId, 's-weapon-1');
      expect(got, isNotNull);
      expect(got!.activeItems, isEmpty);
    });

    test('duplicate name same type fails', () async {
      final userId = await seedUser();
      await createUserSet(
        db,
        userId,
        const CreateSetCommand(
          id: 's1',
          name: 'Kinetic',
          type: SetType.weapon,
        ),
        now: clock,
      );

      expect(
        () => createUserSet(
          db,
          userId,
          const CreateSetCommand(
            id: 's2',
            name: 'Kinetic',
            type: SetType.weapon,
          ),
          now: clock,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.duplicateSetName,
          ),
        ),
      );

      // Same name, different type is ok.
      final other = await createUserSet(
        db,
        userId,
        const CreateSetCommand(
          id: 's3',
          name: 'Kinetic',
          type: SetType.armor,
        ),
        now: clock,
      );
      expect(other.set.type, 'armor');
    });

    test('invalid set type wire parse', () {
      expect(
        () => parseSetTypeWire('foo'),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.invalidSetType,
          ),
        ),
      );
    });

    test('update name and upsert/remove items', () async {
      final userId = await seedUser();
      await createUserSet(
        db,
        userId,
        const CreateSetCommand(
          id: 's1',
          name: 'Armor A',
          type: SetType.armor,
        ),
        now: clock,
      );

      final updated = await updateUserSet(
        db,
        userId,
        's1',
        const UpdateSetCommand(name: 'Armor B', tagIds: ['pvp']),
        now: fixedNow(later),
      );
      expect(updated!.set.name, 'Armor B');
      expect(updated.set.tagIds, ['pvp']);
      expect(updated.set.updatedAt, later);

      final withItem = await upsertUserSetItem(
        db,
        userId,
        's1',
        const UpsertSetItemCommand(
          id: 'si1',
          slot: 'helmet',
          itemHash: 100,
          itemName: 'Helm',
          selectedPerks: [1],
        ),
        now: clock,
      );
      expect(withItem!.activeItems, hasLength(1));
      expect(withItem.activeItems.single.itemHash, 100);
      expect(setItemFromRecord(withItem.activeItems.single).slot, 'helmet');

      final removed = await removeUserSetItem(
        db,
        userId,
        's1',
        'si1',
        now: fixedNow(later),
      );
      expect(removed!.activeItems, isEmpty);
      expect(removed.items, hasLength(1));
    });

    test('delete fails when attached; succeeds when free', () async {
      final userId = await seedUser();
      await createUserSet(
        db,
        userId,
        const CreateSetCommand(id: 's1', name: 'A', type: SetType.armor),
        now: clock,
      );
      await createBuildRecord(
        db,
        userId,
        id: 'b1',
        name: 'Build',
        className: 'Titan',
        now: now,
      );
      await createVariantRecord(
        db,
        id: 'v1',
        buildId: 'b1',
        name: 'Default',
        isDefault: true,
        now: now,
      );
      await replaceAttachments(
        db,
        'v1',
        const [AttachmentWrite(id: 'att-1', setId: 's1', mode: 'live')],
        now,
      );

      final refs = await findAttachmentsBySetId(db, 's1');
      expect(refs, hasLength(1));

      await expectLater(
        deleteUserSet(db, userId, 's1'),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.setInUse,
          ),
        ),
      );
      expect(await getSet(db, userId, 's1'), isNotNull);

      await replaceAttachments(db, 'v1', const [], later);
      expect(await deleteUserSet(db, userId, 's1'), isTrue);
      expect(await getSet(db, userId, 's1'), isNull);
    });

    test('empty name rejected', () async {
      final userId = await seedUser();
      expect(
        () => createUserSet(
          db,
          userId,
          const CreateSetCommand(name: '  ', type: SetType.mod),
          now: clock,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.invalidArgument,
          ),
        ),
      );
    });
  });

  group('BR-SLOT-008/009 set exotic exclusivity', () {
    test('rejects second exotic weapon on a weapon set', () async {
      final userId = await seedUser();
      await createUserSet(
        db,
        userId,
        const CreateSetCommand(
          id: 'w1',
          name: 'Weapons',
          type: SetType.weapon,
        ),
        now: clock,
      );

      final firstMeta = setItemMetaFromCatalog(
        kind: 'weapons',
        slot: 'Kinetic',
        isExotic: true,
        name: 'Witherhoard',
      );
      await upsertUserSetItem(
        db,
        userId,
        'w1',
        UpsertSetItemCommand(
          id: 'si-w',
          slot: 'primary',
          itemHash: 1001,
          itemName: 'Witherhoard',
          itemMeta: firstMeta,
          knownItemMeta: {1001: firstMeta},
        ),
        now: clock,
      );

      final secondMeta = setItemMetaFromCatalog(
        kind: 'weapons',
        slot: 'Power',
        isExotic: true,
        name: 'Gjallarhorn',
      );
      await expectLater(
        upsertUserSetItem(
          db,
          userId,
          'w1',
          UpsertSetItemCommand(
            id: 'si-g',
            slot: 'heavy',
            itemHash: 1002,
            itemName: 'Gjallarhorn',
            itemMeta: secondMeta,
            knownItemMeta: {
              1001: firstMeta,
              1002: secondMeta,
            },
          ),
          now: clock,
        ),
        throwsA(
          isA<UseCaseException>()
              .having((e) => e.code, 'code', UseCaseErrorCode.invalidItem)
              .having(
                (e) => e.message,
                'message',
                matches(RegExp('exotic|Witherhoard', caseSensitive: false)),
              ),
        ),
      );
    });

    test('allows replacing the exotic-holding weapon slot', () async {
      final userId = await seedUser();
      await createUserSet(
        db,
        userId,
        const CreateSetCommand(
          id: 'w2',
          name: 'Weapons',
          type: SetType.weapon,
        ),
        now: clock,
      );

      final firstMeta = setItemMetaFromCatalog(
        kind: 'weapons',
        slot: 'Kinetic',
        isExotic: true,
        name: 'Witherhoard',
      );
      await upsertUserSetItem(
        db,
        userId,
        'w2',
        UpsertSetItemCommand(
          id: 'si-w',
          slot: 'primary',
          itemHash: 1001,
          itemName: 'Witherhoard',
          itemMeta: firstMeta,
          knownItemMeta: {1001: firstMeta},
        ),
        now: clock,
      );

      final replaceMeta = setItemMetaFromCatalog(
        kind: 'weapons',
        slot: 'Kinetic',
        isExotic: true,
        name: 'Outbreak Perfected',
      );
      final replaced = await upsertUserSetItem(
        db,
        userId,
        'w2',
        UpsertSetItemCommand(
          id: 'si-o',
          slot: 'primary',
          itemHash: 1003,
          itemName: 'Outbreak Perfected',
          itemMeta: replaceMeta,
          knownItemMeta: {1003: replaceMeta},
          replaceExisting: true,
        ),
        now: clock,
      );
      expect(replaced!.activeItems, hasLength(1));
      expect(replaced.activeItems.single.itemHash, 1003);
    });

    test('rejects second exotic armor (incl. class item) on armor set', () async {
      final userId = await seedUser();
      await createUserSet(
        db,
        userId,
        const CreateSetCommand(
          id: 'a1',
          name: 'Armor',
          type: SetType.armor,
        ),
        now: clock,
      );

      final helmMeta = setItemMetaFromCatalog(
        kind: 'armor',
        slot: 'Helmet',
        isExotic: true,
        name: 'Synthoceps',
      );
      await upsertUserSetItem(
        db,
        userId,
        'a1',
        UpsertSetItemCommand(
          id: 'si-h',
          slot: 'helmet',
          itemHash: 2001,
          itemName: 'Synthoceps',
          itemMeta: helmMeta,
          knownItemMeta: {2001: helmMeta},
        ),
        now: clock,
      );

      final classMeta = setItemMetaFromCatalog(
        kind: 'armor',
        slot: 'ClassItem',
        isExotic: true,
        name: 'Hoarfrost-Z',
      );
      await expectLater(
        upsertUserSetItem(
          db,
          userId,
          'a1',
          UpsertSetItemCommand(
            id: 'si-c',
            slot: 'class_item',
            itemHash: 2002,
            itemName: 'Hoarfrost-Z',
            itemMeta: classMeta,
            knownItemMeta: {
              2001: helmMeta,
              2002: classMeta,
            },
          ),
          now: clock,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.invalidItem,
          ),
        ),
      );
    });

    test('assertUserSetPassesSaveRules rejects under-min weapon', () async {
      final userId = await seedUser();
      await createUserSet(
        db,
        userId,
        const CreateSetCommand(
          id: 'w-min',
          name: 'Sparse',
          type: SetType.weapon,
        ),
        now: clock,
      );
      await upsertUserSetItem(
        db,
        userId,
        'w-min',
        const UpsertSetItemCommand(
          slot: 'primary',
          itemHash: 1,
          itemName: 'One',
        ),
        now: clock,
      );

      expect(
        () => assertUserSetPassesSaveRules(db, userId, 'w-min'),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.setMinItems,
          ),
        ),
      );

      // Create empty scaffold still allowed (BR-SLOT-005 / create ungated).
      final empty = await createUserSet(
        db,
        userId,
        const CreateSetCommand(
          id: 'w-empty',
          name: 'Empty scaffold',
          type: SetType.weapon,
        ),
        now: clock,
      );
      expect(empty.activeItems, isEmpty);

      // Name update stays ungated.
      final renamed = await updateUserSet(
        db,
        userId,
        'w-empty',
        const UpdateSetCommand(name: 'Still empty'),
        now: fixedNow(later),
      );
      expect(renamed!.set.name, 'Still empty');
    });

    test('assertUserSetPassesSaveRules accepts ≥2 weapon items', () async {
      final userId = await seedUser();
      await createUserSet(
        db,
        userId,
        const CreateSetCommand(
          id: 'w-ok',
          name: 'Ready',
          type: SetType.weapon,
        ),
        now: clock,
      );
      await upsertUserSetItem(
        db,
        userId,
        'w-ok',
        const UpsertSetItemCommand(
          slot: 'primary',
          itemHash: 1,
          itemName: 'A',
        ),
        now: clock,
      );
      await upsertUserSetItem(
        db,
        userId,
        'w-ok',
        const UpsertSetItemCommand(
          slot: 'special',
          itemHash: 2,
          itemName: 'B',
        ),
        now: clock,
      );
      await assertUserSetPassesSaveRules(db, userId, 'w-ok');
    });

    test('allows legendary after one exotic weapon', () async {
      final userId = await seedUser();
      await createUserSet(
        db,
        userId,
        const CreateSetCommand(
          id: 'w3',
          name: 'Weapons',
          type: SetType.weapon,
        ),
        now: clock,
      );

      final exo = setItemMetaFromCatalog(
        kind: 'weapons',
        slot: 'Kinetic',
        isExotic: true,
        name: 'X',
      );
      await upsertUserSetItem(
        db,
        userId,
        'w3',
        UpsertSetItemCommand(
          slot: 'primary',
          itemHash: 1,
          itemName: 'X',
          itemMeta: exo,
          knownItemMeta: {1: exo},
        ),
        now: clock,
      );

      final leg = setItemMetaFromCatalog(
        kind: 'weapons',
        slot: 'Energy',
        isExotic: false,
        name: 'Leg',
      );
      final ok = await upsertUserSetItem(
        db,
        userId,
        'w3',
        UpsertSetItemCommand(
          slot: 'special',
          itemHash: 2,
          itemName: 'Leg',
          itemMeta: leg,
          knownItemMeta: {1: exo, 2: leg},
        ),
        now: clock,
      );
      expect(ok!.activeItems, hasLength(2));
    });
  });
}
