import 'package:destiny2_db/destiny2_db.dart';
import 'package:test/test.dart';

void main() {
  group('preferArmorBaseRollBoard', () {
    test('prefers plug base roll over live ItemStats', () {
      final board = preferArmorBaseRollBoard(
        plugBaseStats: const {
          'Health': 20,
          'Melee': 0,
          'Grenade': 30,
          'Super': 25,
          'Class': 0,
          'Weapons': 0,
        },
        liveStatValues: const {
          'Health': 99,
          'Melee': 99,
          'Grenade': 99,
          'Super': 99,
          'Class': 99,
          'Weapons': 99,
        },
      );
      expect(board, isNotNull);
      expect(board!.stats['Grenade'], 30);
      expect(board.stats['Health'], 20);
      expect(board.total, 75);
      expect(board.incomplete, isFalse);
    });

    test('falls back to live stats when no plug roll', () {
      final board = preferArmorBaseRollBoard(
        plugBaseStats: null,
        liveStatValues: const {'Health': 15, 'Melee': 10},
      );
      expect(board, isNotNull);
      expect(board!.stats['Health'], 15);
    });
  });

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
