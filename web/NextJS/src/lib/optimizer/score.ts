import { ARMOR_STAT_NAMES, type ArmorStatName } from "@/data/rules/statBenefits";

import type { CandidatePiece } from "./types";

type StatTotals = Partial<Record<ArmorStatName, number>>;

/** A kit reduced to the fields needed for ranking. */
export type RankableCombination = {
  estimatedStats: StatTotals;
  reusePieceCount: number;
};

export function estimateKitStats(pieces: CandidatePiece[]): StatTotals {
  const totals: StatTotals = {};
  for (const piece of pieces) {
    for (const name of ARMOR_STAT_NAMES) {
      const value = piece.statValues[name];
      if (typeof value === "number") totals[name] = (totals[name] ?? 0) + value;
    }
  }
  return totals;
}

/** Sum of the prioritized stats (all six when no priorities are given). */
export function sumPrioritizedStats(
  stats: StatTotals,
  priorities: ArmorStatName[] | undefined,
): number {
  const order = priorities && priorities.length > 0 ? priorities : ARMOR_STAT_NAMES;
  return order.reduce((sum, name) => sum + (stats[name] ?? 0), 0);
}

/** Total across all six Armor 3.0 stats — the ranking scalar exposed as `score`. */
export function sumAllStats(stats: StatTotals): number {
  return ARMOR_STAT_NAMES.reduce((sum, name) => sum + (stats[name] ?? 0), 0);
}

/** Negative when `a` should rank before `b` (higher stats first). */
export function compareCombinations(
  a: RankableCombination,
  b: RankableCombination,
  priorities: ArmorStatName[] | undefined,
  preferReuse: boolean,
): number {
  for (const name of priorities ?? []) {
    const diff = (b.estimatedStats[name] ?? 0) - (a.estimatedStats[name] ?? 0);
    if (diff !== 0) return diff;
  }

  const totalDiff = sumAllStats(b.estimatedStats) - sumAllStats(a.estimatedStats);
  if (totalDiff !== 0) return totalDiff;

  if (preferReuse) return b.reusePieceCount - a.reusePieceCount;
  return 0;
}

export function meetsSoftThresholds(
  stats: StatTotals,
  thresholds: StatTotals | undefined,
): boolean {
  if (!thresholds) return true;
  return ARMOR_STAT_NAMES.every((name) => {
    const target = thresholds[name];
    if (typeof target !== "number") return true;
    return (stats[name] ?? 0) >= target;
  });
}

export function isEstimateIncomplete(pieces: CandidatePiece[]): boolean {
  return pieces.some((piece) =>
    ARMOR_STAT_NAMES.some((name) => typeof piece.statValues[name] !== "number"),
  );
}
