import { ARMOR_STAT_NAMES, type ArmorStatName } from "@/data/rules/statBenefits";

import { assignAutoStatMods } from "./autoStatMods";
import { estimateKitStats } from "./score";
import type { AssumedMod, CandidatePiece } from "./types";

type StatTotals = Partial<Record<ArmorStatName, number>>;

/** Add assumed-mod stat deltas onto a base stat total. */
export function applyModDeltas(base: StatTotals, mods: AssumedMod[]): StatTotals {
  const out: StatTotals = { ...base };
  for (const mod of mods) {
    const deltas = mod.statDeltas;
    if (!deltas) continue;
    for (const stat of ARMOR_STAT_NAMES) {
      const delta = deltas[stat];
      if (typeof delta === "number") out[stat] = (out[stat] ?? 0) + delta;
    }
  }
  return out;
}

export type CombinationEstimate = {
  baseStats: StatTotals;
  estimatedStats: StatTotals;
  assumedMods: AssumedMod[];
};

/**
 * Estimate a kit's six-stat totals. When `includeModEstimates` is true, greedy
 * auto stat mods are assigned toward soft thresholds and their deltas fold into
 * `estimatedStats`; otherwise the estimate is base-armor only with no mods.
 */
export function estimateCombinationStats(params: {
  kit: CandidatePiece[];
  thresholds?: StatTotals;
  priorities?: ArmorStatName[];
  includeModEstimates: boolean;
}): CombinationEstimate {
  const baseStats = estimateKitStats(params.kit);
  if (!params.includeModEstimates) {
    return { baseStats, estimatedStats: baseStats, assumedMods: [] };
  }
  const assumedMods = assignAutoStatMods({
    pieces: params.kit,
    baseStats,
    thresholds: params.thresholds,
    priorities: params.priorities,
  });
  return { baseStats, estimatedStats: applyModDeltas(baseStats, assumedMods), assumedMods };
}
