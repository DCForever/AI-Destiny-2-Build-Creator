import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('isLegalSetBonusGoalCombo / G-SET-013', () {
    test('none / empty is legal', () {
      expect(isLegalSetBonusGoalCombo(const []), isTrue);
      expect(validateSetBonusGoalCombo(const []).ok, isTrue);
    });

    test('1×2pc is legal', () {
      expect(
        isLegalSetBonusGoalCombo(const [
          SetBonusCoverageGoal(setBonusKey: 'TechSec', minPieces: 2),
        ]),
        isTrue,
      );
    });

    test('1×4pc is legal', () {
      expect(
        isLegalSetBonusGoalCombo(const [
          SetBonusCoverageGoal(setBonusKey: 'TechSec', minPieces: 4),
        ]),
        isTrue,
      );
    });

    test('2×2pc different families is legal', () {
      expect(
        isLegalSetBonusGoalCombo(const [
          SetBonusCoverageGoal(setBonusKey: 'TechSec', minPieces: 2),
          SetBonusCoverageGoal(setBonusKey: 'Twofer', minPieces: 2),
        ]),
        isTrue,
      );
    });

    test('2×2pc same family is illegal', () {
      final r = validateSetBonusGoalCombo(const [
        SetBonusCoverageGoal(setBonusKey: 'TechSec', minPieces: 2),
        SetBonusCoverageGoal(setBonusKey: 'techsec', minPieces: 2),
      ]);
      expect(r.ok, isFalse);
      expect(r.code, 'SET_BONUS_GOAL_SAME_FAMILY');
    });

    test('2pc + 4pc is illegal', () {
      final r = validateSetBonusGoalCombo(const [
        SetBonusCoverageGoal(setBonusKey: 'A', minPieces: 2),
        SetBonusCoverageGoal(setBonusKey: 'B', minPieces: 4),
      ]);
      expect(r.ok, isFalse);
      expect(r.code, 'SET_BONUS_GOAL_ILLEGAL_PAIR');
    });

    test('two 4pc is illegal', () {
      expect(
        isLegalSetBonusGoalCombo(const [
          SetBonusCoverageGoal(setBonusKey: 'A', minPieces: 4),
          SetBonusCoverageGoal(setBonusKey: 'B', minPieces: 4),
        ]),
        isFalse,
      );
    });

    test('three goals is illegal', () {
      final r = validateSetBonusGoalCombo(const [
        SetBonusCoverageGoal(setBonusKey: 'A', minPieces: 2),
        SetBonusCoverageGoal(setBonusKey: 'B', minPieces: 2),
        SetBonusCoverageGoal(setBonusKey: 'C', minPieces: 2),
      ]);
      expect(r.ok, isFalse);
      expect(r.code, 'SET_BONUS_GOAL_TOO_MANY');
    });

    test('bad tier is illegal', () {
      final r = validateSetBonusGoalCombo(const [
        SetBonusCoverageGoal(setBonusKey: 'A', minPieces: 3),
      ]);
      expect(r.ok, isFalse);
      expect(r.code, 'SET_BONUS_GOAL_BAD_TIER');
    });

    test('empty family key is illegal', () {
      final r = validateSetBonusGoalCombo(const [
        SetBonusCoverageGoal(setBonusKey: '  ', minPieces: 2),
      ]);
      expect(r.ok, isFalse);
      expect(r.code, 'SET_BONUS_GOAL_EMPTY_KEY');
    });
  });

  group('satisfiesHardSetBonusGoals', () {
    test('empty goals always pass', () {
      expect(
        satisfiesHardSetBonusGoals(
          goals: const [],
          pieces: const [
            SetBonusPieceInput(setBonusKey: 'X'),
          ],
        ),
        isTrue,
      );
    });

    test('2pc met by two non-exotics', () {
      expect(
        satisfiesHardSetBonusGoals(
          goals: const [
            SetBonusCoverageGoal(setBonusKey: 'TechSec', minPieces: 2),
          ],
          pieces: const [
            SetBonusPieceInput(setBonusKey: 'TechSec'),
            SetBonusPieceInput(setBonusKey: 'TechSec'),
            SetBonusPieceInput(setBonusKey: 'Other'),
          ],
        ),
        isTrue,
      );
    });

    test('exotic does not count toward tier', () {
      expect(
        satisfiesHardSetBonusGoals(
          goals: const [
            SetBonusCoverageGoal(setBonusKey: 'TechSec', minPieces: 2),
          ],
          pieces: const [
            SetBonusPieceInput(setBonusKey: 'TechSec', isExotic: true),
            SetBonusPieceInput(setBonusKey: 'TechSec'),
          ],
        ),
        isFalse,
      );
    });

    test('4pc includes family 2pc when count ≥4', () {
      expect(
        satisfiesHardSetBonusGoals(
          goals: const [
            SetBonusCoverageGoal(setBonusKey: 'TechSec', minPieces: 4),
          ],
          pieces: List.generate(
            4,
            (_) => const SetBonusPieceInput(setBonusKey: 'TechSec'),
          ),
        ),
        isTrue,
      );
    });

    test('2×2pc both must be met', () {
      final goals = const [
        SetBonusCoverageGoal(setBonusKey: 'A', minPieces: 2),
        SetBonusCoverageGoal(setBonusKey: 'B', minPieces: 2),
      ];
      expect(
        satisfiesHardSetBonusGoals(
          goals: goals,
          pieces: const [
            SetBonusPieceInput(setBonusKey: 'A'),
            SetBonusPieceInput(setBonusKey: 'A'),
            SetBonusPieceInput(setBonusKey: 'B'),
          ],
        ),
        isFalse,
      );
      expect(
        satisfiesHardSetBonusGoals(
          goals: goals,
          pieces: const [
            SetBonusPieceInput(setBonusKey: 'A'),
            SetBonusPieceInput(setBonusKey: 'A'),
            SetBonusPieceInput(setBonusKey: 'B'),
            SetBonusPieceInput(setBonusKey: 'B'),
          ],
        ),
        isTrue,
      );
    });

    test('illegal combo fails satisfaction', () {
      expect(
        satisfiesHardSetBonusGoals(
          goals: const [
            SetBonusCoverageGoal(setBonusKey: 'A', minPieces: 2),
            SetBonusCoverageGoal(setBonusKey: 'A', minPieces: 2),
          ],
          pieces: const [
            SetBonusPieceInput(setBonusKey: 'A'),
            SetBonusPieceInput(setBonusKey: 'A'),
          ],
        ),
        isFalse,
      );
    });
  });

  group('detectSoftSetBonusCoverage', () {
    test('muted soft 2pc / 4pc independent of hard goals', () {
      final soft = detectSoftSetBonusCoverage(const [
        SetBonusPieceInput(setBonusKey: 'A'),
        SetBonusPieceInput(setBonusKey: 'A'),
        SetBonusPieceInput(setBonusKey: 'B'),
        SetBonusPieceInput(setBonusKey: 'B'),
        SetBonusPieceInput(setBonusKey: 'B'),
        SetBonusPieceInput(setBonusKey: 'B'),
      ]);
      expect(soft.twoPieceFamilies, ['A', 'B']);
      expect(soft.fourPieceFamilies, ['B']);
    });
  });

  group('nonExoticPiecesMatchGoalFamilies', () {
    test('union of families for multi-goal', () {
      expect(
        nonExoticPiecesMatchGoalFamilies(
          goals: const [
            SetBonusCoverageGoal(setBonusKey: 'A', minPieces: 2),
            SetBonusCoverageGoal(setBonusKey: 'B', minPieces: 2),
          ],
          pieces: const [
            SetBonusPieceInput(setBonusKey: 'A'),
            SetBonusPieceInput(setBonusKey: 'B'),
            SetBonusPieceInput(setBonusKey: 'A', isExotic: true),
          ],
        ),
        isTrue,
      );
      expect(
        nonExoticPiecesMatchGoalFamilies(
          goals: const [
            SetBonusCoverageGoal(setBonusKey: 'A', minPieces: 2),
          ],
          pieces: const [
            SetBonusPieceInput(setBonusKey: 'A'),
            SetBonusPieceInput(setBonusKey: 'Other'),
          ],
        ),
        isFalse,
      );
    });
  });
}
