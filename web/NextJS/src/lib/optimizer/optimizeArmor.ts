import type { ArmorStatName } from "@/data/rules/statBenefits";
import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import type { AuthenticatedUser } from "@/lib/api/requireUser";
import type { AppDatabase } from "@/lib/db/client";
import { getBuild } from "@/lib/db/repositories/buildRepository";
import type { BuildRecord } from "@/lib/db/repositories/buildRepository";
import type { DestinyClassName } from "@/lib/manifest/types/records";

import { buildCombination } from "./buildCombination";
import { type KitConstraints } from "./constraints";
import { enumerateKits, groupBySlot } from "./enumerate";
import { explainEmpty } from "./explainEmpty";
import { loadArmorCandidates } from "./loadArmorCandidates";
import { prunePiecesBySlot } from "./prune";
import { compareCombinations } from "./score";
import { seedConstraintsFromBuild } from "./seedConstraintsFromBuild";
import {
  type ArmorCombination,
  type ArmorOptimizeResponse,
  type ArmorOptimizeSeed,
  type CandidatePiece,
  type SetBonusCoverageGoal,
} from "./types";

const CLASS_NAMES = new Set<DestinyClassName>(["Titan", "Hunter", "Warlock"]);

export type OptimizeArmorInput = {
  db: AppDatabase;
  userId: number;
  auth?: AuthenticatedUser;
  buildId?: string;
  armorSetId?: string;
  classType?: DestinyClassName;
  lockedExoticItemHash?: number | null;
  requireExotic?: boolean;
  setBonusGoals?: SetBonusCoverageGoal[];
  statPriorities?: ArmorStatName[];
  statThresholds?: Partial<Record<ArmorStatName, number>>;
  requireThresholds?: boolean;
  includeModEstimates?: boolean;
  preferReuse?: boolean;
  maxResults?: number;
  /** Test injection: bypass inventory loading. */
  candidates?: CandidatePiece[];
};

type EffectiveConfig = {
  classType: DestinyClassName;
  lockedExoticItemHash: number | null;
  requireExotic: boolean;
  setBonusGoals: SetBonusCoverageGoal[];
  statPriorities: ArmorStatName[];
  statThresholds?: Partial<Record<ArmorStatName, number>>;
  requireThresholds: boolean;
  includeModEstimates: boolean;
  preferReuse: boolean;
  maxResults: number;
};

function asClassName(value: string | undefined): DestinyClassName | undefined {
  return value != null && CLASS_NAMES.has(value as DestinyClassName)
    ? (value as DestinyClassName)
    : undefined;
}

function resolveConfig(input: OptimizeArmorInput, build: BuildRecord | null): EffectiveConfig {
  const seed = build
    ? seedConstraintsFromBuild({
        exoticArmorHash: build.exoticArmorHash,
        softStatTargets: build.softStatTargets,
      })
    : {};
  const classType = input.classType ?? asClassName(build?.className);
  if (!classType) {
    throw new ApiError(API_ERROR_CODES.INVALID_ITEM, "classType is required", undefined, 400);
  }

  return {
    classType,
    lockedExoticItemHash: input.lockedExoticItemHash ?? seed.lockedExoticItemHash ?? null,
    requireExotic: input.requireExotic ?? seed.requireExotic ?? false,
    setBonusGoals: input.setBonusGoals ?? seed.setBonusGoals ?? [],
    statPriorities: input.statPriorities ?? seed.statPriorities ?? [],
    statThresholds: input.statThresholds ?? seed.statThresholds,
    requireThresholds: input.requireThresholds ?? false,
    includeModEstimates: input.includeModEstimates ?? seed.includeModEstimates ?? true,
    preferReuse: input.preferReuse ?? seed.preferReuse ?? false,
    maxResults: Math.min(50, Math.max(1, input.maxResults ?? 25)),
  };
}

function goalsReachable(candidates: CandidatePiece[], goals: SetBonusCoverageGoal[]): boolean {
  return goals.every((goal) => {
    const slots = new Set(
      candidates.filter((c) => c.setBonusKey === goal.setBonusKey).map((c) => c.slot),
    );
    return slots.size >= goal.minPieces;
  });
}

function buildSeed(config: EffectiveConfig): ArmorOptimizeSeed {
  return {
    classType: config.classType,
    ...(config.lockedExoticItemHash != null
      ? { lockedExoticItemHash: config.lockedExoticItemHash }
      : {}),
    ...(config.statThresholds ? { statThresholds: config.statThresholds } : {}),
    ...(config.statPriorities.length > 0 ? { statPriorities: config.statPriorities } : {}),
    preferReuse: config.preferReuse,
  };
}

async function resolveCandidates(
  input: OptimizeArmorInput,
  classType: DestinyClassName,
): Promise<{ candidates: CandidatePiece[]; hasInventory: boolean }> {
  if (input.candidates) return { candidates: input.candidates, hasInventory: true };
  if (!input.auth) {
    throw new ApiError(API_ERROR_CODES.INVALID_ITEM, "Authentication required", undefined, 401);
  }
  return loadArmorCandidates({
    db: input.db,
    userId: input.userId,
    auth: input.auth,
    classType,
    armorSetId: input.armorSetId,
  });
}

export async function optimizeArmor(input: OptimizeArmorInput): Promise<ArmorOptimizeResponse> {
  const build = input.buildId ? getBuild(input.db, input.userId, input.buildId) : null;
  if (input.buildId && !build) {
    throw new ApiError(API_ERROR_CODES.INVALID_ITEM, "BUILD_NOT_FOUND", { buildId: input.buildId }, 404);
  }

  const config = resolveConfig(input, build);
  const { candidates, hasInventory } = await resolveCandidates(input, config.classType);

  const constraints: KitConstraints = {
    lockedExoticItemHash: config.lockedExoticItemHash,
    requireExotic: config.requireExotic,
    setBonusGoals: config.setBonusGoals,
  };

  const pruned = prunePiecesBySlot(groupBySlot(candidates), {
    priorities: config.statPriorities,
    lockedExoticItemHash: config.lockedExoticItemHash,
    setBonusGoals: config.setBonusGoals,
  });
  const enumeration = enumerateKits(pruned, { constraints });

  let combos: ArmorCombination[] = enumeration.kits.map((kit) =>
    buildCombination(kit, {
      thresholds: config.statThresholds,
      priorities: config.statPriorities,
      includeModEstimates: config.includeModEstimates,
    }),
  );
  const beforeThresholdCount = combos.length;
  if (config.requireThresholds) combos = combos.filter((combo) => combo.meetsSoftThresholds);
  combos.sort((a, b) => compareCombinations(a, b, config.statPriorities, config.preferReuse));

  const truncated = enumeration.truncated || combos.length > config.maxResults;
  const combinations = combos.slice(0, config.maxResults);

  const response: ArmorOptimizeResponse = {
    combinations,
    truncated,
    evaluatedCount: enumeration.evaluatedCount,
    seed: buildSeed(config),
  };

  if (combinations.length === 0) {
    response.emptyReason = explainEmpty({
      hasInventory,
      classArmorCount: candidates.length,
      lockedExoticItemHash: config.lockedExoticItemHash,
      lockedExoticAvailable: candidates.some((c) => c.itemHash === config.lockedExoticItemHash),
      setBonusGoals: config.setBonusGoals,
      setBonusReachable: goalsReachable(candidates, config.setBonusGoals),
      requireThresholds: config.requireThresholds,
      thresholdsFilteredAll: config.requireThresholds && beforeThresholdCount > 0,
    });
  }

  return response;
}
