import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

CandidatePiece piece({
  required EquipmentSlot slot,
  required int itemHash,
  required String instanceId,
  bool isExotic = false,
  String? setBonusKey,
  Map<ArmorStatName, int> stats = const {
    ArmorStatName.health: 10,
    ArmorStatName.melee: 10,
    ArmorStatName.grenade: 10,
    ArmorStatName.superStat: 10,
    ArmorStatName.classStat: 10,
    ArmorStatName.weapons: 10,
  },
  List<ReuseSetRef> usedInSets = const [],
}) {
  return CandidatePiece(
    slot: slot,
    itemHash: itemHash,
    instanceId: instanceId,
    isExotic: isExotic,
    setBonusKey: setBonusKey,
    statValues: stats,
    usedInSets: usedInSets,
  );
}

List<CandidatePiece> onePerSlot({int meleeBoostLegs = 0}) {
  return [
    piece(slot: EquipmentSlot.helmet, itemHash: 1, instanceId: 'h1'),
    piece(slot: EquipmentSlot.arms, itemHash: 2, instanceId: 'a1'),
    piece(slot: EquipmentSlot.chest, itemHash: 3, instanceId: 'c1'),
    piece(
      slot: EquipmentSlot.legs,
      itemHash: 4,
      instanceId: 'l1',
      stats: {
        ArmorStatName.health: 10,
        ArmorStatName.melee: 10 + meleeBoostLegs,
        ArmorStatName.grenade: 10,
        ArmorStatName.superStat: 10,
        ArmorStatName.classStat: 10,
        ArmorStatName.weapons: 10,
      },
    ),
    piece(slot: EquipmentSlot.classItem, itemHash: 5, instanceId: 'ci1'),
  ];
}

void main() {
  group('optimizeArmorCore US1', () {
    test('one piece per slot yields single combination', () {
      final result = optimizeArmorCore(
        ArmorOptimizeRequest(candidates: onePerSlot()),
      );
      expect(result.combinations, hasLength(1));
      expect(result.combinations.single.pieces, hasLength(5));
      expect(result.truncated, isFalse);
      expect(result.evaluatedCount, 1);
      expect(result.emptyReason, isNull);
      // 5 pieces × 6 stats × 10 = 300
      expect(result.combinations.single.score, 300);
      expect(result.combinations.single.assumedMods, isEmpty);
    });

    test('maxResults truncates ranked list', () {
      final candidates = <CandidatePiece>[
        piece(slot: EquipmentSlot.helmet, itemHash: 1, instanceId: 'h1'),
        piece(slot: EquipmentSlot.helmet, itemHash: 11, instanceId: 'h2'),
        piece(slot: EquipmentSlot.arms, itemHash: 2, instanceId: 'a1'),
        piece(slot: EquipmentSlot.arms, itemHash: 22, instanceId: 'a2'),
        piece(slot: EquipmentSlot.chest, itemHash: 3, instanceId: 'c1'),
        piece(slot: EquipmentSlot.legs, itemHash: 4, instanceId: 'l1'),
        piece(slot: EquipmentSlot.classItem, itemHash: 5, instanceId: 'ci1'),
      ];
      final result = optimizeArmorCore(
        ArmorOptimizeRequest(candidates: candidates, maxResults: 2),
      );
      expect(result.combinations, hasLength(2));
      expect(result.truncated, isTrue);
      expect(result.evaluatedCount, greaterThanOrEqualTo(2));
    });

    test('dual exotic board yields no valid kits', () {
      final candidates = [
        piece(
          slot: EquipmentSlot.helmet,
          itemHash: 100,
          instanceId: 'ex1',
          isExotic: true,
        ),
        piece(
          slot: EquipmentSlot.arms,
          itemHash: 200,
          instanceId: 'ex2',
          isExotic: true,
        ),
        piece(slot: EquipmentSlot.chest, itemHash: 3, instanceId: 'c1'),
        piece(slot: EquipmentSlot.legs, itemHash: 4, instanceId: 'l1'),
        piece(slot: EquipmentSlot.classItem, itemHash: 5, instanceId: 'ci1'),
      ];
      // Only dual-exotic path exists (one piece per remaining slots) — enumerate
      // prunes dual exotic during DFS so kits empty.
      final result = optimizeArmorCore(
        ArmorOptimizeRequest(candidates: candidates),
      );
      expect(result.combinations, isEmpty);
      expect(
        result.emptyReason?.code,
        ArmorOptimizeEmptyReasonCode.noValidKits,
      );
    });

    test('soft thresholds do not filter when requireThresholds false', () {
      final result = optimizeArmorCore(
        ArmorOptimizeRequest(
          candidates: onePerSlot(),
          statThresholds: {ArmorStatName.melee: 999},
          requireThresholds: false,
        ),
      );
      expect(result.combinations, hasLength(1));
      expect(result.combinations.single.meetsSoftThresholds, isFalse);
    });

    test('requireThresholds filters below-target kits', () {
      final low = onePerSlot();
      final high = onePerSlot(meleeBoostLegs: 50)
          .map(
            (p) => p.slot == EquipmentSlot.legs
                ? piece(
                    slot: p.slot,
                    itemHash: 44,
                    instanceId: 'l-high',
                    stats: p.statValues,
                  )
                : p,
          )
          .toList();
      final result = optimizeArmorCore(
        ArmorOptimizeRequest(
          candidates: [...low, ...high.where((p) => p.slot == EquipmentSlot.legs)],
          statThresholds: {ArmorStatName.melee: 50},
          requireThresholds: true,
          maxResults: 10,
        ),
      );
      expect(result.combinations, isNotEmpty);
      for (final c in result.combinations) {
        expect(c.meetsSoftThresholds, isTrue);
      }
    });

    test('empty candidates with hasInventory false → NO_INVENTORY', () {
      final result = optimizeArmorCore(
        const ArmorOptimizeRequest(candidates: [], hasInventory: false),
      );
      expect(result.combinations, isEmpty);
      expect(
        result.emptyReason?.code,
        ArmorOptimizeEmptyReasonCode.noInventory,
      );
    });

    test('ranking prefers higher priority stat', () {
      final legsLow = piece(
        slot: EquipmentSlot.legs,
        itemHash: 4,
        instanceId: 'l-low',
        stats: {
          ArmorStatName.health: 10,
          ArmorStatName.melee: 5,
          ArmorStatName.grenade: 10,
          ArmorStatName.superStat: 10,
          ArmorStatName.classStat: 10,
          ArmorStatName.weapons: 10,
        },
      );
      final legsHigh = piece(
        slot: EquipmentSlot.legs,
        itemHash: 44,
        instanceId: 'l-high',
        stats: {
          ArmorStatName.health: 10,
          ArmorStatName.melee: 40,
          ArmorStatName.grenade: 10,
          ArmorStatName.superStat: 10,
          ArmorStatName.classStat: 10,
          ArmorStatName.weapons: 10,
        },
      );
      final base = onePerSlot().where((p) => p.slot != EquipmentSlot.legs);
      final result = optimizeArmorCore(
        ArmorOptimizeRequest(
          candidates: [...base, legsLow, legsHigh],
          statPriorities: [ArmorStatName.melee],
          maxResults: 2,
        ),
      );
      expect(result.combinations.first.pieces
          .firstWhere((p) => p.slot == EquipmentSlot.legs)
          .instanceId, 'l-high');
    });
  });

  group('validateCombinationPieces', () {
    test('accepts five distinct armor slots', () {
      final pieces = armorOptimizerSlots
          .map(
            (s) => CombinationPieceInput(
              slot: s,
              itemHash: 1,
              instanceId: s.wireName,
            ),
          )
          .toList();
      expect(validateCombinationPieces(pieces), isNull);
    });

    test('rejects incomplete kit', () {
      expect(
        validateCombinationPieces([
          const CombinationPieceInput(
            slot: EquipmentSlot.helmet,
            itemHash: 1,
            instanceId: 'h',
          ),
        ]),
        isNotNull,
      );
    });
  });

  group('explainEmpty', () {
    test('locked exotic unavailable', () {
      final reason = explainEmpty(
        const EmptyReasonInput(
          hasInventory: true,
          classArmorCount: 5,
          lockedExoticItemHash: 99,
          lockedExoticAvailable: false,
          setBonusReachable: true,
        ),
      );
      expect(reason.code, ArmorOptimizeEmptyReasonCode.exoticUnavailable);
    });
  });
}
