import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  const now = '2026-07-24T12:00:00.000Z';
  final clock = fixedNow(now);
  final ids = sequentialIds('c');

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedUser() => insertUser(
        db,
        bungieMembershipId: 'm-app-cov',
        membershipType: 3,
        displayName: 'Tester',
      );

  const meleeDesig = SynergyTypeDesignation(
    type: SynergyType('melee'),
    subType: 'Base',
  );

  group('US3 soft coverage query never blocks save', () {
    test('missing evidence returns soft miss; non-default save still ok',
        () async {
      final userId = await seedUser();

      await createUserSynergy(
        db,
        userId,
        const CreateSynergyCommand(
          id: 'syn-1',
          name: 'Melee Loop',
          type: 'melee',
          subType: 'Base',
          links: [
            SynergyLinkWrite(
              id: 'link-1',
              kind: 'weapon',
              displayName: 'Needed Gun',
              itemHash: 777001,
            ),
          ],
        ),
        now: clock,
      );

      final detail = await createUserBuild(
        db,
        userId,
        const CreateBuildCommand(
          id: 'b-cov',
          name: 'Coverage Build',
          className: GuardianClass.hunter,
          subclass: SubclassKit(name: 'Arcstrider'),
          synergyTypes: [meleeDesig],
        ),
        now: clock,
        newId: ids,
      );
      final defaultId = detail.variants.single.id;

      final alt = await createUserVariant(
        db,
        userId,
        'b-cov',
        const CreateVariantCommand(id: 'v-cov', name: 'Soft Miss'),
        now: clock,
      );
      expect(alt, isNotNull);

      await createUserSet(
        db,
        userId,
        const CreateSetCommand(
          id: 'w-other',
          name: 'Other Gun',
          type: SetType.weapon,
        ),
        now: clock,
      );
      await upsertUserSetItem(
        db,
        userId,
        'w-other',
        const UpsertSetItemCommand(
          id: 'wi1',
          slot: 'primary',
          itemHash: 1,
          itemName: 'Not the gun',
        ),
        now: clock,
      );

      final saved = await updateUserVariant(
        db,
        userId,
        'b-cov',
        'v-cov',
        const UpdateVariantCommand(
          attachments: [
            SetAttachmentInput(setId: 'w-other', mode: AttachmentMode.live),
          ],
        ),
        now: clock,
      );
      expect(saved, isNotNull);

      final coverage = await queryVariantCoverage(
        db,
        userId,
        'b-cov',
        'v-cov',
      );
      expect(coverage, isNotNull);
      expect(coverage!.hasSoftMisses, isTrue);
      expect(coverage.coverage.synergies, isNotEmpty);
      expect(
        coverage.coverage.synergies.any((s) => s.tier == CoverageTier.missing),
        isTrue,
      );

      // Soft miss must not prevent another legal non-default save.
      final renamed = await updateUserVariant(
        db,
        userId,
        'b-cov',
        'v-cov',
        const UpdateVariantCommand(name: 'Still Soft'),
        now: clock,
      );
      expect(renamed!.name, 'Still Soft');

      // Soft targets on build still saveable with soft misses present.
      final buildUpdated = await updateUserBuild(
        db,
        userId,
        'b-cov',
        const UpdateBuildCommand(
          softStatTargets: SoftStatTargets({ArmorStatName.weapons: 80}),
        ),
        now: clock,
      );
      expect(buildUpdated!.build.softStatTargets['Weapons'], 80);

      // Coverage does not mutate default attachments.
      final defaultAtts = await getVariantAttachments(db, defaultId);
      expect(defaultAtts, isEmpty);
    });

    test('query returns null for missing build', () async {
      final userId = await seedUser();
      final r = await queryVariantCoverage(db, userId, 'nope', 'nope');
      expect(r, isNull);
    });
  });
}
