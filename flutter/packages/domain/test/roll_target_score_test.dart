import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('validateRollTarget', () {
    test('accepts disjoint preferred and avoid', () {
      final t = WeaponRollTarget(
        id: '1',
        userId: 'u',
        weaponKey: '100',
        name: 'PvE',
        columns: [
          RollTargetColumn(
            columnKey: 'trait1',
            preferredPlugHashes: {1, 2},
            avoidPlugHashes: {3, 4},
          ),
        ],
      );
      expect(() => validateRollTarget(t), returnsNormally);
    });

    test('rejects preferred ∩ avoid overlap', () {
      final t = WeaponRollTarget(
        id: '1',
        userId: 'u',
        weaponKey: '100',
        name: 'PvE',
        columns: [
          RollTargetColumn(
            columnKey: 'trait1',
            preferredPlugHashes: {1, 2},
            avoidPlugHashes: {2, 3},
          ),
        ],
      );
      expect(
        () => validateRollTarget(t),
        throwsA(
          isA<RollTargetValidationException>().having(
            (e) => e.code,
            'code',
            'ROLL_TARGET_PREFERRED_AVOID_OVERLAP',
          ),
        ),
      );
    });

    test('rejects exotic weapons (DBR-IDL-009)', () {
      expect(weaponAllowsRollTargets(isExotic: true), isFalse);
      expect(weaponAllowsRollTargets(isExotic: false), isTrue);
      final t = WeaponRollTarget(
        id: '1',
        userId: 'u',
        weaponKey: '999',
        name: 'PvE',
        columns: const [
          RollTargetColumn(
            columnKey: 'trait1',
            preferredPlugHashes: {1},
          ),
        ],
      );
      expect(
        () => validateRollTarget(t, isExotic: true),
        throwsA(
          isA<RollTargetValidationException>().having(
            (e) => e.code,
            'code',
            'ROLL_TARGET_EXOTIC_NOT_ALLOWED',
          ),
        ),
      );
    });
  });

  group('scoreInstanceAgainstTarget', () {
    final target = WeaponRollTarget(
      id: '1',
      userId: 'u',
      weaponKey: '100',
      name: 'PvE',
      columns: const [
        RollTargetColumn(
          columnKey: 'barrel',
          preferredPlugHashes: {10, 11},
          avoidPlugHashes: {19},
        ),
        RollTargetColumn(
          columnKey: 'trait1',
          preferredPlugHashes: {20},
          avoidPlugHashes: {29, 28},
        ),
        RollTargetColumn(
          columnKey: 'trait2',
          preferredPlugHashes: {30, 31},
        ),
        RollTargetColumn(
          columnKey: 'origin',
          // unscored preferred + avoid
        ),
      ],
    );

    test('perfect preferred and clean avoid', () {
      final m = scoreInstanceAgainstTarget(target, {
        'barrel': 10,
        'trait1': 20,
        'trait2': 31,
        'origin': 99,
      });
      expect(m.preferredMatched, 3);
      expect(m.preferredScored, 3);
      expect(m.preferredRatio, 1.0);
      expect(m.isPerfectPreferred, isTrue);
      expect(m.avoidHits, 0);
      expect(m.avoidScored, 2);
      expect(m.isCleanAvoid, isTrue);
      expect(m.preferredByColumn['origin'], PreferredColumnState.unscored);
    });

    test('partial preferred and avoid hits', () {
      final m = scoreInstanceAgainstTarget(target, {
        'barrel': 19, // avoid hit, preferred miss
        'trait1': 20, // preferred match
        'trait2': 99, // preferred miss
      });
      expect(m.preferredMatched, 1);
      expect(m.preferredScored, 3);
      expect(m.avoidHits, 1);
      expect(m.avoidByColumn['barrel'], AvoidColumnState.hit);
      expect(m.preferredByColumn['barrel'], PreferredColumnState.miss);
      expect(m.preferredByColumn['trait1'], PreferredColumnState.matched);
    });

    test('missing plugs count as preferred miss and avoid clear', () {
      final m = scoreInstanceAgainstTarget(target, {});
      expect(m.preferredMatched, 0);
      expect(m.preferredScored, 3);
      expect(m.avoidHits, 0);
      expect(m.avoidScored, 2);
    });

    test('family match counts preferred', () {
      Set<int> familyOf(int h) {
        if (h == 20 || h == 200) return {20, 200};
        return {h};
      }

      final m = scoreInstanceAgainstTarget(
        target,
        {'barrel': 10, 'trait1': 200, 'trait2': 30},
        familyOf: familyOf,
      );
      expect(m.preferredMatched, 3);
      expect(m.preferredByColumn['trait1'], PreferredColumnState.matched);
    });
  });

  group('rankOwnedAgainstTarget', () {
    final target = WeaponRollTarget(
      id: '1',
      userId: 'u',
      weaponKey: '100',
      name: 'PvE',
      columns: const [
        RollTargetColumn(
          columnKey: 't1',
          preferredPlugHashes: {1},
          avoidPlugHashes: {9},
        ),
        RollTargetColumn(
          columnKey: 't2',
          preferredPlugHashes: {2},
          avoidPlugHashes: {8},
        ),
      ],
    );

    test('preferred ratio primary; avoid hits break ties', () {
      final instances = [
        const RollTargetInstanceInput(
          instanceId: 'a',
          plugsByColumn: {'t1': 1, 't2': 8}, // 1/2 preferred, 1 avoid
          power: 1800,
        ),
        const RollTargetInstanceInput(
          instanceId: 'b',
          plugsByColumn: {'t1': 1, 't2': 2}, // 2/2 preferred, 0 avoid
          power: 1700,
        ),
        const RollTargetInstanceInput(
          instanceId: 'c',
          plugsByColumn: {'t1': 1, 't2': 99}, // 1/2 preferred, 0 avoid
          power: 1900,
        ),
      ];

      final ranked = rankOwnedAgainstTarget(target, instances);
      expect(ranked.map((r) => r.instance.instanceId).toList(), ['b', 'c', 'a']);
      // b: 1.0 preferred; c: 0.5 clean; a: 0.5 with avoid hit
    });

    test('avoid-only ranks least bad first when preferred empty', () {
      final avoidOnly = WeaponRollTarget(
        id: '2',
        userId: 'u',
        weaponKey: '100',
        name: 'Trash filter',
        columns: const [
          RollTargetColumn(
            columnKey: 't1',
            avoidPlugHashes: {9},
          ),
          RollTargetColumn(
            columnKey: 't2',
            avoidPlugHashes: {8},
          ),
        ],
      );
      final instances = [
        const RollTargetInstanceInput(
          instanceId: 'dirty',
          plugsByColumn: {'t1': 9, 't2': 8},
        ),
        const RollTargetInstanceInput(
          instanceId: 'clean',
          plugsByColumn: {'t1': 1, 't2': 2},
        ),
        const RollTargetInstanceInput(
          instanceId: 'half',
          plugsByColumn: {'t1': 9, 't2': 2},
        ),
      ];
      final ranked = rankOwnedAgainstTarget(avoidOnly, instances);
      expect(
        ranked.map((r) => r.instance.instanceId).toList(),
        ['clean', 'half', 'dirty'],
      );
    });

    test('empty owned → empty list', () {
      expect(rankOwnedAgainstTarget(target, const []), isEmpty);
    });
  });
}
