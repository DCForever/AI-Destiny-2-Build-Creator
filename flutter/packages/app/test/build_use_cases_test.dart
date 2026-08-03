import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  const now = '2026-07-24T12:00:00.000Z';
  final clock = fixedNow(now);
  final ids = sequentialIds('b');

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedUser() => insertUser(
        db,
        bungieMembershipId: 'm-app-build',
        membershipType: 3,
        displayName: 'Tester',
      );

  const meleeDesig = SynergyTypeDesignation(
    type: SynergyType('melee'),
    subType: 'Base',
  );

  group('US1 build identity hard gates', () {
    test('NO_SYNERGY blocks create and writes nothing', () async {
      final userId = await seedUser();
      await expectLater(
        () => createUserBuild(
          db,
          userId,
          const CreateBuildCommand(
            className: GuardianClass.hunter,
            synergyTypes: [],
          ),
          now: clock,
          newId: ids,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.noSynergy,
          ),
        ),
      );
      expect(await listUserBuilds(db, userId), isEmpty);
    });

    test('legal create persists tree on build + kit pieces on default variant',
        () async {
      final userId = await seedUser();
      final detail = await createUserBuild(
        db,
        userId,
        const CreateBuildCommand(
          id: 'build-1',
          name: 'Arc Hunter',
          className: GuardianClass.hunter,
          subclass: SubclassKit(name: 'Arcstrider', aspects: ['Flow State']),
          synergyTypes: [meleeDesig],
        ),
        now: clock,
        newId: ids,
      );

      expect(detail.build.id, 'build-1');
      expect(detail.build.name, 'Arc Hunter');
      expect(detail.build.className, 'Hunter');
      expect(detail.variants, hasLength(1));
      expect(detail.variants.single.isDefault, isTrue);
      expect(detail.domain.synergyTypes, hasLength(1));
      expect(detail.domain.subclass.name, 'Arcstrider');
      // Tree-only on Build; pieces on default variant (DBR-SUB-001/003).
      final tree = subclassKitFromJson(detail.build.subclass);
      expect(tree.name, 'Arcstrider');
      expect(tree.aspects, isEmpty);
      final pieces = subclassKitFromJson(detail.variants.single.subclassKit);
      expect(pieces.aspects, ['Flow State']);

      final listed = await listUserBuilds(db, userId);
      expect(listed, hasLength(1));
    });

    test('ILLEGAL_SUBCLASS_KIT blocks too many aspects', () async {
      final userId = await seedUser();
      await expectLater(
        () => createUserBuild(
          db,
          userId,
          const CreateBuildCommand(
            className: GuardianClass.warlock,
            subclass: SubclassKit(
              aspects: ['A', 'B', 'C'],
            ),
            synergyTypes: [meleeDesig],
          ),
          now: clock,
          newId: ids,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.illegalSubclassKit,
          ),
        ),
      );
      expect(await listUserBuilds(db, userId), isEmpty);
    });

    test('EXOTIC_ABILITY_MISMATCH blocks mismatched kit', () async {
      final userId = await seedUser();
      final ports = HardGatePorts(
        lookupAbilityRequirements: ({int? hash, String? name}) {
          if (hash == 999) {
            return const AbilityKit(melee: 'Required Melee');
          }
          return null;
        },
      );

      await expectLater(
        () => createUserBuild(
          db,
          userId,
          const CreateBuildCommand(
            className: GuardianClass.titan,
            exoticArmorHash: 999,
            exoticArmorName: 'Test Exotic',
            subclass: SubclassKit(melee: 'Wrong Melee'),
            synergyTypes: [meleeDesig],
          ),
          now: clock,
          newId: ids,
          ports: ports,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.exoticAbilityMismatch,
          ),
        ),
      );
    });

    test('update softStatTargets alone does not hard-block', () async {
      final userId = await seedUser();
      await createUserBuild(
        db,
        userId,
        const CreateBuildCommand(
          id: 'build-soft',
          name: 'Soft Targets',
          className: GuardianClass.hunter,
          synergyTypes: [meleeDesig],
        ),
        now: clock,
        newId: ids,
      );

      final updated = await updateUserBuild(
        db,
        userId,
        'build-soft',
        const UpdateBuildCommand(
          softStatTargets: SoftStatTargets({ArmorStatName.melee: 100}),
        ),
        now: clock,
      );
      expect(updated, isNotNull);
      expect(updated!.build.softStatTargets['Melee'], 100);
      expect(updated.domain.softStatTargets[ArmorStatName.melee], 100);
    });

    test('update clearing synergies hard-blocks NO_SYNERGY', () async {
      final userId = await seedUser();
      await createUserBuild(
        db,
        userId,
        const CreateBuildCommand(
          id: 'build-syn',
          name: 'Has Syn',
          className: GuardianClass.hunter,
          synergyTypes: [meleeDesig],
        ),
        now: clock,
        newId: ids,
      );

      // Empty synergy list is an identity change — Confirm first, then hard NO_SYNERGY.
      await expectLater(
        () => updateUserBuild(
          db,
          userId,
          'build-syn',
          const UpdateBuildCommand(
            synergyTypes: [],
            identityAction: IdentityAction.confirm,
          ),
          now: clock,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.noSynergy,
          ),
        ),
      );
      final still = await getBuildDetail(db, userId, 'build-syn');
      expect(still!.build.synergyTypes, isNotEmpty);
    });

    test('delete removes build', () async {
      final userId = await seedUser();
      await createUserBuild(
        db,
        userId,
        const CreateBuildCommand(
          id: 'build-del',
          name: 'Gone',
          className: GuardianClass.hunter,
          synergyTypes: [meleeDesig],
        ),
        now: clock,
        newId: ids,
      );
      expect(await deleteUserBuild(db, userId, 'build-del'), isTrue);
      expect(await getBuildDetail(db, userId, 'build-del'), isNull);
    });
  });

  group('US1 identity Confirm/Fork (DART-064)', () {
    const grenadeDesig = SynergyTypeDesignation(
      type: SynergyType('grenade'),
    );

    test('IDENTITY_CONFIRM_REQUIRED without identityAction', () async {
      final userId = await seedUser();
      await createUserBuild(
        db,
        userId,
        const CreateBuildCommand(
          id: 'build-id',
          name: 'Identity',
          className: GuardianClass.hunter,
          synergyTypes: [meleeDesig],
        ),
        now: clock,
        newId: ids,
      );

      await expectLater(
        () => updateUserBuild(
          db,
          userId,
          'build-id',
          const UpdateBuildCommand(synergyTypes: [grenadeDesig]),
          now: clock,
        ),
        throwsA(
          isA<UseCaseException>()
              .having(
                (e) => e.code,
                'code',
                UseCaseErrorCode.identityConfirmRequired,
              )
              .having(
                (e) => e.details['identityFields'],
                'fields',
                contains('synergyTypes'),
              ),
        ),
      );
      final still = await getBuildDetail(db, userId, 'build-id');
      expect(still!.build.synergyTypes.single.type, 'melee');
    });

    test('confirm applies identity in place', () async {
      final userId = await seedUser();
      await createUserBuild(
        db,
        userId,
        const CreateBuildCommand(
          id: 'build-confirm',
          name: 'Confirm Me',
          className: GuardianClass.hunter,
          synergyTypes: [meleeDesig],
        ),
        now: clock,
        newId: ids,
      );

      final updated = await updateUserBuild(
        db,
        userId,
        'build-confirm',
        const UpdateBuildCommand(
          synergyTypes: [grenadeDesig],
          identityAction: IdentityAction.confirm,
        ),
        now: clock,
      );
      expect(updated!.build.id, 'build-confirm');
      expect(updated.build.synergyTypes.single.type, 'grenade');
      expect(updated.forkedFromId, isNull);
    });

    test('fork creates new build and leaves original', () async {
      final userId = await seedUser();
      await createUserBuild(
        db,
        userId,
        const CreateBuildCommand(
          id: 'build-fork-src',
          name: 'Fork Source',
          className: GuardianClass.titan,
          pinnedSuper: 'Hammer of Sol',
          synergyTypes: [meleeDesig],
        ),
        now: clock,
        newId: ids,
      );

      final forked = await updateUserBuild(
        db,
        userId,
        'build-fork-src',
        const UpdateBuildCommand(
          setPinnedSuper: true,
          pinnedSuper: 'Thundercrash',
          identityAction: IdentityAction.fork,
        ),
        now: clock,
        newId: sequentialIds('fork'),
      );
      expect(forked, isNotNull);
      expect(forked!.build.id, isNot('build-fork-src'));
      expect(forked.forkedFromId, 'build-fork-src');
      expect(forked.build.pinnedSuper, 'Thundercrash');
      expect(forked.build.name, 'Fork Source (fork)');

      final original = await getBuildDetail(db, userId, 'build-fork-src');
      expect(original!.build.pinnedSuper, 'Hammer of Sol');
    });

    test('softStatTargets alone does not require identityAction', () async {
      final userId = await seedUser();
      await createUserBuild(
        db,
        userId,
        const CreateBuildCommand(
          id: 'build-soft2',
          name: 'Soft2',
          className: GuardianClass.hunter,
          synergyTypes: [meleeDesig],
        ),
        now: clock,
        newId: ids,
      );
      final updated = await updateUserBuild(
        db,
        userId,
        'build-soft2',
        const UpdateBuildCommand(
          softStatTargets: SoftStatTargets({ArmorStatName.superStat: 80}),
        ),
        now: clock,
      );
      expect(updated!.build.softStatTargets['Super'], 80);
    });
  });
}

