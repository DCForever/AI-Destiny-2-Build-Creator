import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  const now = '2026-07-24T12:00:00.000Z';
  const later = '2026-07-24T13:00:00.000Z';
  final clock = fixedNow(now);

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedUser() => insertUser(
        db,
        bungieMembershipId: 'm-app-syn',
        membershipType: 3,
        displayName: 'Tester',
      );

  group('US2 synergy CRUD + designation immutability', () {
    test('rejects weapon link without itemHash (BR-SYN-005)', () async {
      final userId = await seedUser();
      expect(
        () => createUserSynergy(
          db,
          userId,
          const CreateSynergyCommand(
            id: 'bad',
            name: 'Bad',
            type: 'melee',
            links: [
              SynergyLinkWrite(
                kind: 'weapon',
                displayName: 'No Hash',
              ),
            ],
          ),
          now: clock,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.invalidSynergyLink,
          ),
        ),
      );
    });

    test('create → get → domain map', () async {
      final userId = await seedUser();
      final created = await createUserSynergy(
        db,
        userId,
        const CreateSynergyCommand(
          id: 'syn1',
          name: 'Melee Combo',
          type: 'melee',
          subType: 'Base',
          description: 'Punch',
          links: [
            SynergyLinkWrite(
              id: 'l1',
              kind: 'exotic_armor',
              displayName: 'Synthoceps',
              itemHash: 1001,
            ),
          ],
        ),
        now: clock,
      );

      expect(created.id, 'syn1');
      expect(created.type, 'melee');
      expect(created.subType, 'Base');
      expect(created.links, hasLength(1));

      final domain = mapSynergyDomain(created);
      expect(domain.type.wireName, 'melee');
      expect(domain.links.single.kind, SynergyLinkKind.exoticArmor);

      final listed = await listUserSynergies(db, userId, type: 'melee');
      expect(listed, hasLength(1));
    });

    test('required flag round-trips create/edit', () async {
      final userId = await seedUser();
      final created = await createUserSynergy(
        db,
        userId,
        const CreateSynergyCommand(
          id: 'syn-req',
          name: 'Required Links',
          type: 'melee',
          links: [
            SynergyLinkWrite(
              id: 'l-req',
              kind: 'weapon',
              displayName: 'Must Pin',
              itemHash: 42,
              required: true,
            ),
            SynergyLinkWrite(
              id: 'l-soft',
              kind: 'weapon',
              displayName: 'Soft Only',
              itemHash: 43,
              required: false,
            ),
          ],
        ),
        now: clock,
      );
      expect(created.links.where((l) => l.required).length, 1);
      expect(created.links.singleWhere((l) => l.id == 'l-req').required, isTrue);
      expect(
        created.links.singleWhere((l) => l.id == 'l-soft').required,
        isFalse,
      );

      final domain = mapSynergyDomain(created);
      expect(domain.links.singleWhere((l) => l.id == 'l-req').required, isTrue);

      final updated = await updateUserSynergy(
        db,
        userId,
        'syn-req',
        const UpdateSynergyCommand(
          links: [
            SynergyLinkWrite(
              id: 'l-req',
              kind: 'weapon',
              displayName: 'Must Pin',
              itemHash: 42,
              required: false,
            ),
          ],
        ),
        now: fixedNow(later),
      );
      expect(updated!.links.single.required, isFalse);
    });

    test('update description and links keeps designation', () async {
      final userId = await seedUser();
      await createUserSynergy(
        db,
        userId,
        const CreateSynergyCommand(
          id: 'syn1',
          name: 'Melee Combo',
          type: 'melee',
          subType: 'Base',
          links: [
            SynergyLinkWrite(
              kind: 'weapon',
              displayName: 'Tractor',
              itemHash: 9,
            ),
          ],
        ),
        now: clock,
      );

      final updated = await updateUserSynergy(
        db,
        userId,
        'syn1',
        const UpdateSynergyCommand(
          name: 'Melee Combo+',
          description: 'Updated',
          links: [
            SynergyLinkWrite(
              kind: 'exotic_armor',
              displayName: 'Synthoceps',
              itemHash: 1001,
            ),
          ],
        ),
        now: fixedNow(later),
      );

      expect(updated!.name, 'Melee Combo+');
      expect(updated.description, 'Updated');
      expect(updated.type, 'melee');
      expect(updated.subType, 'Base');
      expect(updated.links.single.displayName, 'Synthoceps');
    });

    test('type change rejected', () async {
      final userId = await seedUser();
      await createUserSynergy(
        db,
        userId,
        const CreateSynergyCommand(
          id: 'syn1',
          name: 'Melee',
          type: 'melee',
        ),
        now: clock,
      );

      expect(
        () => updateUserSynergy(
          db,
          userId,
          'syn1',
          const UpdateSynergyCommand(hasType: true, type: 'grenade'),
          now: clock,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.designationImmutable,
          ),
        ),
      );
    });

    test('subType change rejected', () async {
      final userId = await seedUser();
      await createUserSynergy(
        db,
        userId,
        const CreateSynergyCommand(
          id: 'syn1',
          name: 'Melee',
          type: 'melee',
          subType: 'Base',
        ),
        now: clock,
      );

      expect(
        () => updateUserSynergy(
          db,
          userId,
          'syn1',
          const UpdateSynergyCommand(hasSubType: true, subType: 'Other'),
          now: clock,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.designationImmutable,
          ),
        ),
      );
    });

    test('non-creatable type rejected', () async {
      final userId = await seedUser();
      expect(
        () => createUserSynergy(
          db,
          userId,
          const CreateSynergyCommand(
            name: 'Legacy',
            type: 'kinetic_weapon',
          ),
          now: clock,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.invalidSynergyType,
          ),
        ),
      );
    });

    test('invalid link kind rejected', () async {
      final userId = await seedUser();
      expect(
        () => createUserSynergy(
          db,
          userId,
          const CreateSynergyCommand(
            name: 'Bad',
            type: 'melee',
            links: [
              SynergyLinkWrite(kind: 'not_a_kind', displayName: 'X'),
            ],
          ),
          now: clock,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.invalidSynergyLinkKind,
          ),
        ),
      );
    });

    test('delete removes', () async {
      final userId = await seedUser();
      await createUserSynergy(
        db,
        userId,
        const CreateSynergyCommand(id: 'syn1', name: 'X', type: 'verb'),
        now: clock,
      );
      expect(await deleteUserSynergy(db, userId, 'syn1'), isTrue);
      expect(await getUserSynergy(db, userId, 'syn1'), isNull);
    });
  });
}
