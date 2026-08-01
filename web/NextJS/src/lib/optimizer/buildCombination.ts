import type { ArmorStatName } from "@/data/rules/statBenefits";

import { toCombinationPiece, toSetBonusSummary } from "./combinationDto";
import { estimateCombinationStats } from "./estimate";
import { isEstimateIncomplete, meetsSoftThresholds, sumAllStats } from "./score";
import type { ArmorCombination, CandidatePiece } from "./types";

export type BuildCombinationOptions = {
  thresholds?: Partial<Record<ArmorStatName, number>>;
  priorities?: ArmorStatName[];
  /** US4 toggle: assign auto stat mods (true) or base-armor-only estimate (false). */
  includeModEstimates: boolean;
};

/** Assemble a scored `ArmorCombination` from a validated complete kit. */
export function buildCombination(
  kit: CandidatePiece[],
  options: BuildCombinationOptions,
): ArmorCombination {
  const { estimatedStats, assumedMods } = estimateCombinationStats({
    kit,
    thresholds: options.thresholds,
    priorities: options.priorities,
    includeModEstimates: options.includeModEstimates,
  });
  return {
    pieces: kit.map(toCombinationPiece),
    estimatedStats,
    incompleteEstimate: isEstimateIncomplete(kit),
    setBonusSummary: toSetBonusSummary(kit),
    assumedMods,
    reusePieceCount: kit.filter((piece) => piece.usedInSets.length > 0).length,
    score: sumAllStats(estimatedStats),
    meetsSoftThresholds: meetsSoftThresholds(estimatedStats, options.thresholds),
  };
}
