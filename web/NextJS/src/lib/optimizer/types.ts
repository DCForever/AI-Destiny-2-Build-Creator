import { z } from "zod";

import type { ArmorStatName } from "@/data/rules/statBenefits";

export const armorStatNameSchema = z.enum([
  "Health",
  "Melee",
  "Grenade",
  "Super",
  "Class",
  "Weapons",
]);

export const setBonusCoverageGoalSchema = z.object({
  setBonusKey: z.string().min(1),
  minPieces: z.union([z.literal(2), z.literal(4)]),
});

export type SetBonusCoverageGoal = z.infer<typeof setBonusCoverageGoalSchema>;

export const softThresholdsSchema = z
  .object({
    Health: z.number().int().min(1).max(200),
    Melee: z.number().int().min(1).max(200),
    Grenade: z.number().int().min(1).max(200),
    Super: z.number().int().min(1).max(200),
    Class: z.number().int().min(1).max(200),
    Weapons: z.number().int().min(1).max(200),
  })
  .partial();

/** Persisted on Armor Sets (`sets.optimizer_constraints`). */
export const armorSetOptimizerConstraintsSchema = z.object({
  lockedExoticItemHash: z.number().int().positive().nullable().optional(),
  requireExotic: z.boolean().optional(),
  setBonusGoals: z.array(setBonusCoverageGoalSchema).optional(),
  statPriorities: z.array(armorStatNameSchema).optional(),
  statThresholds: softThresholdsSchema.optional(),
  requireThresholds: z.boolean().optional(),
  includeModEstimates: z.boolean().optional(),
  preferReuse: z.boolean().optional(),
});

export type ArmorSetOptimizerConstraints = z.infer<typeof armorSetOptimizerConstraintsSchema>;

export function emptyOptimizerConstraints(): ArmorSetOptimizerConstraints {
  return {
    setBonusGoals: [],
    preferReuse: false,
    includeModEstimates: true,
  };
}

export function parseOptimizerConstraints(
  raw: string | null | undefined,
): ArmorSetOptimizerConstraints | null {
  if (raw == null || raw === "") return null;
  try {
    const parsed = JSON.parse(raw) as unknown;
    const result = armorSetOptimizerConstraintsSchema.safeParse(parsed);
    return result.success ? result.data : null;
  } catch {
    return null;
  }
}

export function serializeOptimizerConstraints(constraints: ArmorSetOptimizerConstraints): string {
  return JSON.stringify(constraints);
}

/** True when a non-null payload is stored (even partial) — improvement-check eligibility. */
export function hasOptimizerConstraintsPayload(
  constraints: ArmorSetOptimizerConstraints | null | undefined,
): boolean {
  return constraints != null;
}

export function clearOptimizerConstraints(): null {
  return null;
}

export type ArmorOptimizePiece = {
  slot: "helmet" | "arms" | "chest" | "legs" | "class_item";
  itemHash: number;
  instanceId: string;
  itemName?: string;
  isExotic: boolean;
  setBonusKey?: string;
  statValues?: Partial<Record<ArmorStatName, number>>;
  /** Other Armor Sets (excluding the Set under search) with this instance active. */
  usedInOtherSets: ReuseSetRef[];
};

export type AssumedMod = {
  armorSlot: ArmorOptimizePiece["slot"];
  itemHash: number;
  name?: string;
  energyCost: number;
  statDeltas?: Partial<Record<ArmorStatName, number>>;
};

export type ArmorCombination = {
  pieces: ArmorOptimizePiece[];
  estimatedStats: Partial<Record<ArmorStatName, number>>;
  incompleteEstimate: boolean;
  setBonusSummary: Array<{
    setBonusKey: string;
    pieceCount: number;
    active2pc: boolean;
    active4pc: boolean;
  }>;
  assumedMods: AssumedMod[];
  reusePieceCount: number;
  score: number;
  meetsSoftThresholds: boolean;
};

export type ArmorSlot = ArmorOptimizePiece["slot"];

/** Five armor slots a complete kit must fill, in canonical order. */
export const ARMOR_OPTIMIZER_SLOTS: readonly ArmorSlot[] = [
  "helmet",
  "arms",
  "chest",
  "legs",
  "class_item",
];

/** Set membership annotation used for reuse counting (excludes the searched Set). */
export type ReuseSetRef = { id: string; name: string };

/** Internal optimizer representation of one owned armor instance. */
export type CandidatePiece = {
  slot: ArmorSlot;
  itemHash: number;
  instanceId: string;
  itemName?: string;
  isExotic: boolean;
  setBonusKey?: string;
  statValues: Partial<Record<ArmorStatName, number>>;
  /** Per-piece armor mod energy capacity (DBR-MOD-002); consumed by US4 mods. */
  energyCapacity: number;
  /** Other Armor Sets already using this active instance (excludes searched Set). */
  usedInSets: ReuseSetRef[];
};

export type ArmorOptimizeEmptyReasonCode =
  | "NO_INVENTORY"
  | "NO_CLASS_ARMOR"
  | "EXOTIC_UNAVAILABLE"
  | "SET_BONUS_UNSATISFIABLE"
  | "THRESHOLDS_UNMET"
  | "NO_VALID_KITS";

export type ArmorOptimizeEmptyReason = {
  code: ArmorOptimizeEmptyReasonCode;
  message: string;
  details?: Record<string, unknown>;
};

export type ArmorOptimizeSeed = {
  classType: string;
  lockedExoticItemHash?: number;
  statThresholds?: Partial<Record<ArmorStatName, number>>;
  statPriorities?: ArmorStatName[];
  preferReuse?: boolean;
};

export type ArmorOptimizeResponse = {
  combinations: ArmorCombination[];
  truncated: boolean;
  evaluatedCount: number;
  emptyReason?: ArmorOptimizeEmptyReason;
  seed?: ArmorOptimizeSeed;
};
