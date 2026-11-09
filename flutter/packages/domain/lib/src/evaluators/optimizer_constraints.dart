/// Pure hard kit constraints for armor optimizer (TS `constraints.ts`).
library;

import '../models/optimizer.dart';

int countExotics(List<CandidatePiece> pieces) {
  var total = 0;
  for (final piece in pieces) {
    if (piece.isExotic) total += 1;
  }
  return total;
}

/// Counts per family for set-bonus tier (non-exotic only — DBR-SETB-005).
///
/// Keys are stored with the first-seen casing; lookup should use
/// [setBonusCountFor] for case-insensitive access.
Map<String, int> setBonusPieceCounts(List<CandidatePiece> pieces) {
  final counts = <String, int>{};
  final canon = <String, String>{}; // lower → first-seen key
  for (final piece in pieces) {
    if (piece.isExotic) continue;
    final raw = piece.setBonusKey?.trim();
    if (raw == null || raw.isEmpty) continue;
    final lower = raw.toLowerCase();
    final key = canon.putIfAbsent(lower, () => raw);
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts;
}

int setBonusCountFor(Map<String, int> counts, String setBonusKey) {
  final want = setBonusKey.trim().toLowerCase();
  if (want.isEmpty) return 0;
  for (final e in counts.entries) {
    if (e.key.toLowerCase() == want) return e.value;
  }
  return 0;
}

bool satisfiesSetBonusGoals(
  List<CandidatePiece> pieces,
  List<SetBonusCoverageGoal>? goals,
) {
  if (goals == null || goals.isEmpty) return true;
  final counts = setBonusPieceCounts(pieces);
  for (final goal in goals) {
    if (setBonusCountFor(counts, goal.setBonusKey) < goal.minPieces) {
      return false;
    }
  }
  return true;
}

bool isKitValid(List<CandidatePiece> pieces, KitConstraints constraints) {
  if (pieces.length != armorOptimizerSlots.length) return false;
  final seen = <Object>{};
  for (final piece in pieces) {
    if (!seen.add(piece.slot)) return false;
  }
  for (final slot in armorOptimizerSlots) {
    if (!seen.contains(slot)) return false;
  }

  final exotics = countExotics(pieces);
  if (exotics > 1) return false;
  if (constraints.requireExotic == true && exotics < 1) return false;

  final locked = constraints.lockedExoticItemHash;
  if (locked != null && !pieces.any((p) => p.itemHash == locked)) {
    return false;
  }

  return satisfiesSetBonusGoals(pieces, constraints.setBonusGoals);
}

List<SetBonusSummaryEntry> buildSetBonusSummary(List<CandidatePiece> pieces) {
  return setBonusPieceCounts(pieces)
      .entries
      .map(
        (e) => SetBonusSummaryEntry(
          setBonusKey: e.key,
          pieceCount: e.value,
          active2pc: e.value >= 2,
          active4pc: e.value >= 4,
        ),
      )
      .toList();
}
