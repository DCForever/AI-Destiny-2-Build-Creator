import type { ArmorSetOptimizerConstraints } from "@/lib/optimizer/types";

/** Keys persisted on `ArmorSetOptimizerConstraints` (armorSetOptimizerConstraintsSchema). */
const CONSTRAINT_KEYS = [
  "lockedExoticItemHash",
  "requireExotic",
  "setBonusGoals",
  "statPriorities",
  "statThresholds",
  "requireThresholds",
  "includeModEstimates",
  "preferReuse",
] as const;

/**
 * Extract the persisted-constraints subset from an optimize request/seed
 * payload. Used by debug UI materialize wiring so the constraints stored on
 * a new Armor Set match the search that produced the selected combination.
 */
export function pickOptimizerConstraints(
  source: Record<string, unknown>,
): ArmorSetOptimizerConstraints {
  const result: Record<string, unknown> = {};
  for (const key of CONSTRAINT_KEYS) {
    if (source[key] !== undefined) result[key] = source[key];
  }
  return result as ArmorSetOptimizerConstraints;
}
