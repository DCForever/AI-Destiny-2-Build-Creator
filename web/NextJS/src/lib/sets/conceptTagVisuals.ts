/**
 * Map concept tags → designation icons / element colors for icon-first UI.
 * Client-safe (no Node/fs).
 */

import {
  CONCEPT_TAGS,
  getConceptTag,
  type ConceptTagId,
  isConceptTagId,
} from "@/data/conceptTags";
import {
  ELEMENT_CSS_COLOR,
  isDestinyElement,
  type DestinyElement,
} from "@/lib/destiny/identityVisuals";
import type { DesignationRef } from "@/lib/synergies/designationIconShared";

export type ConceptTagVisual = {
  tagId: string;
  label: string;
  /** Designation lookup for Bungie icon API (null when no icon expected). */
  designation: DesignationRef | null;
  /** CSS color for element tags (and accent ring). */
  accentColor: string | null;
  facet: string | null;
  /** True when UI can render a glyph without Bungie path (e.g. element SVG). */
  hasGlyphFallback: boolean;
};

/**
 * Playstyle tags → designations with official icons.
 * Melee / Grenade / Super use DestinyStatDefinition category glyphs (not a random ability).
 * Ability has no generic Bungie category icon — stays text-only.
 */
const PLAYSTYLE_DESIGNATION: Partial<
  Record<string, { type: string; subType: string }>
> = {
  melee: { type: "melee", subType: "Melee" },
  grenade: { type: "grenade", subType: "Grenade" },
  super: { type: "super", subType: "Super" },
  healing: { type: "verb", subType: "Cure" },
  support: { type: "verb", subType: "Cure" },
  dps: { type: "verb", subType: "Radiant" },
  survival: { type: "verb", subType: "Woven Mail" },
};

/**
 * Visual presentation for a concept tag id (e.g. "arc", "grenade").
 */
export function conceptTagVisual(tagId: string): ConceptTagVisual {
  const tag = isConceptTagId(tagId) ? getConceptTag(tagId) : undefined;
  const label = tag?.label ?? tagId;
  const facet = tag?.facet ?? null;

  if (facet === "element" || isDestinyElement(label)) {
    const elementCandidate = isDestinyElement(label)
      ? label
      : capitalize(tagId);
    const element = isDestinyElement(elementCandidate)
      ? (elementCandidate as DestinyElement)
      : null;
    return {
      tagId,
      label: element ?? label,
      designation: element
        ? { type: "element", subType: element }
        : { type: "element", subType: label },
      accentColor: element ? ELEMENT_CSS_COLOR[element] : null,
      facet: facet ?? "element",
      hasGlyphFallback: Boolean(element),
    };
  }

  const play = PLAYSTYLE_DESIGNATION[tagId];
  if (play) {
    return {
      tagId,
      label,
      designation: play,
      accentColor: null,
      facet,
      hasGlyphFallback: false,
    };
  }

  // Activity / role / unknown — text labels only (no designation fetch).
  return {
    tagId,
    label,
    designation: null,
    accentColor: null,
    facet,
    hasGlyphFallback: false,
  };
}

/** Designation refs for a list of tag ids (for batch icon fetch). */
export function conceptTagDesignationRefs(tagIds: string[]): DesignationRef[] {
  const refs: DesignationRef[] = [];
  const seen = new Set<string>();
  for (const id of tagIds) {
    const v = conceptTagVisual(id);
    if (!v.designation) continue;
    const key = `${v.designation.type}::${v.designation.subType ?? ""}`;
    if (seen.has(key)) continue;
    seen.add(key);
    refs.push(v.designation);
  }
  return refs;
}

/** All concept tags that can resolve icons (for curated preload). */
export function allConceptTagDesignationRefs(): DesignationRef[] {
  return conceptTagDesignationRefs(CONCEPT_TAGS.map((t) => t.id as ConceptTagId));
}

function capitalize(s: string): string {
  if (!s) return s;
  return s.charAt(0).toUpperCase() + s.slice(1).toLowerCase();
}
