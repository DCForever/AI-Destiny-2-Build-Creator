import { z } from "zod";

/** Facets group concept tags in UI pickers and filter bars. */
export const CONCEPT_TAG_FACETS = [
  "activity",
  "element",
  "playstyle",
  "role",
] as const;

export type ConceptTagFacet = (typeof CONCEPT_TAG_FACETS)[number];

export type ConceptTag = {
  readonly id: string;
  readonly label: string;
  readonly facet: ConceptTagFacet;
};

export const CONCEPT_TAGS = [
  // activity
  { id: "pve", label: "PVE", facet: "activity" },
  { id: "pvp", label: "PVP", facet: "activity" },
  { id: "grandmaster", label: "Grandmaster", facet: "activity" },
  { id: "nightfall", label: "Nightfall", facet: "activity" },
  { id: "dungeon", label: "Dungeon", facet: "activity" },
  { id: "raid", label: "Raid", facet: "activity" },
  { id: "solo", label: "Solo", facet: "activity" },
  { id: "trials", label: "Trials", facet: "activity" },
  { id: "crucible", label: "Crucible", facet: "activity" },
  // element
  { id: "solar", label: "Solar", facet: "element" },
  { id: "arc", label: "Arc", facet: "element" },
  { id: "void", label: "Void", facet: "element" },
  { id: "stasis", label: "Stasis", facet: "element" },
  { id: "strand", label: "Strand", facet: "element" },
  { id: "kinetic", label: "Kinetic", facet: "element" },
  { id: "prismatic", label: "Prismatic", facet: "element" },
  // playstyle
  { id: "melee", label: "Melee", facet: "playstyle" },
  { id: "grenade", label: "Grenade", facet: "playstyle" },
  { id: "super", label: "Super", facet: "playstyle" },
  { id: "support", label: "Support", facet: "playstyle" },
  { id: "dps", label: "DPS", facet: "playstyle" },
  { id: "survival", label: "Survival", facet: "playstyle" },
  { id: "healing", label: "Healing", facet: "playstyle" },
  { id: "ability", label: "Ability", facet: "playstyle" },
  // role
  { id: "additive", label: "Additive", facet: "role" },
  { id: "crowd_control", label: "Crowd Control", facet: "role" },
  { id: "champion", label: "Champion", facet: "role" },
  { id: "orbit", label: "Orbit", facet: "role" },
] as const satisfies readonly ConceptTag[];

export type ConceptTagId = (typeof CONCEPT_TAGS)[number]["id"];

const CONCEPT_TAG_IDS = CONCEPT_TAGS.map((t) => t.id) as [
  ConceptTagId,
  ...ConceptTagId[],
];

export const conceptTagIdSchema = z.enum(CONCEPT_TAG_IDS);

export const conceptTagIdsSchema = z
  .array(conceptTagIdSchema)
  .refine((ids) => new Set(ids).size === ids.length, {
    message: "Duplicate concept tag ids are not allowed",
  });

export function isConceptTagId(value: string): value is ConceptTagId {
  return conceptTagIdSchema.safeParse(value).success;
}

export function getConceptTag(id: ConceptTagId): ConceptTag | undefined {
  return CONCEPT_TAGS.find((t) => t.id === id);
}

export function getConceptTagLabel(id: ConceptTagId): string {
  return getConceptTag(id)?.label ?? id;
}

/** Group tags by facet for UI pickers (activity, element, playstyle, role). */
export function conceptTagsByFacet(): Record<ConceptTagFacet, ConceptTag[]> {
  const grouped = Object.fromEntries(
    CONCEPT_TAG_FACETS.map((facet) => [facet, [] as ConceptTag[]]),
  ) as Record<ConceptTagFacet, ConceptTag[]>;

  for (const tag of CONCEPT_TAGS) {
    grouped[tag.facet].push(tag);
  }

  return grouped;
}

/** Display shorthand for multi-tag filter (e.g. Solar · Melee). */
export function formatTagFilterLabel(tagIds: ConceptTagId[]): string {
  return tagIds.map((id) => getConceptTagLabel(id)).join(" · ");
}
