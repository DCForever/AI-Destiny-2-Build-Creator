import { SYNERGY_ELEMENTS } from "@/data/synergyElements";
import {
  resolveVerbSubType,
  SYNERGY_VERB_ALIASES,
  SYNERGY_VERB_NAMES,
} from "@/data/synergyVerbs";
import { CREATABLE_SYNERGY_TYPES } from "@/lib/synergies/schemas";
import { getSynergyTypeLabel } from "@/lib/synergies/generateSynergyName";

/** Normalize for equality: case, spacing, simple singular/plural. */
export function normalizeDesignationKey(name: string): string {
  let s = name.trim().toLowerCase().replace(/\s+/g, " ");
  // crude English plural: "stasis shards" / "champions" → singular
  if (s.endsWith("ses") && s.length > 4) {
    // e.g. "classes" — leave most *ses alone; "stasis" ends with sis not ses as whole word issue
  } else if (s.endsWith("s") && !s.endsWith("ss") && s.length > 3) {
    s = s.slice(0, -1);
  }
  return s;
}

/**
 * Prefer singular display form for novel keywords (Champions → Champion).
 * Curated verbs still resolve via resolveVerbSubType first by callers.
 */
export function singularizeKeywordLabel(name: string): string {
  const trimmed = name.trim();
  if (!trimmed) return trimmed;
  // multi-word: singularize last token only (Stasis Shards → Stasis Shard)
  const parts = trimmed.split(/\s+/);
  const last = parts[parts.length - 1]!;
  if (
    /s$/i.test(last) &&
    !/ss$/i.test(last) &&
    last.length > 3 &&
    !/sis$/i.test(last)
  ) {
    parts[parts.length - 1] = last.replace(/s$/i, "");
    return parts.join(" ");
  }
  return trimmed;
}

export type ExistingDesignationRef = {
  type: string;
  subType: string | null;
  label: string;
};

/**
 * Index of type labels + all known subtypes so gap discovery does not
 * re-propose e.g. "Glaive" as a novel verb when it is already a weapon archetype.
 */
export function buildExistingDesignationIndex(input?: {
  weaponArchetypeNames?: string[];
  meleeNames?: string[];
  grenadeNames?: string[];
  superNames?: string[];
}): {
  /** normalized key → canonical label + type */
  byKey: Map<string, ExistingDesignationRef>;
  /** normalized keys only */
  keys: Set<string>;
} {
  const byKey = new Map<string, ExistingDesignationRef>();

  function add(type: string, subType: string | null, label: string) {
    const key = normalizeDesignationKey(subType ?? type);
    if (!byKey.has(key)) {
      byKey.set(key, { type, subType, label });
    }
    // also index full "Type: Sub" style labels
    const full = normalizeDesignationKey(label);
    if (!byKey.has(full)) {
      byKey.set(full, { type, subType, label });
    }
  }

  for (const type of CREATABLE_SYNERGY_TYPES) {
    add(type, null, getSynergyTypeLabel(type));
  }

  for (const name of SYNERGY_VERB_NAMES) {
    add("verb", name, name);
  }
  for (const [alias, canonical] of Object.entries(SYNERGY_VERB_ALIASES)) {
    add("verb", canonical, canonical);
    // ensure alias form maps to same entry
    byKey.set(normalizeDesignationKey(alias), {
      type: "verb",
      subType: canonical,
      label: canonical,
    });
  }

  for (const name of SYNERGY_ELEMENTS) {
    add("element", name, name);
  }

  for (const name of input?.weaponArchetypeNames ?? []) {
    add("weapon_archetype", name, name);
  }
  for (const name of input?.meleeNames ?? []) {
    add("melee", name, name);
  }
  for (const name of input?.grenadeNames ?? []) {
    add("grenade", name, name);
  }
  for (const name of input?.superNames ?? []) {
    add("super", name, name);
  }

  return { byKey, keys: new Set(byKey.keys()) };
}

/** Resolve a free-text token to a known designation, if any. */
export function resolveExistingDesignation(
  token: string,
  index: ReturnType<typeof buildExistingDesignationIndex>,
): ExistingDesignationRef | null {
  const verb = resolveVerbSubType(token);
  if (verb) {
    return { type: "verb", subType: verb, label: verb };
  }
  const key = normalizeDesignationKey(token);
  return index.byKey.get(key) ?? null;
}
