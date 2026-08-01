import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/optimizer/optimizer_candidate_map.dart';
import 'package:destiny2_windows_host/optimizer/optimizer_format.dart';
import 'package:flutter_test/flutter_test.dart';

ArmorCombination _combo({
  int score = 10,
  bool meetsSoft = true,
  int reuse = 0,
}) {
  return ArmorCombination(
    pieces: [
      const ArmorOptimizePiece(
        slot: EquipmentSlot.helmet,
        itemHash: 1,
        instanceId: 'h1',
        itemName: 'Helm A',
        isExotic: false,
      ),
      const ArmorOptimizePiece(
        slot: EquipmentSlot.arms,
        itemHash: 2,
        instanceId: 'a1',
        isExotic: false,
      ),
      const ArmorOptimizePiece(
        slot: EquipmentSlot.chest,
        itemHash: 3,
        instanceId: 'c1',
        isExotic: true,
      ),
      const ArmorOptimizePiece(
        slot: EquipmentSlot.legs,
        itemHash: 4,
        instanceId: 'l1',
        isExotic: false,
      ),
      const ArmorOptimizePiece(
        slot: EquipmentSlot.classItem,
        itemHash: 5,
        instanceId: 'ci1',
        isExotic: false,
      ),
    ],
    estimatedStats: const {
      ArmorStatName.health: 20,
      ArmorStatName.melee: 10,
    },
    incompleteEstimate: false,
    setBonusSummary: const [],
    reusePieceCount: reuse,
    score: score,
    meetsSoftThresholds: meetsSoft,
  );
}

void main() {
  group('optimizer_format', () {
    test('advisory caption forbids silent apply', () {
      expect(kOptimizerAdvisoryCaption.toLowerCase(), contains('confirm'));
      expect(kOptimizerAdvisoryCaption.toLowerCase(), contains('never'));
      expect(kOptimizerAdvisoryCaption.toLowerCase(), contains('write'));
    });

    test('formatEstimatedStatsSummary orders Armor 3.0 stats', () {
      final s = formatEstimatedStatsSummary(const {
        ArmorStatName.melee: 5,
        ArmorStatName.health: 20,
      });
      expect(s, 'Health:20 Melee:5');
    });

    test('formatCombinationPiecesSummary includes exotic marker', () {
      final line = formatCombinationPiecesSummary(_combo());
      expect(line, contains('helmet·Helm A'));
      expect(line, contains('chest·3 (exotic)'));
    });

    test('formatSuggestionTitle includes score and soft flag', () {
      final title = formatSuggestionTitle(
        indexOneBased: 1,
        combo: _combo(score: 42, meetsSoft: false, reuse: 2),
      );
      expect(title, contains('#1'));
      expect(title, contains('score 42'));
      expect(title, contains('reuse 2'));
      expect(title, contains('below soft'));
    });

    test('topCompareWindow caps at top N', () {
      final all = [
        _combo(score: 3),
        _combo(score: 2),
        _combo(score: 1),
        _combo(score: 0),
      ];
      final top = topCompareWindow(all, topN: 3);
      expect(top, hasLength(3));
      expect(top.first.score, 3);
    });

    test('formatOptimizerEmptyReason includes code', () {
      const reason = ArmorOptimizeEmptyReason(
        code: ArmorOptimizeEmptyReasonCode.noInventory,
        message: 'No owned armor',
      );
      expect(formatOptimizerEmptyReason(reason), contains('NO_INVENTORY'));
      expect(formatOptimizerEmptyReason(reason), contains('No owned armor'));
    });

    test('formatTruncationNote when truncated', () {
      final note = formatTruncationNote(
        truncated: true,
        shown: 3,
        total: 3,
      );
      expect(note, isNotNull);
      expect(note!.toLowerCase(), contains('truncated'));
    });

    test('confirm bodies mention cancel / unchanged', () {
      final apply = confirmApplyInPlaceBody(_combo());
      expect(apply.toLowerCase(), contains('cancel'));
      expect(apply.toLowerCase(), contains('unchanged'));
      final mat = confirmMaterializeBody(_combo(), 'My Kit');
      expect(mat, contains('My Kit'));
      expect(mat.toLowerCase(), contains('not modified'));
    });
  });

  group('optimizer_candidate_map', () {
    test('maps inventory buckets to armor slots', () {
      expect(armorSlotFromInventoryBucket('Helmet'), EquipmentSlot.helmet);
      expect(armorSlotFromInventoryBucket('Gauntlets'), EquipmentSlot.arms);
      expect(armorSlotFromInventoryBucket('Chest'), EquipmentSlot.chest);
      expect(armorSlotFromInventoryBucket('Legs'), EquipmentSlot.legs);
      expect(armorSlotFromInventoryBucket('ClassItem'), EquipmentSlot.classItem);
      expect(armorSlotFromInventoryBucket('Kinetic'), isNull);
    });

    test('parseArmorStatValues reads wire names', () {
      final m = parseArmorStatValues({
        'Health': 12,
        'Melee': 8,
        'unknown': 1,
      });
      expect(m[ArmorStatName.health], 12);
      expect(m[ArmorStatName.melee], 8);
      expect(m.length, 2);
    });
  });
}
