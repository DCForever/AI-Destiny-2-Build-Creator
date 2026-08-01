/**
 * Curated affinity/verb overrides for ability enrichment (013).
 * Used when plug-category derivation is incomplete (e.g. Prismatic dual-affinity)
 * or description wording is ambiguous for acceptance anchors.
 */

export type AbilityAffinityOverride = {
  subclassAffinities: string[];
};

export type AbilityVerbOverride = {
  verbs: string[];
};

/** Hash → subclass affinities (merged with derived affinities). */
export const ABILITY_AFFINITY_OVERRIDES: Readonly<Record<number, AbilityAffinityOverride>> = {
  // Phoenix Dive — Dawnblade + Prismatic Warlock (FR-006)
  1026: { subclassAffinities: ["Dawnblade", "Prismatic Warlock"] },
};

/** Hash → effect verbs (merged with derived verbs). */
export const ABILITY_VERB_OVERRIDES: Readonly<Record<number, AbilityVerbOverride>> = {
  // Phoenix Dive — Cure (FR-006)
  1026: { verbs: ["Cure"] },
  // Chaos Reach — Jolt (FR-007); fixture description may omit the keyword
  1018: { verbs: ["Jolt"] },
};

export function getAffinityOverride(hash: number): string[] {
  return ABILITY_AFFINITY_OVERRIDES[hash]?.subclassAffinities ?? [];
}

export function getVerbOverride(hash: number): string[] {
  return ABILITY_VERB_OVERRIDES[hash]?.verbs ?? [];
}
