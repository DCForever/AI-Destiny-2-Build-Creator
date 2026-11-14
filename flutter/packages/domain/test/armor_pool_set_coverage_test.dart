import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('computeArmorPoolSetCoverage', () {
    test('counts sets with 2+/1/0 per slot from synthetic inventory', () {
      // Three sets in universe. Helmet: setA has 2, setB has 1, setC has 0.
      const setA = 'set:100';
      const setB = 'set:200';
      const setC = 'set:300';
      final items = <FillInInventoryItem>[
        _piece(
          id: '1',
          hash: 1,
          slot: EquipmentSlot.helmet,
          setHash: 100,
        ),
        _piece(
          id: '2',
          hash: 2,
          slot: EquipmentSlot.helmet,
          setHash: 100,
        ),
        _piece(
          id: '3',
          hash: 3,
          slot: EquipmentSlot.helmet,
          setHash: 200,
        ),
        // Arms: setA 2, setB 2, setC 2 → all 2+
        for (final setHash in [100, 200, 300]) ...[
          _piece(
            id: 'a$setHash-1',
            hash: setHash + 10,
            slot: EquipmentSlot.arms,
            setHash: setHash,
          ),
          _piece(
            id: 'a$setHash-2',
            hash: setHash + 11,
            slot: EquipmentSlot.arms,
            setHash: setHash,
          ),
        ],
      ];

      final report = computeArmorPoolSetCoverage(
        items: items,
        guardianClass: GuardianClass.warlock,
        knownSetKeys: {setA, setB, setC},
      );

      expect(report.setUniverseCount, 3);
      expect(report.slotGoalsTotal, 15); // 3 sets × 5 slots

      final helmet = report.slotRows
          .singleWhere((r) => r.slot == EquipmentSlot.helmet);
      expect(helmet.setsWithTwoPlus, 1);
      expect(helmet.setsWithOne, 1);
      expect(helmet.setsWithNone, 1);

      final arms =
          report.slotRows.singleWhere((r) => r.slot == EquipmentSlot.arms);
      expect(arms.setsWithTwoPlus, 3);
      expect(arms.setsWithOne, 0);
      expect(arms.setsWithNone, 0);

      // Exotics ignored for set coverage.
      final withExotic = computeArmorPoolSetCoverage(
        items: [
          ...items,
          _piece(
            id: 'ex',
            hash: 999,
            slot: EquipmentSlot.helmet,
            setHash: null,
            exotic: true,
          ),
        ],
        guardianClass: GuardianClass.warlock,
        knownSetKeys: {setA, setB, setC},
      );
      expect(
        withExotic.slotRows
            .singleWhere((r) => r.slot == EquipmentSlot.helmet)
            .setsWithTwoPlus,
        1,
      );
    });

    test('empty inventory with known sets → all none', () {
      final report = computeArmorPoolSetCoverage(
        items: const [],
        guardianClass: GuardianClass.warlock,
        knownSetKeys: {'set:1', 'set:2'},
      );
      expect(report.setUniverseCount, 2);
      for (final row in report.slotRows) {
        expect(row.setsWithTwoPlus, 0);
        expect(row.setsWithOne, 0);
        expect(row.setsWithNone, 2);
      }
      expect(report.slotGoalsMet, 0);
    });
  });

  group('armorLocationFromDimOwner', () {
    test('maps vault / character / postmaster', () {
      expect(armorLocationFromDimOwner('Vault'), 'vault');
      expect(armorLocationFromDimOwner('Warlock(1823)'), 'character');
      expect(armorLocationFromDimOwner('Postmaster'), 'postmaster');
      expect(armorLocationFromDimOwner(null), isNull);
    });
  });

  group('formatOptimizerSetBonusBox', () {
    test('formats 4pc and 2pc+2pc', () {
      expect(
        formatOptimizerSetBonusBox(const [
          (
            setBonusKey: 'Techsec',
            pieceCount: 4,
            active2pc: true,
            active4pc: true,
          ),
        ]),
        '4pc Techsec',
      );
      expect(
        formatOptimizerSetBonusBox(const [
          (
            setBonusKey: 'A',
            pieceCount: 2,
            active2pc: true,
            active4pc: false,
          ),
          (
            setBonusKey: 'B',
            pieceCount: 2,
            active2pc: true,
            active4pc: false,
          ),
        ]),
        '2pc A + 2pc B',
      );
    });
  });

  group('candidatesFromDimArmorItems', () {
    test('maps class-filtered armor with stats and set keys', () {
      final items = [
        _piece(
          id: '1',
          hash: 10,
          slot: EquipmentSlot.helmet,
          setHash: 55,
          stats: const {ArmorStatName.health: 20},
        ),
        _piece(
          id: 'titan',
          hash: 11,
          slot: EquipmentSlot.helmet,
          setHash: 55,
          cls: GuardianClass.titan,
        ),
      ];
      final cands = candidatesFromDimArmorItems(
        items: items,
        guardianClass: GuardianClass.warlock,
      );
      expect(cands, hasLength(1));
      expect(cands.single.instanceId, '1');
      expect(cands.single.setBonusKey, 'set:55');
      expect(cands.single.statValues[ArmorStatName.health], 20);
    });
  });
}

FillInInventoryItem _piece({
  required String id,
  required int hash,
  required EquipmentSlot slot,
  int? setHash,
  bool exotic = false,
  GuardianClass cls = GuardianClass.warlock,
  Map<ArmorStatName, int> stats = const {},
}) {
  return FillInInventoryItem(
    instanceId: id,
    itemHash: hash,
    slot: slot,
    isExotic: exotic,
    guardianClass: cls,
    armorSetHash: exotic ? null : setHash,
    name: 'Piece $hash',
    location: 'vault',
    statValues: stats,
  );
}
