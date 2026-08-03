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
      await upsertUserSetItem(
        db,
        userId,
        'w-other',
        const UpsertSetItemCommand(
          id: 'wi2',
          slot: 'special',
          itemHash: 2,
          itemName: 'Also not',
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

    test('Verb:Jolt expands to Element:Arc for library matching', () async {
      final userId = await seedUser();

      await createUserSynergy(
        db,
        userId,
        const CreateSynergyCommand(
          id: 'syn-arc',
          name: 'Element: Arc',
          type: 'element',
          subType: 'Arc',
          links: [
            SynergyLinkWrite(
              id: 'l-arc',
              kind: 'weapon',
              displayName: 'Arc Gun',
              itemHash: 5001,
            ),
          ],
        ),
        now: clock,
      );

      await createUserBuild(
        db,
        userId,
        const CreateBuildCommand(
          id: 'b-verb',
          name: 'Jolt Build',
          className: GuardianClass.warlock,
          subclass: SubclassKit(name: 'Stormcaller'),
          synergyTypes: [
            SynergyTypeDesignation(
              type: SynergyType('verb'),
              subType: 'Jolt',
            ),
          ],
        ),
        now: clock,
        newId: ids,
      );

      final loaded = await loadDesignatedSynergies(
        db,
        userId,
        const [
          SynergyTypeDesignationRecord(type: 'verb', subType: 'Jolt'),
        ],
      );
      // Explicit Verb:Jolt + implied Element:Arc
      expect(loaded.length, greaterThanOrEqualTo(2));
      expect(
        loaded.any(
          (s) => s.type.wireName == 'element' && s.subType == 'Arc',
        ),
        isTrue,
      );
      final arcRow = loaded.firstWhere(
        (s) => s.type.wireName == 'element' && s.subType == 'Arc',
      );
      expect(arcRow.links, isNotEmpty);
      expect(arcRow.links.single.itemHash, 5001);
    });

    test('armor_set_bonus soft tier scores with indexes', () async {
      final userId = await seedUser();
      await createUserSynergy(
        db,
        userId,
        const CreateSynergyCommand(
          id: 'syn-set',
          name: 'Field-Tested',
          type: 'melee',
          subType: 'Base',
          links: [
            SynergyLinkWrite(
              id: 'l-set',
              kind: 'armor_set_bonus',
              displayName: 'Field-Tested 2pc',
              armorSetName: 'Field-Tested',
              armorSetHash: 500,
              bonusPieces: 2,
              bonusName: '2pc',
            ),
          ],
        ),
        now: clock,
      );

      await createUserBuild(
        db,
        userId,
        const CreateBuildCommand(
          id: 'b-set',
          name: 'Set Build',
          className: GuardianClass.titan,
          subclass: SubclassKit(name: 'Sunbreaker'),
          synergyTypes: [meleeDesig],
        ),
        now: clock,
        newId: ids,
      );

      final alt = await createUserVariant(
        db,
        userId,
        'b-set',
        const CreateVariantCommand(id: 'v-set', name: 'Armor kit'),
        now: clock,
      );
      expect(alt, isNotNull);

      await createUserSet(
        db,
        userId,
        const CreateSetCommand(
          id: 'armor-set',
          name: 'Armor',
          type: SetType.armor,
        ),
        now: clock,
      );
      await upsertUserSetItem(
        db,
        userId,
        'armor-set',
        const UpsertSetItemCommand(
          slot: 'helmet',
          itemHash: 101,
          itemName: 'Helm',
        ),
        now: clock,
      );
      await upsertUserSetItem(
        db,
        userId,
        'armor-set',
        const UpsertSetItemCommand(
          slot: 'arms',
          itemHash: 102,
          itemName: 'Arms',
        ),
        now: clock,
      );

      await updateUserVariant(
        db,
        userId,
        'b-set',
        'v-set',
        const UpdateVariantCommand(
          attachments: [
            SetAttachmentInput(
              setId: 'armor-set',
              mode: AttachmentMode.live,
            ),
          ],
        ),
        now: clock,
      );

      const record = SetBonusRecord(
        hash: 500,
        name: 'Field-Tested',
        perks: [SetBonusPerk(requiredCount: 2, name: '2pc')],
      );
      final indexes = loadCoverageIndexes(
        setBonusByItemHash: {101: record, 102: record},
      );

      final coverage = await queryVariantCoverage(
        db,
        userId,
        'b-set',
        'v-set',
        indexes: indexes,
      );
      expect(coverage, isNotNull);
      expect(
        coverage!.coverage.synergies.any(
          (s) => s.tier == CoverageTier.supported,
        ),
        isTrue,
      );
      expect(coverage.coverage.setBonuses, isNotEmpty);
    });
  });

  group('designation aggregation + expand pure helpers', () {
    test('aggregateLinksForDesignation dedupes by coverage key', () {
      final a = Synergy(
        id: '1',
        name: 'A',
        type: const SynergyType('element'),
        subType: 'Arc',
        links: [
          const SynergyLink(
            id: 'l1',
            synergyId: '1',
            kind: SynergyLinkKind.weapon,
            displayName: 'Gun',
            itemHash: 1,
          ),
        ],
      );
      final b = Synergy(
        id: '2',
        name: 'B',
        type: const SynergyType('element'),
        subType: 'Arc',
        links: [
          const SynergyLink(
            id: 'l2',
            synergyId: '2',
            kind: SynergyLinkKind.weapon,
            displayName: 'Gun',
            itemHash: 1,
          ),
          const SynergyLink(
            id: 'l3',
            synergyId: '2',
            kind: SynergyLinkKind.weapon,
            displayName: 'Other',
            itemHash: 2,
          ),
        ],
      );
      final links = aggregateLinksForDesignation([a, b]);
      expect(links, hasLength(2));
    });

    test('impliedElementForVerb Jolt → Arc via expand', () {
      final expanded = expandDesignationsWithImpliedElements([
        const SynergyTypeDesignation(
          type: SynergyType('verb'),
          subType: 'Jolt',
        ),
      ]);
      expect(expanded, hasLength(2));
      expect(expanded[1].type.wireName, 'element');
      expect(expanded[1].subType, 'Arc');
    });
  });
}
