/**
 * Universal Catalog composition kinds and action eligibility (027).
 * Mirrors specs/027-catalog-universal-search/data-model.md and research.md R2.
 */

export const COMPOSITION_KINDS = [
  "weapon",
  "exotic_weapon",
  "armor",
  "exotic_armor",
  "mod",
  "weapon_perk",
  "origin_trait",
  "armor_set_bonus",
  "artifact_perk",
  "aspect",
  "fragment",
  "ability",
] as const;

export type CompositionKind = (typeof COMPOSITION_KINDS)[number];

const KIND_SET = new Set<string>(COMPOSITION_KINDS);

const LABELS: Record<CompositionKind, string> = {
  weapon: "Weapon",
  exotic_weapon: "Exotic weapon",
  armor: "Armor",
  exotic_armor: "Exotic armor",
  mod: "Mod",
  weapon_perk: "Weapon perk",
  origin_trait: "Origin trait",
  armor_set_bonus: "Armor set bonus",
  artifact_perk: "Artifact perk",
  aspect: "Aspect",
  fragment: "Fragment",
  ability: "Ability",
};

/** Set types a hit may target on create/add (FR-017). */
export type CompositionSetType = "weapon" | "armor" | "mod" | "pair";

const SET_ELIGIBLE = new Set<CompositionKind>([
  "weapon",
  "exotic_weapon",
  "armor",
  "exotic_armor",
  "mod",
]);

/** Equippable kinds that may carry inventory ownership annotations. */
export const OWNABLE_COMPOSITION_KINDS: ReadonlySet<CompositionKind> = SET_ELIGIBLE;

const SYNERGY_ELIGIBLE = new Set<CompositionKind>([
  "weapon",
  "exotic_weapon",
  "weapon_perk",
  "origin_trait",
  "armor_set_bonus",
  "exotic_armor",
  "artifact_perk",
]);

const SET_TYPES_BY_KIND: Record<CompositionKind, readonly CompositionSetType[]> = {
  weapon: ["weapon"],
  exotic_weapon: ["weapon", "pair"],
  armor: ["armor"],
  exotic_armor: ["armor", "pair"],
  mod: ["mod"],
  weapon_perk: [],
  origin_trait: [],
  armor_set_bonus: [],
  artifact_perk: [],
  aspect: [],
  fragment: [],
  ability: [],
};

export function isCompositionKind(value: string): value is CompositionKind {
  return KIND_SET.has(value);
}

/**
 * Parse `kinds` query CSV. Omit/undefined → all v1 kinds.
 * Invalid tokens → `{ error }`. Empty CSV (no tokens) → `[]`.
 */
export function parseKindsParam(
  csv: string | undefined,
): CompositionKind[] | { error: string } {
  if (csv === undefined) {
    return [...COMPOSITION_KINDS];
  }

  const raw = csv.trim();
  if (raw === "") {
    return [];
  }

  const parts = raw.split(",").map((p) => p.trim()).filter((p) => p.length > 0);
  if (parts.length === 0) {
    return [];
  }

  const out: CompositionKind[] = [];
  const seen = new Set<CompositionKind>();
  for (const part of parts) {
    if (!isCompositionKind(part)) {
      return { error: `Invalid kind: ${part}` };
    }
    if (!seen.has(part)) {
      seen.add(part);
      out.push(part);
    }
  }
  return out;
}

export function compositionKindLabel(kind: CompositionKind): string {
  return LABELS[kind];
}

export function hitActions(kind: CompositionKind): { set: boolean; synergy: boolean } {
  return {
    set: SET_ELIGIBLE.has(kind),
    synergy: SYNERGY_ELIGIBLE.has(kind),
  };
}

/** Alias used by universal search hit construction. */
export const compositionActionsForKind = hitActions;

export function setTypesForHit(kind: CompositionKind): CompositionSetType[] {
  return [...SET_TYPES_BY_KIND[kind]];
}
