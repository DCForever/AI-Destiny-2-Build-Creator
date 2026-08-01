import { ARMOR_STAT_NAMES, type ArmorStatName } from "@/data/rules/statBenefits";
import type { SoftStatTargets } from "@/lib/builds/softStatTargets";
import {
  emptyOptimizerConstraints,
  type ArmorSetOptimizerConstraints,
} from "@/lib/optimizer/types";

export type BuildConstraintSeed = {
  exoticArmorHash?: number | null;
  softStatTargets?: SoftStatTargets | null;
};

/**
 * Seed Armor Set optimizer constraints from a Build: exotic lock + soft-stat
 * priorities/thresholds. Set-bonus goals stay empty.
 */
export function seedConstraintsFromBuild(build: BuildConstraintSeed): ArmorSetOptimizerConstraints {
  const base = emptyOptimizerConstraints();
  const locked =
    build.exoticArmorHash != null && Number.isFinite(build.exoticArmorHash) && build.exoticArmorHash > 0
      ? build.exoticArmorHash
      : null;

  const targets = build.softStatTargets ?? {};
  const thresholds: Partial<Record<ArmorStatName, number>> = {};
  for (const name of ARMOR_STAT_NAMES) {
    const v = targets[name];
    if (typeof v === "number") thresholds[name] = v;
  }

  const priorities = [...ARMOR_STAT_NAMES].sort((a, b) => {
    const ta = thresholds[a] ?? 0;
    const tb = thresholds[b] ?? 0;
    return tb - ta;
  });

  return {
    ...base,
    lockedExoticItemHash: locked,
    setBonusGoals: [],
    preferReuse: false,
    includeModEstimates: true,
    ...(Object.keys(thresholds).length > 0
      ? {
          statThresholds: thresholds,
          statPriorities: priorities,
        }
      : {}),
  };
}
