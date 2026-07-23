import type { ArmorStatName } from "@/data/rules/statBenefits";
import {
  seedConstraintsFromBuild,
  type BuildConstraintSeed,
} from "@/lib/optimizer/seedConstraintsFromBuild";
import {
  armorSetOptimizerConstraintsSchema,
  type ArmorSetOptimizerConstraints,
  type SetBonusCoverageGoal,
} from "@/lib/optimizer/types";

export type ComposeOptimizerConstraintsInput = {
  seed: BuildConstraintSeed;
  /** Replaces setBonusGoals (deduped by setBonusKey, last wins). */
  setBonusGoals?: SetBonusCoverageGoal[];
  statThresholds?: Partial<Record<ArmorStatName, number>>;
  statPriorities?: ArmorStatName[];
  includeModEstimates?: boolean;
  preferReuse?: boolean;
  lockedExoticItemHash?: number | null;
  requireExotic?: boolean;
  requireThresholds?: boolean;
};

function dedupeGoals(goals: SetBonusCoverageGoal[]): SetBonusCoverageGoal[] {
  const map = new Map<string, SetBonusCoverageGoal>();
  for (const g of goals) {
    if (g.minPieces !== 2 && g.minPieces !== 4) continue;
    map.set(g.setBonusKey, { setBonusKey: g.setBonusKey, minPieces: g.minPieces });
  }
  return [...map.values()];
}

/**
 * Compose ArmorSetOptimizerConstraints from build seed + Finish/user edits.
 */
export function composeOptimizerConstraints(
  input: ComposeOptimizerConstraintsInput,
): ArmorSetOptimizerConstraints {
  const seeded = seedConstraintsFromBuild(input.seed);
  const merged: ArmorSetOptimizerConstraints = {
    ...seeded,
    setBonusGoals: dedupeGoals(input.setBonusGoals ?? seeded.setBonusGoals ?? []),
    includeModEstimates: input.includeModEstimates ?? seeded.includeModEstimates ?? true,
    preferReuse: input.preferReuse ?? seeded.preferReuse ?? false,
  };

  if (input.lockedExoticItemHash !== undefined) {
    merged.lockedExoticItemHash = input.lockedExoticItemHash;
  }
  if (input.statThresholds) {
    merged.statThresholds = { ...merged.statThresholds, ...input.statThresholds };
  }
  if (input.statPriorities) {
    merged.statPriorities = input.statPriorities;
  }
  if (input.requireExotic !== undefined) merged.requireExotic = input.requireExotic;
  if (input.requireThresholds !== undefined) merged.requireThresholds = input.requireThresholds;

  return armorSetOptimizerConstraintsSchema.parse(merged);
}
