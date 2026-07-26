import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  const now = '2026-07-25T12:00:00.000Z';
  final clock = fixedNow(now);
  var idSeq = 0;
  String nextId() => 'id-${++idSeq}';

  setUp(() {
    db = AppDatabase.memory();
    idSeq = 0;
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedUser() => insertUser(
        db,
        bungieMembershipId: 'm-finish-wt',
        membershipType: 3,
        displayName: 'Tester',
      );

  Future<({String buildId, String variantId})> seedBuild(int userId) async {
    final detail = await createUserBuild(
      db,
      userId,
      CreateBuildCommand(
        id: 'b1',
        name: 'Solar Titan',
        className: GuardianClass.titan,
        synergyTypes: const [
          SynergyTypeDesignation(type: SynergyType('solar')),
        ],
      ),
      now: clock,
      newId: nextId,
    );
    return (buildId: detail.build.id, variantId: detail.variants.first.id);
  }

  group('createSetAndAttach', () {
    test('creates empty set with inherited name and live-attaches', () async {
      final userId = await seedUser();
      final ids = await seedBuild(userId);

      final result = await createSetAndAttach(
        db,
        userId,
        CreateSetAndAttachCommand(
          buildId: ids.buildId,
          variantId: ids.variantId,
          type: SetType.armor,
        ),
        now: clock,
        newId: nextId,
      );

      expect(result.set.set.name, 'Solar Titan Armor');
      expect(result.set.set.type, 'armor');
      expect(result.set.set.tagIds, isEmpty);
      expect(result.attachmentSetId, result.set.set.id);

      final atts = await listAttachments(db, ids.variantId);
      expect(atts, hasLength(1));
      expect(atts.single.setId, result.set.set.id);
      expect(atts.single.mode, AttachmentMode.live.wireName);
    });

    test('allocates unique name on duplicate', () async {
      final userId = await seedUser();
      final ids = await seedBuild(userId);
      await createUserSet(
        db,
        userId,
        const CreateSetCommand(
          id: 'existing',
          name: 'Solar Titan Armor',
          type: SetType.armor,
        ),
        now: clock,
      );

      final result = await createSetAndAttach(
        db,
        userId,
        CreateSetAndAttachCommand(
          buildId: ids.buildId,
          variantId: ids.variantId,
          type: SetType.armor,
        ),
        now: clock,
        newId: nextId,
      );
      expect(result.set.set.name, 'Solar Titan Armor (2)');
    });
  });

  group('createSetsFromBuild capture', () {
    test('captures armor claims and attaches', () async {
      final userId = await seedUser();
      final ids = await seedBuild(userId);

      final result = await createSetsFromBuild(
        db,
        userId,
        CreateSetsFromBuildCommand(
          buildId: ids.buildId,
          variantId: ids.variantId,
          categories: const [FinishCategory.armor],
          claimsByCategory: {
            FinishCategory.armor: const [
              CaptureClaim(
                slot: 'helmet',
                itemHash: 101,
                itemName: 'Helm',
                instanceId: 'i-h',
              ),
              CaptureClaim(
                slot: 'arms',
                itemHash: 102,
                itemName: 'Arms',
                instanceId: 'i-a',
              ),
            ],
          },
        ),
        now: clock,
        newId: nextId,
      );

      expect(result.createdSets, hasLength(1));
      expect(result.createdSets.single.type, SetType.armor);
      final detail = await getSetDetail(db, userId, result.createdSets.single.id);
      expect(detail!.activeItems, hasLength(2));
      expect(parseOptimizerConstraints(detail.set.optimizerConstraints), isNotNull);

      final atts = await listAttachments(db, ids.variantId);
      expect(atts.single.setId, result.createdSets.single.id);
    });

    test('NOTHING_TO_CREATE when no claims', () async {
      final userId = await seedUser();
      final ids = await seedBuild(userId);
      expect(
        () => createSetsFromBuild(
          db,
          userId,
          CreateSetsFromBuildCommand(
            buildId: ids.buildId,
            variantId: ids.variantId,
            categories: const [FinishCategory.armor, FinishCategory.mod],
          ),
          now: clock,
          newId: nextId,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.message,
            'message',
            'NOTHING_TO_CREATE',
          ),
        ),
      );
    });
  });
}
