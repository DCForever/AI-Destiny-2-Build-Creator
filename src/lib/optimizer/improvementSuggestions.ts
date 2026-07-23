import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import type { AuthenticatedUser } from "@/lib/api/requireUser";
import type { AppDatabase } from "@/lib/db/client";
import { findAttachmentsBySetId, getSet } from "@/lib/db/repositories/setRepository";
import { listUserSets } from "@/lib/sets/setService";

import { optimizeFromSet } from "./optimizeFromSet";
import type { RankableCombination } from "./score";
import { parseOptimizerConstraints, type ArmorCombination } from "./types";

export type ImprovementSuggestion = {
  armorSetId: string;
  armorSetName: string;
  buildIds: string[];
  hasImprovement: boolean;
  betterCombination?: ArmorCombination;
  currentSummary?: RankableCombination;
};

export type ImprovementSuggestionsResponse = { suggestions: ImprovementSuggestion[] };

export type ImprovementSuggestionsInput = {
  db: AppDatabase;
  userId: number;
  auth: AuthenticatedUser;
  /** Hint that inventory just synced (attached constrained Sets). */
  afterSync?: boolean;
  /** On-open check for a single Set (attached or unattached). */
  armorSetId?: string;
};

/** Parse the improvement-suggestions query into a normalized input shape. */
export function parseImprovementSuggestionsQuery(url: URL): {
  afterSync: boolean;
  armorSetId?: string;
} {
  const armorSetId = url.searchParams.get("armorSetId");
  return {
    afterSync: url.searchParams.get("afterSync") === "1",
    ...(armorSetId ? { armorSetId } : {}),
  };
}

function attachedBuildIds(db: AppDatabase, setId: string): string[] {
  return [...new Set(findAttachmentsBySetId(db, setId).map((ref) => ref.buildId))];
}

async function suggestForSet(
  input: ImprovementSuggestionsInput,
  setId: string,
): Promise<ImprovementSuggestion> {
  const set = getSet(input.db, input.userId, setId);
  if (!set || set.type !== "armor") {
    throw new ApiError(API_ERROR_CODES.SET_NOT_FOUND, "Armor set not found", { setId }, 404);
  }
  const result = await optimizeFromSet({
    db: input.db,
    userId: input.userId,
    auth: input.auth,
    setId,
  });
  const top = result.combinations[0];
  return {
    armorSetId: setId,
    armorSetName: set.name,
    buildIds: attachedBuildIds(input.db, setId),
    hasImprovement: result.hasImprovement,
    ...(result.hasImprovement && top ? { betterCombination: top } : {}),
    ...(result.currentSummary ? { currentSummary: result.currentSummary } : {}),
  };
}

/**
 * Soft improvement suggestions (US5b): for a single opened Set, or for every
 * attached constrained Armor Set after a sync. Never mutates Set items — the
 * client confirms via apply-combination (suggest-then-confirm).
 */
export async function buildImprovementSuggestions(
  input: ImprovementSuggestionsInput,
): Promise<ImprovementSuggestionsResponse> {
  if (input.armorSetId) {
    return { suggestions: [await suggestForSet(input, input.armorSetId)] };
  }

  const suggestions: ImprovementSuggestion[] = [];
  for (const set of listUserSets(input.db, input.userId, { type: "armor" })) {
    if (!parseOptimizerConstraints(set.optimizerConstraints)) continue;
    if (attachedBuildIds(input.db, set.id).length === 0) continue;
    const suggestion = await suggestForSet(input, set.id);
    if (suggestion.hasImprovement) suggestions.push(suggestion);
  }
  return { suggestions };
}
