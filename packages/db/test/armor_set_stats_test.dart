import 'package:destiny2_db/destiny2_db.dart';
import 'package:test/test.dart';

void main() {
  group('sumArmorSetStats', () {
    test('sums EoF six-stat pieces and grandTotal', () {
      final totals = sumArmorSetStats([
        const ArmorStatPieceInput(
          instanceId: 'a',
          stats: {
            'Health': 20,
            'Melee': 10,
            'Grenade': 10,
            'Super': 10,
            'Class': 10,
            'Weapons': 10,
          },
        ),
        const ArmorStatPieceInput(
          instanceId: 'b',
          stats: {
            'Health': 5,
            'Melee': 5,
            'Grenade': 5,
            'Super': 5,
            'Class': 5,
            'Weapons': 5,
          },
        ),
      ]);
      expect(totals.piecesWithStats, 2);
      expect(totals.statValues['Health'], 25);
      expect(totals.statValues['Weapons'], 15);
      expect(totals.grandTotal, 100);
      expect(totals.incomplete, isFalse);
    });

    test('wishlist pieces do not invent zeros', () {
      final totals = sumArmorSetStats([
        const ArmorStatPieceInput(), // wishlist — no instance
        const ArmorStatPieceInput(
          instanceId: 'pin',
          stats: {
            'Health': 12,
            'Melee': 8,
            'Grenade': 8,
            'Super': 8,
            'Class': 8,
            'Weapons': 8,
          },
        ),
      ]);
      expect(totals.piecesWithStats, 1);
      expect(totals.statValues['Health'], 12);
      expect(totals.grandTotal, 52);
      expect(totals.incomplete, isFalse);
    });

    test('pinned instance without stats marks incomplete', () {
      final totals = sumArmorSetStats([
        const ArmorStatPieceInput(instanceId: 'missing-rolls'),
      ]);
      expect(totals.piecesWithStats, 0);
      expect(totals.statValues, isEmpty);
      expect(totals.incomplete, isTrue);
      expect(totals.grandTotal, 0);
    });

    test('fromBoard null yields no contribution', () {
      final piece = ArmorStatPieceInput.fromBoard(null, instanceId: null);
      final totals = sumArmorSetStats([piece]);
      expect(totals.piecesWithStats, 0);
      expect(totals.incomplete, isFalse);
    });

    test('incomplete piece propagates incomplete flag', () {
      final board = buildArmorBaseStatBoard(const {
        'Health': 10,
        'Melee': 10,
      });
      final piece =
          ArmorStatPieceInput.fromBoard(board, instanceId: 'partial');
      final totals = sumArmorSetStats([piece]);
      expect(totals.piecesWithStats, 1);
      expect(totals.incomplete, isTrue);
      expect(totals.statValues['Health'], 10);
    });
  });
}
