import type { ArmorStatName } from "@/data/rules/statBenefits";

import { compareCombinations, type RankableCombination } from "./score";

/**
 * True when `candidate` ranks lexicographically above `current` under the same
 * ordering used by the optimizer (prioritized stats → total → optional reuse
 * tie-break). Used to gate soft improvement suggestions and refresh applies.
 */
export function detectImprovement(
  current: RankableCombination,
  candidate: RankableCombination,
  priorities: ArmorStatName[] | undefined,
  preferReuse: boolean,
): boolean {
  return compareCombinations(candidate, current, priorities, preferReuse) < 0;
}
