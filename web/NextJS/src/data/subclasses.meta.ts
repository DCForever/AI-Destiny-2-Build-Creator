/**
 * Curated subclass metadata: element and champion-relevant verbs.
 * Each verb cites a source file in src/data/meta/sources/ for reviewability.
 */

import type { ElementName } from "@/lib/manifest/types/records";
import type { GuardianClass } from "./subclasses";

export interface SubclassVerbMeta {
  name: string;
  description: string;
  /** Relative path under src/data/meta/sources/ */
  source: string;
}

export interface SubclassMeta {
  name: string;
  classType: GuardianClass;
  element: ElementName;
  verbs: SubclassVerbMeta[];
}

const PATCH = "bungie-update-9-7-0-patch-notes.txt";
const DEV_INSIGHT = "dev-insight-abilities-armor-preview.txt";
const KYBERS = "kyberscorner-sandbox-abilities-armor.txt";

function verbs(...items: SubclassVerbMeta[]): SubclassVerbMeta[] {
  return items;
}

export const SUBCLASS_METADATA: Record<string, SubclassMeta> = {
  Sunbreaker: {
    name: "Sunbreaker",
    classType: "Titan",
    element: "Solar",
    verbs: verbs(
      { name: "Ignition", description: "Large Solar explosions that scorch nearby targets.", source: PATCH },
      { name: "Scorch", description: "Solar damage over time; stacks increase ignition potency.", source: PATCH },
      { name: "Restoration", description: "Regenerates health and shields over time.", source: DEV_INSIGHT },
    ),
  },
  Striker: {
    name: "Striker",
    classType: "Titan",
    element: "Arc",
    verbs: verbs(
      { name: "Jolt", description: "Arc targets chain lightning to nearby enemies.", source: PATCH },
      { name: "Blind", description: "Disorients combatants, stunning Unstoppable champions.", source: PATCH },
    ),
  },
  Behemoth: {
    name: "Behemoth",
    classType: "Titan",
    element: "Stasis",
    verbs: verbs(
      { name: "Shatter", description: "Breaking frozen targets deals burst damage; stuns Unstoppable.", source: PATCH },
      { name: "Slow", description: "Reduces target movement; stuns Overload champions.", source: PATCH },
      { name: "Freeze", description: "Immobilizes targets for shatter combos.", source: KYBERS },
    ),
  },
  Sentinel: {
    name: "Sentinel",
    classType: "Titan",
    element: "Void",
    verbs: verbs(
      { name: "Suppress", description: "Disables enemy abilities; stuns Overload champions.", source: PATCH },
      { name: "Volatile", description: "Void targets explode on death (damage buff vs champions, not Barrier stun).", source: PATCH },
    ),
  },
  Berserker: {
    name: "Berserker",
    classType: "Titan",
    element: "Strand",
    verbs: verbs(
      { name: "Suspend", description: "Lifts and immobilizes targets; stuns Unstoppable champions.", source: PATCH },
      { name: "Unravel", description: "Strand damage spreads to nearby targets.", source: DEV_INSIGHT },
    ),
  },
  "Prismatic Titan": {
    name: "Prismatic Titan",
    classType: "Titan",
    element: "Prismatic",
    verbs: verbs(
      { name: "Ignition", description: "Prismatic facet: Solar ignition explosions.", source: PATCH },
      { name: "Jolt", description: "Prismatic facet: Arc jolt chains.", source: PATCH },
      { name: "Shatter", description: "Prismatic facet: Stasis shatter burst.", source: PATCH },
      { name: "Suppress", description: "Prismatic facet: Void suppression.", source: PATCH },
      { name: "Suspend", description: "Prismatic facet: Strand suspension.", source: PATCH },
    ),
  },
  Gunslinger: {
    name: "Gunslinger",
    classType: "Hunter",
    element: "Solar",
    verbs: verbs(
      { name: "Ignition", description: "Solar explosions from scorched targets.", source: PATCH },
      { name: "Scorch", description: "Solar burn stacking for ignition.", source: PATCH },
      { name: "Restoration", description: "Health and shield regeneration.", source: DEV_INSIGHT },
    ),
  },
  Arcstrider: {
    name: "Arcstrider",
    classType: "Hunter",
    element: "Arc",
    verbs: verbs(
      { name: "Jolt", description: "Lightning chains between Arc-damaged targets.", source: PATCH },
      { name: "Blind", description: "Blinds and disorients; Unstoppable counter.", source: PATCH },
    ),
  },
  Revenant: {
    name: "Revenant",
    classType: "Hunter",
    element: "Stasis",
    verbs: verbs(
      { name: "Shatter", description: "Shatter damage stuns Unstoppable champions.", source: PATCH },
      { name: "Slow", description: "Slows targets; Overload counter.", source: PATCH },
      { name: "Freeze", description: "Freezes for shatter setups.", source: KYBERS },
    ),
  },
  Nightstalker: {
    name: "Nightstalker",
    classType: "Hunter",
    element: "Void",
    verbs: verbs(
      { name: "Suppress", description: "Suppresses abilities; Overload counter.", source: PATCH },
      { name: "Volatile", description: "Void explosions on defeated targets.", source: PATCH },
    ),
  },
  Threadrunner: {
    name: "Threadrunner",
    classType: "Hunter",
    element: "Strand",
    verbs: verbs(
      { name: "Suspend", description: "Suspends targets in mid-air; Unstoppable counter.", source: PATCH },
      { name: "Unravel", description: "Strand damage propagates to linked targets.", source: DEV_INSIGHT },
    ),
  },
  "Prismatic Hunter": {
    name: "Prismatic Hunter",
    classType: "Hunter",
    element: "Prismatic",
    verbs: verbs(
      { name: "Ignition", description: "Prismatic facet: Solar ignition.", source: PATCH },
      { name: "Jolt", description: "Prismatic facet: Arc jolt.", source: PATCH },
      { name: "Shatter", description: "Prismatic facet: Stasis shatter.", source: PATCH },
      { name: "Suppress", description: "Prismatic facet: Void suppress.", source: PATCH },
      { name: "Suspend", description: "Prismatic facet: Strand suspend.", source: PATCH },
    ),
  },
  Dawnblade: {
    name: "Dawnblade",
    classType: "Warlock",
    element: "Solar",
    verbs: verbs(
      { name: "Ignition", description: "Large Solar detonations.", source: PATCH },
      { name: "Scorch", description: "Solar damage over time.", source: PATCH },
      { name: "Restoration", description: "Healing and shield regen.", source: DEV_INSIGHT },
    ),
  },
  Stormcaller: {
    name: "Stormcaller",
    classType: "Warlock",
    element: "Arc",
    verbs: verbs(
      { name: "Jolt", description: "Arc chains between targets; Overload counter.", source: PATCH },
      { name: "Blind", description: "Blinds enemies; Unstoppable counter.", source: PATCH },
    ),
  },
  Shadebinder: {
    name: "Shadebinder",
    classType: "Warlock",
    element: "Stasis",
    verbs: verbs(
      { name: "Shatter", description: "Shatter damage; Unstoppable counter.", source: PATCH },
      { name: "Slow", description: "Slows targets; Overload counter.", source: PATCH },
      { name: "Freeze", description: "Freezes for shatter.", source: KYBERS },
    ),
  },
  Voidwalker: {
    name: "Voidwalker",
    classType: "Warlock",
    element: "Void",
    verbs: verbs(
      { name: "Suppress", description: "Suppresses abilities; Overload counter.", source: PATCH },
      { name: "Volatile", description: "Void detonations on defeat.", source: DEV_INSIGHT },
    ),
  },
  Broodweaver: {
    name: "Broodweaver",
    classType: "Warlock",
    element: "Strand",
    verbs: verbs(
      { name: "Suspend", description: "Suspends targets; Unstoppable counter.", source: PATCH },
      { name: "Unravel", description: "Strand damage threads to nearby enemies.", source: DEV_INSIGHT },
    ),
  },
  "Prismatic Warlock": {
    name: "Prismatic Warlock",
    classType: "Warlock",
    element: "Prismatic",
    verbs: verbs(
      { name: "Ignition", description: "Prismatic facet: Solar ignition.", source: PATCH },
      { name: "Jolt", description: "Prismatic facet: Arc jolt.", source: PATCH },
      { name: "Shatter", description: "Prismatic facet: Stasis shatter.", source: PATCH },
      { name: "Suppress", description: "Prismatic facet: Void suppress.", source: PATCH },
      { name: "Suspend", description: "Prismatic facet: Strand suspend.", source: PATCH },
    ),
  },
};

export function getSubclassMeta(name: string): SubclassMeta | undefined {
  return SUBCLASS_METADATA[name];
}

export function formatSubclassLabel(name: string): string {
  const meta = getSubclassMeta(name);
  if (!meta) return name;
  const verbNames = meta.verbs.map(v => v.name).join(", ");
  return `${meta.name} — ${meta.element} · ${verbNames}`;
}

export function listSubclassVerbs(name: string): SubclassVerbMeta[] {
  return getSubclassMeta(name)?.verbs ?? [];
}
