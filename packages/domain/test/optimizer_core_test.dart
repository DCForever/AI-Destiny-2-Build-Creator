import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

CandidatePiece piece(
  EquipmentSlot slot,
  int itemHash, {
  bool isExotic = false,
  String? setBonusKey,
  Map<ArmorStatName, int> statValues = const {},
  String? instanceId,
  int energyCapacity = 10,
}) {
  return CandidatePiece(
    slot: slot,
    itemHash: itemHash,
    instanceId: instanceId ?? '${slot.wireName}-$itemHash',
    isExotic: isExotic,
    setBonusKey: setBonusKey,
    statValues: statValues,
    energyCapacity: energyCapacity,
  );
}

List<CandidatePiece> oneEach({
  Map<EquipmentSlot, CandidatePiece Function(CandidatePiece base)>? extra,
}) {
  return [
    for (var i = 0; i < armorOptimizerSlots.length; i++)
      () {
        final slot = armorOptimizerSlots[i];
        final base = piece(slot, 100 + i);
        return extra?[slot]?.call(base) ?? base;
      }(),
  ];
}

CandidatePiece helmet(
  int id,
  int melee, {
  bool isExotic = false,
  String? setBonusKey,
}) {
  return piece(
    EquipmentSlot.helmet,
    id,
    isExotic: isExotic,
    setBonusKey: setBonusKey,
    statValues: {ArmorStatName.melee: melee},
  );
}

List<CandidatePiece> fullKit({
  Map<EquipmentSlot, CandidatePiece Function(CandidatePiece base)>? overrides,
}) {
  return [
    for (var i = 0; i < armorOptimizerSlots.length; i++)
      () {
        final slot = armorOptimizerSlots[i];
        final base = piece(slot, 100 + i);
        return overrides?[slot]?.call(base) ?? base;
      }(),
  ];
}

void main() {
  group('constraints', () {
    test('counts exotics across the kit', () {
      final kit = fullKit(
        overrides: {
          EquipmentSlot.helmet: (b) =>
              piece(b.slot, b.itemHash, isExotic: true),
        },
      );
      expect(countExotics(kit), 1);
    });

    test('rejects kits with two exotics', () {
      final kit = fullKit(
        overrides: {
          EquipmentSlot.helmet: (b) =>
              piece(b.slot, b.itemHash, isExotic: true),
          EquipmentSlot.chest: (b) =>
              piece(b.slot, b.itemHash, isExotic: true),
        },
      );
      expect(isKitValid(kit, const KitConstraints()), isFalse);
    });

    test('requires exactly five distinct slots', () {
      final kit = fullKit().sublist(0, 4);
      expect(isKitValid(kit, const KitConstraints()), isFalse);
    });

    test('requires the locked exotic hash to be present', () {
      final kit = fullKit(
        overrides: {
          EquipmentSlot.helmet: (b) =>
              piece(b.slot, 555, isExotic: true),
        },
      );
      expect(
        isKitValid(kit, const KitConstraints(lockedExoticItemHash: 555)),
        isTrue,
      );
      expect(
        isKitValid(kit, const KitConstraints(lockedExoticItemHash: 999)),
        isFalse,
      );
    });

    test('honors requireExotic', () {
      final kit = fullKit();
      expect(
        isKitValid(kit, const KitConstraints(requireExotic: true)),
        isFalse,
      );
      final exoticKit = fullKit(
        overrides: {
          EquipmentSlot.helmet: (b) =>
              piece(b.slot, b.itemHash, isExotic: true),
        },
      );
      expect(
        isKitValid(exoticKit, const KitConstraints(requireExotic: true)),
        isTrue,
      );
    });

    test('counts set-bonus pieces by key', () {
      final kit = fullKit(
        overrides: {
          EquipmentSlot.helmet: (b) =>
              piece(b.slot, b.itemHash, setBonusKey: 'TechSec'),
          EquipmentSlot.arms: (b) =>
              piece(b.slot, b.itemHash, setBonusKey: 'TechSec'),
          EquipmentSlot.chest: (b) =>
              piece(b.slot, b.itemHash, setBonusKey: 'Bushido'),
        },
      );
      final counts = setBonusPieceCounts(kit);
      expect(counts['TechSec'], 2);
      expect(counts['Bushido'], 1);
    });

    test('satisfies set-bonus goals only when piece counts reach minPieces', () {
      final kit = fullKit(
        overrides: {
          EquipmentSlot.helmet: (b) =>
              piece(b.slot, b.itemHash, setBonusKey: 'TechSec'),
          EquipmentSlot.arms: (b) =>
              piece(b.slot, b.itemHash, setBonusKey: 'TechSec'),
        },
      );
      expect(
        satisfiesSetBonusGoals(kit, [
          const SetBonusCoverageGoal(setBonusKey: 'TechSec', minPieces: 2),
        ]),
        isTrue,
      );
      expect(
        satisfiesSetBonusGoals(kit, [
          const SetBonusCoverageGoal(setBonusKey: 'TechSec', minPieces: 4),
        ]),
        isFalse,
      );
      expect(satisfiesSetBonusGoals(kit, const []), isTrue);
    });

    test('summarizes 2pc/4pc activation', () {
      final kit = fullKit(
        overrides: {
          EquipmentSlot.helmet: (b) =>
              piece(b.slot, b.itemHash, setBonusKey: 'TechSec'),
          EquipmentSlot.arms: (b) =>
              piece(b.slot, b.itemHash, setBonusKey: 'TechSec'),
          EquipmentSlot.chest: (b) =>
              piece(b.slot, b.itemHash, setBonusKey: 'TechSec'),
          EquipmentSlot.legs: (b) =>
              piece(b.slot, b.itemHash, setBonusKey: 'TechSec'),
        },
      );
      final summary = buildSetBonusSummary(kit);
      final tech = summary.firstWhere((s) => s.setBonusKey == 'TechSec');
      expect(tech.pieceCount, 4);
      expect(tech.active2pc, isTrue);
      expect(tech.active4pc, isTrue);
    });
  });

  group('enumerate', () {
    test('returns no kits when a slot is empty', () {
      final pieces =
          oneEach().where((p) => p.slot != EquipmentSlot.legs).toList();
      final result = enumerateKits(
        groupBySlot(pieces),
        const EnumerateOptions(),
      );
      expect(result.kits, isEmpty);
      expect(result.evaluatedCount, 0);
      expect(result.truncated, isFalse);
    });

    test('produces the single complete kit from one piece per slot', () {
      final result = enumerateKits(
        groupBySlot(oneEach()),
        const EnumerateOptions(),
      );
      expect(result.kits, hasLength(1));
      expect(result.kits.single, hasLength(5));
    });

    test('never emits kits with two exotics', () {
      final pieces = [
        piece(EquipmentSlot.helmet, 1, isExotic: true),
        piece(EquipmentSlot.helmet, 2),
        piece(EquipmentSlot.arms, 3, isExotic: true),
        piece(EquipmentSlot.chest, 4),
        piece(EquipmentSlot.legs, 5),
        piece(EquipmentSlot.classItem, 6),
      ];
      final result = enumerateKits(
        groupBySlot(pieces),
        const EnumerateOptions(),
      );
      expect(result.kits, isNotEmpty);
      for (final kit in result.kits) {
        expect(kit.where((p) => p.isExotic).length, lessThanOrEqualTo(1));
      }
    });

    test('filters by locked exotic and set-bonus goals', () {
      final pieces = [
        piece(EquipmentSlot.helmet, 555, isExotic: true, setBonusKey: 'A'),
        piece(EquipmentSlot.helmet, 10, setBonusKey: 'A'),
        piece(EquipmentSlot.arms, 11, setBonusKey: 'A'),
        piece(EquipmentSlot.chest, 12, setBonusKey: 'A'),
        piece(EquipmentSlot.legs, 13),
        piece(EquipmentSlot.classItem, 14),
      ];
      final result = enumerateKits(
        groupBySlot(pieces),
        const EnumerateOptions(
          constraints: KitConstraints(
            lockedExoticItemHash: 555,
            setBonusGoals: [
              SetBonusCoverageGoal(setBonusKey: 'A', minPieces: 2),
            ],
          ),
        ),
      );
      expect(result.kits, isNotEmpty);
      for (final kit in result.kits) {
        expect(kit.any((p) => p.itemHash == 555), isTrue);
      }
    });

    test('truncates and flags when the evaluation cap is hit', () {
      final many = <CandidatePiece>[];
      for (final slot in armorOptimizerSlots) {
        for (var i = 0; i < 4; i++) {
          many.add(piece(slot, i));
        }
      }
      final result = enumerateKits(
        groupBySlot(many),
        const EnumerateOptions(maxCombinations: 10),
      );
      expect(result.truncated, isTrue);
      expect(result.evaluatedCount, lessThanOrEqualTo(11));
    });
  });

  group('prune', () {
    test('keeps only the top-K by prioritized stats', () {
      final pieces = [
        for (var i = 0; i < defaultPruneK + 5; i++) helmet(i, i),
      ];
      final kept = prunePiecesForSlot(
        pieces,
        const PruneOptions(priorities: [ArmorStatName.melee], k: 4),
      );
      expect(kept, hasLength(4));
      final meleeValues = kept
          .map((p) => p.statValues[ArmorStatName.melee] ?? 0)
          .toList()
        ..sort((a, b) => b.compareTo(a));
      expect(meleeValues.first, pieces.length - 1);
    });

    test('always retains locked exotic copies even with low stats', () {
      final pieces = [
        helmet(1, 100),
        helmet(2, 90),
        helmet(555, 1, isExotic: true),
      ];
      final kept = prunePiecesForSlot(
        pieces,
        const PruneOptions(
          priorities: [ArmorStatName.melee],
          k: 1,
          lockedExoticItemHash: 555,
        ),
      );
      expect(kept.any((p) => p.itemHash == 555), isTrue);
    });

    test('retains pieces needed for set-bonus goals', () {
      final pieces = [
        helmet(1, 100),
        helmet(2, 95),
        helmet(3, 1, setBonusKey: 'TechSec'),
      ];
      final kept = prunePiecesForSlot(
        pieces,
        const PruneOptions(
          priorities: [ArmorStatName.melee],
          k: 1,
          setBonusGoals: [
            SetBonusCoverageGoal(setBonusKey: 'TechSec', minPieces: 2),
          ],
        ),
      );
      expect(kept.any((p) => p.setBonusKey == 'TechSec'), isTrue);
    });
  });

  group('score', () {
    List<CandidatePiece> kit(List<Map<ArmorStatName, int>> perPiece) {
      return [
        for (var i = 0; i < armorOptimizerSlots.length; i++)
          piece(
            armorOptimizerSlots[i],
            100 + i,
            statValues: i < perPiece.length ? perPiece[i] : const {},
          ),
      ];
    }

    test('sums each stat across pieces', () {
      final pieces = kit([
        {ArmorStatName.melee: 10},
        {ArmorStatName.melee: 5, ArmorStatName.health: 8},
        {},
        {},
        {},
      ]);
      final stats = estimateKitStats(pieces);
      expect(stats[ArmorStatName.melee], 15);
      expect(stats[ArmorStatName.health], 8);
    });

    test('sums prioritized stats only when priorities provided', () {
      final stats = {
        ArmorStatName.melee: 30,
        ArmorStatName.health: 20,
        ArmorStatName.superStat: 10,
      };
      expect(
        sumPrioritizedStats(stats, [ArmorStatName.melee, ArmorStatName.health]),
        50,
      );
      expect(sumPrioritizedStats(stats, const []), 60);
    });

    test('orders lexicographically by priority stats', () {
      const a = RankableCombination(
        estimatedStats: {
          ArmorStatName.melee: 30,
          ArmorStatName.health: 10,
        },
        reusePieceCount: 0,
      );
      const b = RankableCombination(
        estimatedStats: {
          ArmorStatName.melee: 20,
          ArmorStatName.health: 99,
        },
        reusePieceCount: 0,
      );
      expect(
        compareCombinations(
          a,
          b,
          [ArmorStatName.melee, ArmorStatName.health],
          false,
        ),
        lessThan(0),
      );
    });

    test('breaks priority ties by total stats', () {
      const a = RankableCombination(
        estimatedStats: {
          ArmorStatName.melee: 20,
          ArmorStatName.health: 40,
        },
        reusePieceCount: 0,
      );
      const b = RankableCombination(
        estimatedStats: {
          ArmorStatName.melee: 20,
          ArmorStatName.health: 10,
        },
        reusePieceCount: 0,
      );
      expect(
        compareCombinations(a, b, [ArmorStatName.melee], false),
        lessThan(0),
      );
    });

    test('only uses reuse as a tie-break when preferReuse is set', () {
      const a = RankableCombination(
        estimatedStats: {ArmorStatName.melee: 20},
        reusePieceCount: 0,
      );
      const b = RankableCombination(
        estimatedStats: {ArmorStatName.melee: 20},
        reusePieceCount: 3,
      );
      expect(
        compareCombinations(a, b, [ArmorStatName.melee], false),
        0,
      );
      expect(
        compareCombinations(a, b, [ArmorStatName.melee], true),
        greaterThan(0),
      );
    });

    test('evaluates soft thresholds', () {
      expect(
        meetsSoftThresholds(
          {ArmorStatName.melee: 100},
          {ArmorStatName.melee: 100},
        ),
        isTrue,
      );
      expect(
        meetsSoftThresholds(
          {ArmorStatName.melee: 90},
          {ArmorStatName.melee: 100},
        ),
        isFalse,
      );
      expect(
        meetsSoftThresholds({ArmorStatName.melee: 90}, null),
        isTrue,
      );
    });

    test('marks estimate incomplete when a piece lacks all six stats', () {
      final completeValues = {
        ArmorStatName.health: 1,
        ArmorStatName.melee: 1,
        ArmorStatName.grenade: 1,
        ArmorStatName.superStat: 1,
        ArmorStatName.classStat: 1,
        ArmorStatName.weapons: 1,
      };
      final complete = kit([
        completeValues,
        completeValues,
        completeValues,
        completeValues,
        completeValues,
      ]);
      expect(isEstimateIncomplete(complete), isFalse);
      expect(
        isEstimateIncomplete(kit([
          {ArmorStatName.melee: 5},
        ])),
        isTrue,
      );
    });
  });

  group('package invariants', () {
    test('default max combinations and prune K match product constants', () {
      expect(defaultMaxCombinations, 250000);
      expect(defaultPruneK, 16);
    });

    test('armor optimizer slots match five product armor slots', () {
      expect(
        armorOptimizerSlots.map((s) => s.wireName).toList(),
        ['helmet', 'arms', 'chest', 'legs', 'class_item'],
      );
    });
  });
}
