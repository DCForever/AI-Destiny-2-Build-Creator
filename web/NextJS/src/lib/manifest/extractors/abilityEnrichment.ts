/**
 * Derive subclass affinities and effect verbs for AbilityRecord enrichment (013).
 */

import {
  getAffinityOverride,
  getVerbOverride,
} from "@/data/abilityEnrichmentOverrides";
import { SUBCLASS_METADATA } from "@/data/subclasses.meta";
import {
  resolveVerbSubType,
  SYNERGY_VERB_ALIASES,
  SYNERGY_VERB_NAMES,
} from "@/data/synergyVerbs";
import type { DestinyClassName, ElementName } from "../types/records";

const DEDICATED_CAT_RE =
  /^(titan|hunter|warlock)\.(arc|solar|void|stasis|strand|prismatic)\.(supers|grenades|melee|class_abilities|movement)$/i;

const SHARED_CAT_RE = /^shared\./i;

const CLASS_PREFIX: Record<string, DestinyClassName> = {
  titan: "Titan",
  hunter: "Hunter",
  warlock: "Warlock",
};

const ELEMENT_SEGMENT: Record<string, ElementName> = {
  arc: "Arc",
  solar: "Solar",
  void: "Void",
  stasis: "Stasis",
  strand: "Strand",
  prismatic: "Prismatic",
};

function dedupe(values: string[]): string[] {
  return [...new Set(values)];
}

function isPrismaticSubclassName(name: string): boolean {
  return name.startsWith("Prismatic ");
}

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/** Dedicated subclasses matching class + element (excludes Prismatic variants). */
export function dedicatedSubclassesFor(
  classType: DestinyClassName | null,
  element: ElementName,
): string[] {
  return Object.values(SUBCLASS_METADATA)
    .filter((meta) => {
      if (isPrismaticSubclassName(meta.name)) return false;
      if (meta.element !== element) return false;
      if (classType != null && meta.classType !== classType) return false;
      return true;
    })
    .map((meta) => meta.name);
}

export type DeriveAffinitiesInput = {
  hash: number;
  plugCategoryIdentifier: string;
  classType: DestinyClassName | null;
  element: ElementName;
  /** Extra affinities from plug-set membership (e.g. proven Prismatic). */
  membershipAffinities?: string[];
};

/**
 * Tier 1: dedicated plug category → SUBCLASS_METADATA join.
 * Tier 2: shared → element-matched dedicated subclasses (no Prismatic by element alone).
 * Tier 3: membership affinities + curated overrides.
 */
export function deriveSubclassAffinities(input: DeriveAffinitiesInput): string[] {
  const { hash, plugCategoryIdentifier, classType, element, membershipAffinities = [] } =
    input;
  const cat = plugCategoryIdentifier.trim();
  const derived: string[] = [];

  const dedicatedMatch = DEDICATED_CAT_RE.exec(cat);
  if (dedicatedMatch) {
    const prefixClass = CLASS_PREFIX[dedicatedMatch[1].toLowerCase()] ?? classType;
    const catElement = ELEMENT_SEGMENT[dedicatedMatch[2].toLowerCase()] ?? element;
    derived.push(...dedicatedSubclassesFor(prefixClass, catElement));
  } else if (SHARED_CAT_RE.test(cat) || classType == null) {
    derived.push(...dedicatedSubclassesFor(null, element));
  } else {
    derived.push(...dedicatedSubclassesFor(classType, element));
  }

  const merged = dedupe([
    ...derived,
    ...membershipAffinities,
    ...getAffinityOverride(hash),
  ]);

  return merged.filter((name) => name !== "Prismatic");
}

export type DeriveVerbsInput = {
  hash: number;
  description: string;
  /** Additional text (e.g. sandbox perk description). */
  extraText?: string;
};

/** Word-boundary match against curated verbs; merge overrides; no loose substring. */
export function deriveAbilityVerbs(input: DeriveVerbsInput): string[] {
  const text = `${input.description}\n${input.extraText ?? ""}`;
  const found: string[] = [];

  for (const verbName of SYNERGY_VERB_NAMES) {
    const pattern = new RegExp(`\\b${escapeRegExp(verbName)}\\b`, "i");
    if (pattern.test(text)) {
      const canonical = resolveVerbSubType(verbName);
      if (canonical) found.push(canonical);
    }
  }

  for (const [alias, canonical] of Object.entries(SYNERGY_VERB_ALIASES)) {
    const pattern = new RegExp(`\\b${escapeRegExp(alias)}\\b`, "i");
    if (pattern.test(text)) found.push(canonical);
  }

  return dedupe([...found, ...getVerbOverride(input.hash)]);
}
