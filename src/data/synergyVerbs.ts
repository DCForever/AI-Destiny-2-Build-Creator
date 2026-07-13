/**
 * Curated Destiny 2 keyword verbs for Verb synergy sub-types (007).
 * Sourced from Destinypedia element verb pages; elements are separate (synergyElements.ts).
 * Many verbs imply an element synergy (e.g. Ionic Trace → Arc).
 */

import type { SynergyElement } from "@/data/synergyElements";

export type SynergyVerbEntry = {
  name: string;
  description: string;
  /**
   * Damage element this verb belongs to when it is element-specific.
   * Null for subclass-agnostic keywords (Armor Charge, Exhaust, Sliding, …).
   */
  element: SynergyElement | null;
};

/** Legacy / plural display names accepted and normalized to canonical names. */
export const SYNERGY_VERB_ALIASES: Readonly<Record<string, string>> = {
  Suppress: "Suppression",
  /** Object text often uses plural. */
  "Stasis Shards": "Stasis Shard",
};

export const SYNERGY_VERBS: readonly SynergyVerbEntry[] = [
  // Solar
  {
    name: "Scorch",
    description: "Solar damage over time; stacks lead to Ignition.",
    element: "Solar",
  },
  {
    name: "Ignition",
    description: "Large Solar explosion.",
    element: "Solar",
  },
  {
    name: "Restoration",
    description: "Regenerates health and shields over time.",
    element: "Solar",
  },
  { name: "Cure", description: "Instant heal.", element: "Solar" },
  {
    name: "Radiant",
    description: "Increases weapon damage.",
    element: "Solar",
  },
  {
    name: "Firesprite",
    description: "Solar pickup companion.",
    element: "Solar",
  },
  // Arc
  {
    name: "Jolt",
    description: "Chains lightning; stuns Overload champions.",
    element: "Arc",
  },
  {
    name: "Blind",
    description: "Disorients targets; stuns Unstoppable champions.",
    element: "Arc",
  },
  {
    name: "Amplified",
    description: "Increased movement speed and weapon handling.",
    element: "Arc",
  },
  {
    name: "Bolt Charge",
    description: "Arc stacks that proc a lightning bolt at max.",
    element: "Arc",
  },
  {
    name: "Ionic Trace",
    description: "Arc pickup that grants Bolt Charge stacks.",
    element: "Arc",
  },
  // Subclass-agnostic / armor keyword (distinct from Bolt Charge)
  {
    name: "Armor Charge",
    description: "Stacks from orbs/armor mods that empower armor-charge effects.",
    element: null,
  },
  // Void
  {
    name: "Suppression",
    description: "Disables abilities; stuns Overload champions.",
    element: "Void",
  },
  {
    name: "Volatile",
    description: "Unstable Void energy; explodes on further damage.",
    element: "Void",
  },
  {
    name: "Weaken",
    description: "Reduces target damage output.",
    element: "Void",
  },
  {
    name: "Void Breach",
    description: "Void pickup orb.",
    element: "Void",
  },
  {
    name: "Devour",
    description: "Defeating targets heals you.",
    element: "Void",
  },
  {
    name: "Void Overshield",
    description: "Bonus Void shields.",
    element: "Void",
  },
  {
    name: "Invisibility",
    description: "Void stealth buff.",
    element: "Void",
  },
  // Stasis
  {
    name: "Slow",
    description: "Reduces movement; stuns Overload champions.",
    element: "Stasis",
  },
  {
    name: "Freeze",
    description: "Immobilizes targets for shatter combos.",
    element: "Stasis",
  },
  {
    name: "Shatter",
    description: "Burst on frozen break; stuns Unstoppable champions.",
    element: "Stasis",
  },
  {
    name: "Frost Armor",
    description: "Damage reduction buff.",
    element: "Stasis",
  },
  {
    name: "Stasis Crystal",
    description: "Solidified Stasis matter; freezes nearby targets.",
    element: "Stasis",
  },
  {
    name: "Stasis Shard",
    description: "Stasis pickup; grants melee and grenade energy.",
    element: "Stasis",
  },
  // Strand
  {
    name: "Suspend",
    description: "Lifts and immobilizes; stuns Unstoppable champions.",
    element: "Strand",
  },
  {
    name: "Unravel",
    description: "Strand damage propagates to linked targets.",
    element: "Strand",
  },
  {
    name: "Sever",
    description: "Reduces target damage output.",
    element: "Strand",
  },
  {
    name: "Threadling",
    description: "Seeking Strand creature.",
    element: "Strand",
  },
  {
    name: "Woven Mail",
    description: "Damage reduction buff.",
    element: "Strand",
  },
  {
    name: "Tangle",
    description: "Strand pickup; can be thrown for damage.",
    element: "Strand",
  },
  // Prismatic
  {
    name: "Transcendence",
    description: "Light and Darkness harmony state.",
    element: "Prismatic",
  },
  // Subclass-agnostic
  {
    name: "Exhaust",
    description: "Reduces enemy damage output; applied across elements.",
    element: null,
  },
  /** Movement / weapon keyword used by many perks and exotics (slide-shoot loops). */
  {
    name: "Sliding",
    description: "Slide-based movement and slide-shoot interactions.",
    element: null,
  },
] as const;

export const SYNERGY_VERB_NAMES: readonly string[] = SYNERGY_VERBS.map((v) => v.name);

const VERB_BY_NAME = new Map(
  SYNERGY_VERBS.map((v) => [v.name.toLowerCase(), v] as const),
);

function singularPluralForms(name: string): string[] {
  const t = name.trim();
  if (!t) return [];
  const forms = new Set<string>([t]);
  if (/s$/i.test(t) && !/ss$/i.test(t) && t.length > 3) {
    forms.add(t.replace(/s$/i, ""));
  } else {
    forms.add(`${t}s`);
  }
  return [...forms];
}

/**
 * Exact / alias / plural match only (no multi-word suffix walk).
 */
function resolveVerbSubTypeExact(name: string): string | null {
  const trimmed = name.trim();
  if (!trimmed) return null;

  for (const form of singularPluralForms(trimmed)) {
    if ((SYNERGY_VERB_NAMES as readonly string[]).includes(form)) return form;
    const aliasExact = SYNERGY_VERB_ALIASES[form];
    if (aliasExact) return aliasExact;
  }

  const lowerForms = singularPluralForms(trimmed).map((f) => f.toLowerCase());
  for (const canonical of SYNERGY_VERB_NAMES) {
    if (lowerForms.includes(canonical.toLowerCase())) return canonical;
  }
  for (const [alias, canonical] of Object.entries(SYNERGY_VERB_ALIASES)) {
    if (lowerForms.includes(alias.toLowerCase())) return canonical;
    if (lowerForms.includes(canonical.toLowerCase())) return canonical;
  }

  return null;
}

/**
 * Map a free-text verb name to the canonical curated subType.
 * Case-insensitive; accepts aliases, simple plurals (Stasis Shards → Stasis Shard),
 * and element-prefixed phrases (Solar Firesprite → Firesprite).
 */
export function resolveVerbSubType(name: string): string | null {
  const trimmed = name.trim();
  if (!trimmed) return null;

  const exact = resolveVerbSubTypeExact(trimmed);
  if (exact) return exact;

  // "Solar Firesprite", "Arc Ionic Traces" → trailing curated verb / multi-word verb
  const parts = trimmed.split(/\s+/);
  if (parts.length < 2) return null;
  // Longest trailing span first so "Void Breach" wins over bare "Breach" if both existed
  for (let start = 1; start < parts.length; start++) {
    const suffix = parts.slice(start).join(" ");
    const hit = resolveVerbSubTypeExact(suffix);
    if (hit) return hit;
  }

  return null;
}

export function isKnownVerbSubType(name: string): boolean {
  return resolveVerbSubType(name) !== null;
}

/**
 * Element implied by a curated verb (Ionic Trace → Arc).
 * Accepts free-text / aliases via resolveVerbSubType.
 */
export function impliedElementForVerb(
  verbName: string | null | undefined,
): SynergyElement | null {
  if (!verbName?.trim()) return null;
  const canonical = resolveVerbSubType(verbName);
  if (!canonical) return null;
  return VERB_BY_NAME.get(canonical.toLowerCase())?.element ?? null;
}

export function getSynergyVerbEntry(
  verbName: string | null | undefined,
): SynergyVerbEntry | undefined {
  if (!verbName?.trim()) return undefined;
  const canonical = resolveVerbSubType(verbName);
  if (!canonical) return undefined;
  return VERB_BY_NAME.get(canonical.toLowerCase());
}
