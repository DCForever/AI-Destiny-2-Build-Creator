import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  OwnedArmorCompareRow row({
    required String id,
    required int totalHint,
    int? power,
    String name = 'Piece',
    bool exotic = false,
  }) {
    // Spread total across Health for simple ranking.
    return OwnedArmorCompareRow(
      instanceId: id,
      itemHash: 1,
      itemName: name,
      slot: 'helmet',
      isExotic: exotic,
      power: power,
      statValues: {ArmorStatName.health: totalHint},
    );
  }

  group('rankOwnedArmorCompare', () {
    test('ranks by total then EoF', () {
      final ranked = rankOwnedArmorCompare([
        row(id: 'a', totalHint: 30, name: 'Low'),
        row(id: 'b', totalHint: 60, name: 'High'),
        row(id: 'c', totalHint: 45, name: 'Mid'),
      ]);
      expect(ranked.map((r) => r.instanceId).toList(), ['b', 'c', 'a']);
    });
  });

  group('filterOwnedWithInstanceIdentity', () {
    test('drops empty instance ids', () {
      final filtered = filterOwnedWithInstanceIdentity([
        row(id: 'ok', totalHint: 10),
        const OwnedArmorCompareRow(
          instanceId: '',
          itemHash: 2,
          itemName: 'Ghost',
          slot: 'arms',
        ),
        const OwnedArmorCompareRow(
          instanceId: '  ',
          itemHash: 3,
          itemName: 'Ghost2',
          slot: 'chest',
        ),
      ]);
      expect(filtered, hasLength(1));
      expect(filtered.single.instanceId, 'ok');
    });
  });

  group('wouldBlockSecondExotic', () {
    test('blocks second exotic', () {
      expect(
        wouldBlockSecondExotic(
          candidateIsExotic: true,
          otherOccupied: [
            (slot: 'helmet', isExotic: true, name: 'Cuirass'),
          ],
        ),
        isTrue,
      );
      expect(
        wouldBlockSecondExotic(
          candidateIsExotic: true,
          otherOccupied: [
            (slot: 'helmet', isExotic: false, name: 'Plate'),
          ],
        ),
        isFalse,
      );
    });
  });

  group('annotateBonusFit', () {
    test('marks non-exotic goal members', () {
      final rows = annotateBonusFit(
        rows: [
          const OwnedArmorCompareRow(
            instanceId: '1',
            itemHash: 1,
            itemName: 'A',
            slot: 'helmet',
            setBonusKey: 'TechSec',
          ),
          const OwnedArmorCompareRow(
            instanceId: '2',
            itemHash: 2,
            itemName: 'X',
            slot: 'arms',
            isExotic: true,
            setBonusKey: 'TechSec',
          ),
        ],
        goalKeys: const ['TechSec'],
      );
      expect(rows[0].bonusFit, isTrue);
      expect(rows[1].bonusFit, isFalse);
    });
  });
}
