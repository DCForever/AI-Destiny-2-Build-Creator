import { z } from "zod";

import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import type { AuthenticatedUser } from "@/lib/api/requireUser";
import { resolveInventoryHashProjections } from "@/lib/catalog/inventoryHashProjections";
import type { AppDatabase } from "@/lib/db/client";
import { getSet } from "@/lib/db/repositories/setRepository";
import type { DestinyClassName } from "@/lib/manifest/types/records";
import { listActiveSetItems } from "@/lib/sets/setItemService";
import { getServices } from "@/lib/services";

import { detectImprovement } from "./detectImprovement";
import { estimateCombinationStats } from "./estimate";
import { loadArmorCandidates } from "./loadArmorCandidates";
import { optimizeArmor } from "./optimizeArmor";
import type { RankableCombination } from "./score";
import {
  armorSetOptimizerConstraintsSchema,
  parseOptimizerConstraints,
  type ArmorOptimizeResponse,
  type ArmorSetOptimizerConstraints,
  type CandidatePiece,
} from "./types";

const destinyClassNameSchema = z.enum(["Titan", "Hunter", "Warlock"]);

/** Zod contract for `POST /api/user/sets/[id]/optimize`. */
export const refreshOptimizeBodySchema = z.object({
  overrides: armorSetOptimizerConstraintsSchema.partial().optional(),
  maxResults: z.number().int().min(1).max(50).optional(),
  /** When the set has no pieces, clients (Finish) pass build class. */
  classType: destinyClassNameSchema.optional(),
});

export type RefreshOptimizeBody = z.infer<typeof refreshOptimizeBodySchema>;

export type OptimizeFromSetInput = {
  db: AppDatabase;
  userId: number;
  auth?: AuthenticatedUser;
  setId: string;
  /** Per-run constraint overrides (not persisted). */
  overrides?: Partial<ArmorSetOptimizerConstraints>;
  maxResults?: number;
  /** Resolved by the route from set items; injected directly in tests. */
  classType?: DestinyClassName;
  candidates?: CandidatePiece[];
};

export type RefreshOptimizeResult = ArmorOptimizeResponse & {
  armorSetId: string;
  constraintsUsed: ArmorSetOptimizerConstraints;
  hasImprovement: boolean;
  /** Current-pieces estimate used for the improvement comparison. */
  currentSummary?: RankableCombination;
};

const CLASS_NAMES = new Set<string>(["Titan", "Hunter", "Warlock"]);

function asClassName(value: string | undefined): DestinyClassName | undefined {
  return value != null && CLASS_NAMES.has(value) ? (value as DestinyClassName) : undefined;
}

async function resolveClassType(
  db: AppDatabase,
  setId: string,
): Promise<DestinyClassName | undefined> {
  const hashes = (await listActiveSetItems(db, setId)).map((item) => item.itemHash);
  if (hashes.length === 0) return undefined;
  const { manifest } = await getServices();
  const version = (await manifest.getStatus()).cachedVersion;
  if (!version) return undefined;
  const projections = await resolveInventoryHashProjections(manifest, version, hashes);
  for (const hash of hashes) {
    const classType = asClassName(projections.get(hash)?.classType);
    if (classType) return classType;
  }
  return undefined;
}

async function currentRankable(
  db: AppDatabase,
  setId: string,
  candidates: CandidatePiece[],
  constraints: ArmorSetOptimizerConstraints,
): Promise<RankableCombination | null> {
  const byInstance = new Map(candidates.map((piece) => [piece.instanceId, piece]));
  const pieces: CandidatePiece[] = [];
  for (const item of await listActiveSetItems(db, setId)) {
    const match = item.instanceId ? byInstance.get(item.instanceId) : undefined;
    if (match) pieces.push(match);
  }
  if (pieces.length === 0) return null;

  const { estimatedStats } = estimateCombinationStats({
    kit: pieces,
    thresholds: constraints.statThresholds,
    priorities: constraints.statPriorities,
    includeModEstimates: constraints.includeModEstimates ?? true,
  });
  return { estimatedStats, reusePieceCount: pieces.filter((p) => p.usedInSets.length > 0).length };
}

async function resolveCandidates(
  input: OptimizeFromSetInput,
  classType: DestinyClassName,
): Promise<CandidatePiece[]> {
  if (input.candidates) return input.candidates;
  if (!input.auth) {
    throw new ApiError(API_ERROR_CODES.INVALID_ITEM, "Authentication required", undefined, 401);
  }
  const loaded = await loadArmorCandidates({
    db: input.db,
    userId: input.userId,
    auth: input.auth,
    classType,
    armorSetId: input.setId,
  });
  return loaded.candidates;
}

/**
 * Refresh search (US5b): re-run the optimizer from a Set's stored constraints
 * (with optional per-run overrides), excluding the Set itself from reuse
 * annotations, and flag whether the top kit improves on the current pieces.
 */
export async function optimizeFromSet(input: OptimizeFromSetInput): Promise<RefreshOptimizeResult> {
  const set = getSet(input.db, input.userId, input.setId);
  if (!set || set.type !== "armor") {
    throw new ApiError(API_ERROR_CODES.SET_NOT_FOUND, "Armor set not found", { setId: input.setId }, 404);
  }
  const stored = parseOptimizerConstraints(set.optimizerConstraints);
  if (!stored) {
    throw new ApiError(API_ERROR_CODES.NO_CONSTRAINTS, "Set has no stored constraints", undefined, 400);
  }
  const constraintsUsed: ArmorSetOptimizerConstraints = { ...stored, ...input.overrides };

  const classType = input.classType ?? (await resolveClassType(input.db, input.setId));
  if (!classType) {
    throw new ApiError(API_ERROR_CODES.INVALID_ITEM, "Unable to resolve set class type", undefined, 400);
  }
  const candidates = await resolveCandidates(input, classType);

  const response = await optimizeArmor({
    db: input.db,
    userId: input.userId,
    auth: input.auth,
    armorSetId: input.setId,
    classType,
    candidates,
    ...constraintsUsed,
    ...(input.maxResults != null ? { maxResults: input.maxResults } : {}),
  });

  const top = response.combinations[0];
  const current = await currentRankable(input.db, input.setId, candidates, constraintsUsed);
  const hasImprovement =
    top != null &&
    current != null &&
    detectImprovement(
      current,
      { estimatedStats: top.estimatedStats, reusePieceCount: top.reusePieceCount },
      constraintsUsed.statPriorities,
      constraintsUsed.preferReuse ?? false,
    );

  return {
    ...response,
    armorSetId: input.setId,
    constraintsUsed,
    hasImprovement,
    ...(current ? { currentSummary: current } : {}),
  };
}
