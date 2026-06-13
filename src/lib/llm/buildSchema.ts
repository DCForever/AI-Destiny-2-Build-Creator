/**
 * The build contract between the LLM and the app. The model outputs names and
 * rationale ONLY — never hashes. The app resolves names against the manifest
 * entity stores and validates perk/fragment legality afterwards.
 *
 * Converted to JSON Schema (z.toJSONSchema) for Phase B structured output.
 */

import { z } from "zod";

const trimmed = z.string().trim().min(1);

export const buildRequestSchema = z.object({
  className: z.enum(["Titan", "Hunter", "Warlock"]),
  subclass: trimmed.describe('Subclass name, e.g. "Sunbreaker" or "Prismatic"'),
  activity: trimmed.describe('Target activity, e.g. "Grandmaster Nightfall"'),
  playstyle: trimmed.describe('Playstyle, e.g. "aggressive melee"'),
  preferredExotic: z.string().trim().optional(),
  preferredWeapon: z.string().trim().optional(),
  notes: z.string().trim().optional(),
});
export type BuildRequest = z.infer<typeof buildRequestSchema>;

const subclassSection = z.object({
  name: trimmed,
  super: trimmed,
  classAbility: trimmed,
  movement: trimmed,
  melee: trimmed,
  grenade: trimmed,
  aspects: z.array(trimmed).min(1).max(3),
  fragments: z.array(trimmed).min(1).max(8),
  rationale: trimmed,
});

const statTargetSection = z.object({
  stat: z.enum(["Health", "Melee", "Grenade", "Super", "Class", "Weapons"]),
  target: z.number().int().min(0).max(200),
  rationale: trimmed,
});

const exoticArmorSection = z.object({
  name: trimmed,
  rationale: trimmed,
  alternatives: z.array(z.object({ name: trimmed, rationale: trimmed })).max(2),
});

const weaponPerkPick = z.object({
  name: trimmed,
  /** Why this perk, or what to use instead if it doesn't drop. */
  rationale: z.string().trim().optional(),
});

const weaponSection = z.object({
  slot: z.enum(["Kinetic", "Energy", "Power"]),
  name: trimmed,
  isExotic: z.boolean(),
  perks: z.array(weaponPerkPick).max(5),
  rationale: trimmed,
});

const armorModsSection = z.object({
  helmet: z.array(trimmed).max(3),
  arms: z.array(trimmed).max(3),
  chest: z.array(trimmed).max(3),
  legs: z.array(trimmed).max(3),
  classItem: z.array(trimmed).max(3),
  rationale: trimmed,
});

const armorArchetypeSection = z.object({
  /** Armor 3.0 archetype to farm, e.g. "Gunner". */
  archetype: trimmed,
  /** Optional set bonus worth chasing, e.g. "Shattered Throne". */
  setBonus: z.string().trim().optional(),
  rationale: trimmed,
});

/**
 * Artifacts 2.0 section. Omitted (null) for Trials/Competitive builds, where
 * artifacts are disabled by rule.
 */
const artifactSection = z.object({
  name: trimmed.describe('One of the seven permanent artifacts, e.g. "Hunters Journal"'),
  perks: z.array(weaponPerkPick).min(1).max(12),
  rationale: trimmed,
});

export const generatedBuildSchema = z.object({
  name: trimmed.describe("Short evocative build name"),
  summary: trimmed.describe("2-3 sentence overview of the build's engine"),
  subclass: subclassSection,
  statTargets: z.array(statTargetSection).length(6),
  exoticArmor: exoticArmorSection,
  armor: armorArchetypeSection,
  weapons: z.array(weaponSection).length(3),
  mods: armorModsSection,
  artifact: artifactSection.nullable(),
  gameplayLoop: trimmed.describe("Step-by-step rotation in 3-6 sentences"),
  acquisitionNotes: trimmed.describe("Where to farm the key pieces"),
});
export type GeneratedBuild = z.infer<typeof generatedBuildSchema>;

/** JSON Schema for Phase B structured output. */
export function buildJsonSchema(): Record<string, unknown> {
  return z.toJSONSchema(generatedBuildSchema) as Record<string, unknown>;
}
