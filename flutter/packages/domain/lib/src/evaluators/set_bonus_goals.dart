/// Pure G-SET-013 set-bonus goal legality + hard satisfaction.
///
/// Legal combos only: **none · 1×2pc · 2×2pc (different families) · 1×4pc**.
/// A 4pc goal includes that family's 2pc (DBR-SETB-003 supersession 2026-08-10).
/// Soft ≥2pc detection (DBR-SETB-006) is separate and never hard-blocks.
library;

import '../models/optimizer.dart';

/// One hard set-bonus goal (family key + target tier 2 or 4).
typedef SetBonusGoal = SetBonusCoverageGoal;

/// Result of validating a goal list under G-SET-013.
class SetBonusGoalComboResult {
  const SetBonusGoalComboResult._({
    required this.ok,
    this.code,
    this.message,
  });

  const SetBonusGoalComboResult.ok()
      : this._(ok: true);

  const SetBonusGoalComboResult.fail({
    required String code,
    required String message,
  }) : this._(ok: false, code: code, message: message);

  final bool ok;
  final String? code;
  final String? message;
}

/// True when [goals] is a legal G-SET-013 combination.
///
/// - empty / none → ok
/// - one goal with minPieces 2 or 4 → ok
/// - two goals, both 2pc, different non-empty families → ok
/// - otherwise illegal (same family twice, 2pc+4pc, two 4pc, >2 goals, bad tier)
bool isLegalSetBonusGoalCombo(List<SetBonusCoverageGoal> goals) {
  return validateSetBonusGoalCombo(goals).ok;
}

/// Validate [goals] and return a structured result (for hosts / save gates).
SetBonusGoalComboResult validateSetBonusGoalCombo(
  List<SetBonusCoverageGoal> goals,
) {
  if (goals.isEmpty) return const SetBonusGoalComboResult.ok();

  if (goals.length > 2) {
    return const SetBonusGoalComboResult.fail(
      code: 'SET_BONUS_GOAL_TOO_MANY',
      message:
          'At most two set-bonus goals (2×2pc different families) are allowed',
    );
  }

  for (final g in goals) {
    final key = g.setBonusKey.trim();
    if (key.isEmpty) {
      return const SetBonusGoalComboResult.fail(
        code: 'SET_BONUS_GOAL_EMPTY_KEY',
        message: 'Set-bonus family key must not be empty',
      );
    }
    if (g.minPieces != 2 && g.minPieces != 4) {
      return const SetBonusGoalComboResult.fail(
        code: 'SET_BONUS_GOAL_BAD_TIER',
        message: 'Set-bonus target tier must be 2 or 4',
      );
    }
  }

  if (goals.length == 1) {
    return const SetBonusGoalComboResult.ok();
  }

  // Exactly two goals: both must be 2pc on different families.
  final a = goals[0];
  final b = goals[1];
  if (a.minPieces != 2 || b.minPieces != 2) {
    return const SetBonusGoalComboResult.fail(
      code: 'SET_BONUS_GOAL_ILLEGAL_PAIR',
      message:
          'Two goals must both be 2-piece on different families '
          '(or use a single 4-piece goal)',
    );
  }
  final keyA = a.setBonusKey.trim().toLowerCase();
  final keyB = b.setBonusKey.trim().toLowerCase();
  if (keyA == keyB) {
    return const SetBonusGoalComboResult.fail(
      code: 'SET_BONUS_GOAL_SAME_FAMILY',
      message: 'Two 2-piece goals must use different set-bonus families',
    );
  }
  return const SetBonusGoalComboResult.ok();
}

/// Count non-exotic contributing pieces per set-bonus family key.
///
/// Exotics never count toward tier (DBR-SETB-005).
Map<String, int> contributingSetBonusCounts(
  Iterable<SetBonusPieceInput> pieces,
) {
  final counts = <String, int>{};
  for (final p in pieces) {
    if (p.isExotic) continue;
    final key = p.setBonusKey?.trim();
    if (key == null || key.isEmpty) continue;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts;
}

/// Minimal piece input for hard goal satisfaction (no optimizer coupling).
class SetBonusPieceInput {
  const SetBonusPieceInput({
    this.setBonusKey,
    this.isExotic = false,
  });

  final String? setBonusKey;
  final bool isExotic;
}

/// Whether every hard goal's minPieces is met by non-exotic contributors.
///
/// Empty / null goals always pass (DBR-SETB-006). Illegal combos fail.
bool satisfiesHardSetBonusGoals({
  required List<SetBonusCoverageGoal> goals,
  required Iterable<SetBonusPieceInput> pieces,
}) {
  if (goals.isEmpty) return true;
  if (!isLegalSetBonusGoalCombo(goals)) return false;
  final counts = contributingSetBonusCounts(pieces);
  for (final g in goals) {
    final key = g.setBonusKey.trim();
    if ((counts[key] ?? 0) < g.minPieces) return false;
  }
  return true;
}

/// Soft coverage bands for display (DBR-SETB-006): families with ≥2 / ≥4 pieces.
///
/// Independent of hard goals; muted UI uses these for detected 2pc/4pc.
class SoftSetBonusCoverage {
  const SoftSetBonusCoverage({
    this.twoPieceFamilies = const [],
    this.fourPieceFamilies = const [],
  });

  final List<String> twoPieceFamilies;
  final List<String> fourPieceFamilies;

  bool get hasAny =>
      twoPieceFamilies.isNotEmpty || fourPieceFamilies.isNotEmpty;
}

/// Detect soft ≥2pc / ≥4pc families from non-exotic contributing pieces.
SoftSetBonusCoverage detectSoftSetBonusCoverage(
  Iterable<SetBonusPieceInput> pieces,
) {
  final counts = contributingSetBonusCounts(pieces);
  final two = <String>[];
  final four = <String>[];
  for (final e in counts.entries) {
    if (e.value >= 4) {
      four.add(e.key);
      two.add(e.key);
    } else if (e.value >= 2) {
      two.add(e.key);
    }
  }
  two.sort();
  four.sort();
  return SoftSetBonusCoverage(
    twoPieceFamilies: List.unmodifiable(two),
    fourPieceFamilies: List.unmodifiable(four),
  );
}

/// True when every non-exotic filled piece is a member of the union of goal
/// families (DBR-SETB-004 multi-goal). Exotics may be outside the union.
bool nonExoticPiecesMatchGoalFamilies({
  required List<SetBonusCoverageGoal> goals,
  required Iterable<SetBonusPieceInput> pieces,
}) {
  if (goals.isEmpty) return true;
  final families = {
    for (final g in goals) g.setBonusKey.trim().toLowerCase(),
  };
  for (final p in pieces) {
    if (p.isExotic) continue;
    final key = p.setBonusKey?.trim();
    if (key == null || key.isEmpty) return false;
    if (!families.contains(key.toLowerCase())) return false;
  }
  return true;
}

/// Convert optimizer [CandidatePiece]s to [SetBonusPieceInput] for shared checks.
List<SetBonusPieceInput> setBonusInputsFromCandidates(
  Iterable<CandidatePiece> pieces,
) {
  return [
    for (final p in pieces)
      SetBonusPieceInput(
        setBonusKey: p.setBonusKey,
        isExotic: p.isExotic,
      ),
  ];
}
