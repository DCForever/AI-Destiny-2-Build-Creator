import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

CandidatePiece piece({
  required EquipmentSlot slot,
  required int hash,
  required String instanceId,
  int melee = 10,
}) {
  return CandidatePiece(
    slot: slot,
    itemHash: hash,
    instanceId: instanceId,
    itemName: 'Item $hash',
    isExotic: false,
    statValues: {
      ArmorStatName.health: 10,
      ArmorStatName.melee: melee,
      ArmorStatName.grenade: 10,
      ArmorStatName.superStat: 10,
      ArmorStatName.classStat: 10,
      ArmorStatName.weapons: 10,
    },
  );
}

void main() {
  late AppDatabase db;
  const now = '2026-07-25T12:00:00.000Z';
  final clock = fixedNow(now);
  var idSeq = 0;
  String nextId() => 's-${++idSeq}';

  setUp(() {
    db = AppDatabase.memory();
    idSeq = 0;
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedUser() => insertUser(
        db,
        bungieMembershipId: 'm-improve',
        membershipType: 3,
        displayName: 'Tester',
      );

  group('combinationImprovesCurrent / currentRankable', () {
    test('detects improvement when top ranks higher', () {
      const current = RankableCombination(
        estimatedStats: {ArmorStatName.melee: 20},
        reusePieceCount: 0,
      );
      final top = ArmorCombination(
        pieces: const [],
        estimatedStats: const {ArmorStatName.melee: 50},
        incompleteEstimate: false,
        setBonusSummary: const [],
        reusePieceCount: 0,
        score: 50,
        meetsSoftThresholds: true,
      );
      expect(
        combinationImprovesCurrent(
          current: current,
          top: top,
          constraints: const ArmorSetOptimizerConstraints(
            statPriorities: [ArmorStatName.melee],
          ),
        ),
        isTrue,
      );
    });

    test('currentRankableFromPieces matches instances', () {
      final candidates = [
        piece(slot: EquipmentSlot.helmet, hash: 1, instanceId: 'h1', melee: 30),
      ];
      final rankable = currentRankableFromPieces(
        activeItems: [
          const SetItemRecord(
            id: 'si1',
            setId: 'a1',
            slot: 'helmet',
            itemHash: 1,
            itemName: 'Helm',
            instanceId: 'h1',
            selectedPerks: [],
            modHashes: [],
            sortOrder: 0,
          ),
        ],
        candidates: candidates,
      );
      expect(rankable, isNotNull);
      expect(rankable!.estimatedStats[ArmorStatName.melee], 30);
    });
  });

  group('buildImprovementSuggestions', () {
    test('returns suggestion only when hasImprovement; never writes', () async {
      final userId = await seedUser();
      final build = await createUserBuild(
        db,
        userId,
        CreateBuildCommand(
          id: 'b1',
          name: 'B',
          className: GuardianClass.titan,
          synergyTypes: const [
            SynergyTypeDesignation(type: SynergyType('solar')),
          ],
        ),
        now: clock,
        newId: nextId,
      );
      final constraints = serializeOptimizerConstraints(
        const ArmorSetOptimizerConstraints(preferReuse: false),
      );
      final set = await createUserSet(
        db,
        userId,
        CreateSetCommand(
          id: 'armor-1',
          name: 'Constrained Armor',
          type: SetType.armor,
          optimizerConstraints: constraints,
        ),
        now: clock,
      );
      await upsertUserSetItem(
        db,
        userId,
        set.set.id,
        const UpsertSetItemCommand(
          slot: 'helmet',
          itemHash: 1,
          itemName: 'Weak Helm',
          instanceId: 'h-weak',
          replaceExisting: true,
        ),
        now: clock,
      );
      await upsertUserSetItem(
        db,
        userId,
        set.set.id,
        const UpsertSetItemCommand(
          slot: 'arms',
          itemHash: 2,
          itemName: 'Arms',
          instanceId: 'a-1',
          replaceExisting: true,
        ),
        now: clock,
      );
      await replaceAttachmentByType(
        db,
        userId,
        build.variants.first.id,
        SetType.armor,
        set.set.id,
        now: clock,
      );

      final beforeItems = await listActiveSetItems(db, set.set.id);

      final better = ArmorCombination(
        pieces: [
          ArmorOptimizePiece(
            slot: EquipmentSlot.helmet,
            itemHash: 9,
            instanceId: 'h-strong',
            isExotic: false,
            statValues: const {ArmorStatName.melee: 99},
          ),
          for (final s in [
            EquipmentSlot.arms,
            EquipmentSlot.chest,
            EquipmentSlot.legs,
            EquipmentSlot.classItem,
          ])
            ArmorOptimizePiece(
              slot: s,
              itemHash: 2,
              instanceId: 'x-${s.wireName}',
              isExotic: false,
            ),
        ],
        estimatedStats: const {ArmorStatName.melee: 99},
        incompleteEstimate: false,
        setBonusSummary: const [],
        reusePieceCount: 0,
        score: 99,
        meetsSoftThresholds: true,
      );

      final suggestions = await buildImprovementSuggestions(
        db,
        userId,
        candidates: [
          piece(slot: EquipmentSlot.helmet, hash: 1, instanceId: 'h-weak', melee: 5),
        ],
        optimizeRunner: ({
          required String setId,
          required ArmorSetOptimizerConstraints constraints,
          required List<CandidatePiece> candidates,
        }) async {
          return ArmorOptimizeResponse(
            combinations: [better],
            truncated: false,
            evaluatedCount: 1,
          );
        },
      );

      expect(suggestions, hasLength(1));
      expect(suggestions.single.armorSetId, 'armor-1');
      expect(suggestions.single.hasImprovement, isTrue);
      expect(suggestions.single.betterCombination, isNotNull);

      final afterItems = await listActiveSetItems(db, set.set.id);
      expect(afterItems.map((i) => i.instanceId).toList(),
          beforeItems.map((i) => i.instanceId).toList());
    });

    test('no suggestions without constraints', () async {
      final userId = await seedUser();
      final build = await createUserBuild(
        db,
        userId,
        CreateBuildCommand(
          id: 'b2',
          name: 'B2',
          className: GuardianClass.hunter,
          synergyTypes: const [
            SynergyTypeDesignation(type: SynergyType('arc')),
          ],
        ),
        now: clock,
        newId: nextId,
      );
      final set = await createUserSet(
        db,
        userId,
        const CreateSetCommand(
          id: 'armor-free',
          name: 'Free',
          type: SetType.armor,
        ),
        now: clock,
      );
      await upsertUserSetItem(
        db,
        userId,
        set.set.id,
        const UpsertSetItemCommand(
          slot: 'helmet',
          itemHash: 10,
          itemName: 'H',
        ),
        now: clock,
      );
      await upsertUserSetItem(
        db,
        userId,
        set.set.id,
        const UpsertSetItemCommand(
          slot: 'arms',
          itemHash: 11,
          itemName: 'A',
        ),
        now: clock,
      );
      await replaceAttachmentByType(
        db,
        userId,
        build.variants.first.id,
        SetType.armor,
        set.set.id,
        now: clock,
      );

      final suggestions = await buildImprovementSuggestions(
        db,
        userId,
        candidates: const [],
      );
      expect(suggestions, isEmpty);
    });
  });
}
