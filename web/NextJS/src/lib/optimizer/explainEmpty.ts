import type { ArmorOptimizeEmptyReason, SetBonusCoverageGoal } from "./types";

export type EmptyReasonInput = {
  hasInventory: boolean;
  classArmorCount: number;
  lockedExoticItemHash?: number | null;
  lockedExoticAvailable: boolean;
  setBonusGoals?: SetBonusCoverageGoal[];
  /** Whether the goals can still be met by the available candidate pool. */
  setBonusReachable: boolean;
  requireThresholds?: boolean;
  /** Whether required soft thresholds removed every otherwise-valid kit. */
  thresholdsFilteredAll: boolean;
};

/** First unmet hard constraint wins; ordering mirrors the contract's codes. */
export function explainEmpty(input: EmptyReasonInput): ArmorOptimizeEmptyReason {
  if (!input.hasInventory) {
    return { code: "NO_INVENTORY", message: "No synced inventory. Sync your inventory and retry." };
  }

  if (input.classArmorCount === 0) {
    return {
      code: "NO_CLASS_ARMOR",
      message: "No owned armor for this class.",
    };
  }

  if (input.lockedExoticItemHash != null && !input.lockedExoticAvailable) {
    return {
      code: "EXOTIC_UNAVAILABLE",
      message: "The locked exotic is not owned in a usable slot.",
      details: { lockedExoticItemHash: input.lockedExoticItemHash },
    };
  }

  if (input.setBonusGoals && input.setBonusGoals.length > 0 && !input.setBonusReachable) {
    return {
      code: "SET_BONUS_UNSATISFIABLE",
      message: "Owned armor cannot satisfy the requested set-bonus coverage.",
      details: { setBonusGoals: input.setBonusGoals },
    };
  }

  if (input.requireThresholds && input.thresholdsFilteredAll) {
    return {
      code: "THRESHOLDS_UNMET",
      message: "No kit meets the required stat thresholds.",
    };
  }

  return { code: "NO_VALID_KITS", message: "No complete kit satisfies the given constraints." };
}
