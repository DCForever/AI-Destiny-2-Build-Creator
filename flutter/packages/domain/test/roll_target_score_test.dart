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

  group('scoreInstanceAgainstTarget — roll quality on scored sockets', () {
    // Ideal: 10,11,20,30,31,40  Avoid: 19,29,28,49
    final target = WeaponRollTarget(
      id: '1',
      userId: 'u',
      weaponKey: '100',
      name: 'PvE',
      columns: const [
        RollTargetColumn(
          columnKey: 'socket_1',
          label: 'Trait 1',
          preferredPlugHashes: {10, 11, 20},
          avoidPlugHashes: {19, 29},
        ),
        RollTargetColumn(
          columnKey: 'socket_2',
          label: 'Trait 2',
          preferredPlugHashes: {30, 31, 40},
          avoidPlugHashes: {28, 49},
        ),
      ],
    );

    test('Duty Bound style: 525 → 3/6 good + Av 3; columns still perfect', () {
      // 6 plugs on the two trait columns: 3 ideal, 3 avoid.
      final m = scoreInstanceAgainstTarget(target, {
        'socket_1': {10, 19, 11}, // 2 good, 1 bad
        'socket_2': {30, 28, 49}, // 1 good, 2 bad
      });
      expect(m.preferredMatched, 3);
      expect(m.preferredScored, 6);
      expect(m.avoidHits, 3);
      expect(m.avoidScored, 1); // segment enabled
      expect(m.preferredRatio, closeTo(0.5, 0.001));
      // Both preferred sockets hit → perfect green tint even though N!=M.
      expect(m.isPerfectPreferred, isTrue);
      expect(m.isCleanAvoid, isFalse);
      expect(m.preferredByColumn['socket_1'], PreferredColumnState.matched);
      expect(m.preferredByColumn['socket_2'], PreferredColumnState.matched);
    });

    test('Duty Bound style: 487 → 3/4 good + Av 1; columns perfect', () {
      // 4 plugs: 3 ideal, 1 avoid.
      final m = scoreInstanceAgainstTarget(target, {
        'socket_1': {10, 20}, // 2 good
        'socket_2': {30, 49}, // 1 good, 1 bad
      });
      expect(m.preferredMatched, 3);
      expect(m.preferredScored, 4);
      expect(m.avoidHits, 1);
      expect(m.isPerfectPreferred, isTrue);
    });

    test('column miss is not perfect even with some good plugs', () {
      final m = scoreInstanceAgainstTarget(target, {
        'socket_1': {10, 11}, // preferred hit
        'socket_2': {49}, // only avoid — preferred miss
      });
      expect(m.preferredMatched, 2);
      expect(m.preferredScored, 3);
      expect(m.isPerfectPreferred, isFalse);
      expect(m.preferredByColumn['socket_2'], PreferredColumnState.miss);
    });

    test('neutrals count in M but not N or Av', () {
      final m = scoreInstanceAgainstTarget(target, {
        'socket_1': {10, 999}, // 1 good, 1 neutral
        'socket_2': {30}, // 1 good
      });
      expect(m.preferredMatched, 2);
      expect(m.preferredScored, 3);
      expect(m.avoidHits, 0);
    });

    test('key mismatch still classifies by hash presence on copy', () {
      // Target uses socket_*; instance map uses Label@i — resolve + classify.
      final m = scoreInstanceAgainstTarget(target, {
        'Trait 1@1': {10, 19},
        'Trait 2@2': {30, 40},
      });
      expect(m.preferredMatched, 3); // 10, 30, 40
      expect(m.preferredScored, 4);
      expect(m.avoidHits, 1); // 19
    });

    test('single int plugs still accepted', () {
      final m = scoreInstanceAgainstTarget(target, {
        'socket_1': 10,
        'socket_2': 30,
      });
      expect(m.preferredMatched, 2);
      expect(m.preferredScored, 2);
      expect(m.avoidHits, 0);
    });

    test('family match counts as good', () {
      Set<int> familyOf(int h) {
        if (h == 10 || h == 1000) return {10, 1000};
        return {h};
      }

      final m = scoreInstanceAgainstTarget(
        target,
        {
          'socket_1': {1000}, // enhanced of preferred 10
          'socket_2': {30},
        },
        familyOf: familyOf,
      );
      expect(m.preferredMatched, 2);
      expect(m.preferredScored, 2);
    });

    test('Duty Bound 487: alternate hashes same display name → 3/4 Av 1', () {
      // Real D2 issue: Stopping Power / All-Star / Onslaught each have multiple
      // plug item hashes. Target stores the hash the user tapped in the pool;
      // the owned copy may roll a different hash with the same name.
      const stopA = 1517798362;
      const stopB = 1011551830; // on 487
      const allStarA = 1226351311;
      const allStarB = 3251326479; // on 487
      const onslaughtA = 95528736;
      const onslaughtB = 956288240; // on 487
      const loneWolf = 2073244114;

      final names = {
        stopA: 'Stopping Power',
        stopB: 'Stopping Power',
        allStarA: 'All-Star',
        allStarB: 'All-Star',
        onslaughtA: 'Onslaught',
        onslaughtB: 'Onslaught',
        loneWolf: 'Lone Wolf',
      };
      final familyOf = buildPlugFamilyLookup(names);

      final t = WeaponRollTarget(
        id: '1',
        userId: 'u',
        weaponKey: '260532765',
        name: 'PvE',
        columns: const [
          RollTargetColumn(
            columnKey: 'socket_3',
            preferredPlugHashes: {stopA},
            avoidPlugHashes: {loneWolf},
          ),
          RollTargetColumn(
            columnKey: 'socket_4',
            preferredPlugHashes: {allStarA, onslaughtA},
          ),
        ],
      );

      final m = scoreInstanceAgainstTarget(
        t,
        {
          'socket_3': {stopB, loneWolf},
          'socket_4': {allStarB, onslaughtB},
        },
        familyOf: familyOf,
      );
      expect(m.preferredMatched, 3);
      expect(m.preferredScored, 4);
      expect(m.avoidHits, 1);
    });
  });

  group('plug family by display name', () {
    test('normalize strips enhanced and punctuation', () {
      expect(normalizePlugFamilyName('All-Star'), 'all star');
      expect(normalizePlugFamilyName('Enhanced Rampage'), 'rampage');
      expect(normalizePlugFamilyName('Rampage (Enhanced)'), 'rampage');
    });

    test('expandHashesWithFamily unions siblings', () {
      final familyOf = buildPlugFamilyLookup({
        1: 'Stopping Power',
        2: 'Stopping Power',
        3: 'Lone Wolf',
      });
      expect(expandHashesWithFamily({1}, familyOf), {1, 2});
      expect(familyOf(2), {1, 2});
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

    test('higher good/total ranks first; avoid hits break ties', () {
      final instances = [
        const RollTargetInstanceInput(
          instanceId: 'a',
          plugsByColumn: {
            't1': {1, 9}, // 1 good, 1 bad of 2
            't2': {8}, // 1 bad
          },
          power: 1800,
        ),
        const RollTargetInstanceInput(
          instanceId: 'b',
          plugsByColumn: {
            't1': {1},
            't2': {2},
          }, // 2/2 good
          power: 1700,
        ),
        const RollTargetInstanceInput(
          instanceId: 'c',
          plugsByColumn: {
            't1': {1},
            't2': {99},
          }, // 1/2 good, 0 bad
          power: 1900,
        ),
      ];

      final ranked = rankOwnedAgainstTarget(target, instances);
      // b: 1.0 clean; c: 0.5 clean; a: 1/3 with avoids
      expect(
        ranked.map((r) => r.instance.instanceId).toList(),
        ['b', 'c', 'a'],
      );
      expect(ranked[0].match.isPerfectPreferred, isTrue);
      expect(ranked[1].match.isPerfectPreferred, isFalse);
    });

    test('avoid-only ranks least bad first when preferred empty', () {
      final avoidOnly = WeaponRollTarget(
        id: '1',
        userId: 'u',
        weaponKey: '100',
        name: 'PvE',
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
          instanceId: 'bad',
          plugsByColumn: {'t1': 9, 't2': 8},
          power: 1800,
        ),
        const RollTargetInstanceInput(
          instanceId: 'clean',
          plugsByColumn: {'t1': 1, 't2': 2},
          power: 1700,
        ),
        const RollTargetInstanceInput(
          instanceId: 'one',
          plugsByColumn: {'t1': 9, 't2': 2},
          power: 1900,
        ),
      ];
      final ranked = rankOwnedAgainstTarget(avoidOnly, instances);
      expect(
        ranked.map((r) => r.instance.instanceId).toList(),
        ['clean', 'one', 'bad'],
      );
      expect(ranked.first.match.isPerfectPreferred, isFalse);
    });

    test('empty owned → empty list', () {
      expect(rankOwnedAgainstTarget(target, const []), isEmpty);
    });
  });
}
