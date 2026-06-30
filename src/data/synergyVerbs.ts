/**
 * Curated Destiny 2 keyword verbs for Verb synergy sub-types (007).
 * Sourced from Destinypedia element verb pages; elements are separate (synergyElements.ts).
 */

export type SynergyVerbEntry = {
  name: string;
  description: string;
};

/** Legacy display names accepted at validation and normalized to canonical names. */
export const SYNERGY_VERB_ALIASES: Readonly<Record<string, string>> = {
  Suppress: "Suppression",
};

export const SYNERGY_VERBS: readonly SynergyVerbEntry[] = [
  // Solar
  { name: "Scorch", description: "Solar damage over time; stacks lead to Ignition." },
  { name: "Ignition", description: "Large Solar explosion." },
  { name: "Restoration", description: "Regenerates health and shields over time." },
  { name: "Cure", description: "Instant heal." },
  { name: "Radiant", description: "Increases weapon damage." },
  { name: "Firesprite", description: "Solar pickup companion." },
  // Arc
  { name: "Jolt", description: "Chains lightning; stuns Overload champions." },
  { name: "Blind", description: "Disorients targets; stuns Unstoppable champions." },
  { name: "Amplified", description: "Increased movement speed and weapon handling." },
  { name: "Bolt Charge", description: "Arc stacks that proc a lightning bolt at max." },
  { name: "Ionic Trace", description: "Arc pickup that grants Bolt Charge stacks." },
  // Void
  { name: "Suppression", description: "Disables abilities; stuns Overload champions." },
  { name: "Volatile", description: "Unstable Void energy; explodes on further damage." },
  { name: "Weaken", description: "Reduces target damage output." },
  { name: "Void Breach", description: "Void pickup orb." },
  { name: "Devour", description: "Defeating targets heals you." },
  { name: "Void Overshield", description: "Bonus Void shields." },
  { name: "Invisibility", description: "Void stealth buff." },
  // Stasis
  { name: "Slow", description: "Reduces movement; stuns Overload champions." },
  { name: "Freeze", description: "Immobilizes targets for shatter combos." },
  { name: "Shatter", description: "Burst on frozen break; stuns Unstoppable champions." },
  { name: "Frost Armor", description: "Damage reduction buff." },
  { name: "Stasis Crystal", description: "Solidified Stasis matter; freezes nearby targets." },
  { name: "Stasis Shard", description: "Stasis pickup; grants melee and grenade energy." },
  // Strand
  { name: "Suspend", description: "Lifts and immobilizes; stuns Unstoppable champions." },
  { name: "Unravel", description: "Strand damage propagates to linked targets." },
  { name: "Sever", description: "Reduces target damage output." },
  { name: "Threadling", description: "Seeking Strand creature." },
  { name: "Woven Mail", description: "Damage reduction buff." },
  { name: "Tangle", description: "Strand pickup; can be thrown for damage." },
  // Prismatic
  { name: "Transcendence", description: "Light and Darkness harmony state." },
  // Subclass-agnostic
  { name: "Exhaust", description: "Reduces enemy damage output; applied across elements." },
] as const;

export const SYNERGY_VERB_NAMES: readonly string[] = SYNERGY_VERBS.map((v) => v.name);

export function resolveVerbSubType(name: string): string | null {
  if ((SYNERGY_VERB_NAMES as readonly string[]).includes(name)) return name;
  return SYNERGY_VERB_ALIASES[name] ?? null;
}

export function isKnownVerbSubType(name: string): boolean {
  return resolveVerbSubType(name) !== null;
}
