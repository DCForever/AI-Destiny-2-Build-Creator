/// Pure scoring helpers for armor optimizer (TS `score.ts`).
library;

import '../models/optimizer.dart';
import '../models/soft_stats.dart';

Map<ArmorStatName, int> estimateKitStats(List<CandidatePiece> pieces) {
  final totals = <ArmorStatName, int>{};
  for (final piece in pieces) {
    for (final name in ArmorStatName.all) {
      final value = piece.statValues[name];
      if (value != null) {
        totals[name] = (totals[name] ?? 0) + value;
      }
    }
  }
  return totals;
}

/// Sum of the prioritized stats (all six when no priorities are given).
int sumPrioritizedStats(
  Map<ArmorStatName, int> stats,
  List<ArmorStatName>? priorities,
) {
  final order =
      (priorities != null && priorities.isNotEmpty) ? priorities : ArmorStatName.all;
  var sum = 0;
  for (final name in order) {
    sum += stats[name] ?? 0;
  }
  return sum;
}

/// Total across all six Armor 3.0 stats — the ranking scalar exposed as `score`.
int sumAllStats(Map<ArmorStatName, int> stats) {
  var sum = 0;
  for (final name in ArmorStatName.all) {
    sum += stats[name] ?? 0;
  }
  return sum;
}

/// Negative when [a] should rank before [b] (higher stats first).
int compareCombinations(
  RankableCombination a,
  RankableCombination b,
  List<ArmorStatName>? priorities,
  bool preferReuse,
) {
  for (final name in priorities ?? const <ArmorStatName>[]) {
    final diff = (b.estimatedStats[name] ?? 0) - (a.estimatedStats[name] ?? 0);
    if (diff != 0) return diff;
  }

  final totalDiff = sumAllStats(b.estimatedStats) - sumAllStats(a.estimatedStats);
  if (totalDiff != 0) return totalDiff;

  if (preferReuse) return b.reusePieceCount - a.reusePieceCount;
  return 0;
}

bool meetsSoftThresholds(
  Map<ArmorStatName, int> stats,
  Map<ArmorStatName, int>? thresholds,
) {
  if (thresholds == null) return true;
  for (final name in ArmorStatName.all) {
    final target = thresholds[name];
    if (target == null) continue;
    if ((stats[name] ?? 0) < target) return false;
  }
  return true;
}

bool isEstimateIncomplete(List<CandidatePiece> pieces) {
  for (final piece in pieces) {
    for (final name in ArmorStatName.all) {
      if (!piece.statValues.containsKey(name)) return true;
    }
  }
  return false;
}
