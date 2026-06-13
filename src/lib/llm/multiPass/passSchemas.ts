/**
 * Partial zod schemas for each multi-pass specialist. Each pass outputs a
 * focused slice of the full GeneratedBuild; mergePasses assembles them.
 */

import { z } from "zod";

const trimmed = z.string().trim().min(1);

const weaponPerkPick = z.object({
  name: trimmed,
  rationale: z.string().trim().optional(),
});

// --- Pass 1: Abilities (subclass + stat targets) ---

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

export const abilitiesPassSchema = z.object({
  name: trimmed.describe("Short evocative build name"),
  subclass: subclassSection,
  statTargets: z.array(statTargetSection).length(6),
});
export type AbilitiesPassOutput = z.infer<typeof abilitiesPassSchema>;

// --- Pass 2: Weapons ---

const weaponSection = z.object({
  slot: z.enum(["Kinetic", "Energy", "Power"]),
  name: trimmed,
  isExotic: z.boolean(),
  perks: z.array(weaponPerkPick).max(5),
  rationale: trimmed,
});

export const weaponsPassSchema = z.object({
  weapons: z.array(weaponSection).length(3),
});
export type WeaponsPassOutput = z.infer<typeof weaponsPassSchema>;

// --- Pass 3: Armor (exotic, archetype, mods) ---

const exoticArmorSection = z.object({
  name: trimmed,
  rationale: trimmed,
  alternatives: z.array(z.object({ name: trimmed, rationale: trimmed })).max(2),
});

const armorArchetypeSection = z.object({
  archetype: trimmed,
  setBonus: z.string().trim().optional(),
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

export const armorPassSchema = z.object({
  exoticArmor: exoticArmorSection,
  armor: armorArchetypeSection,
  mods: armorModsSection,
});
export type ArmorPassOutput = z.infer<typeof armorPassSchema>;

// --- Pass 4: Artifact ---

const artifactSection = z.object({
  name: trimmed,
  perks: z.array(weaponPerkPick).min(1).max(12),
  rationale: trimmed,
});

export const artifactPassSchema = z.object({
  artifact: artifactSection.nullable(),
});
export type ArtifactPassOutput = z.infer<typeof artifactPassSchema>;

// --- Pass 5: Synthesis (narrative + rationale only) ---

const rationalePatch = z.object({
  rationale: trimmed,
});

export const synthesisPassSchema = z.object({
  name: trimmed.optional(),
  summary: trimmed,
  gameplayLoop: trimmed,
  acquisitionNotes: trimmed,
  subclass: rationalePatch.optional(),
  exoticArmor: rationalePatch.optional(),
  armor: rationalePatch.optional(),
  mods: rationalePatch.optional(),
  artifact: rationalePatch.nullable().optional(),
  weapons: z.array(rationalePatch).length(3).optional(),
  statTargets: z.array(rationalePatch).length(6).optional(),
});
export type SynthesisPassOutput = z.infer<typeof synthesisPassSchema>;

export function abilitiesPassJsonSchema(): Record<string, unknown> {
  return z.toJSONSchema(abilitiesPassSchema) as Record<string, unknown>;
}

export function weaponsPassJsonSchema(): Record<string, unknown> {
  return z.toJSONSchema(weaponsPassSchema) as Record<string, unknown>;
}

export function armorPassJsonSchema(): Record<string, unknown> {
  return z.toJSONSchema(armorPassSchema) as Record<string, unknown>;
}

export function artifactPassJsonSchema(): Record<string, unknown> {
  return z.toJSONSchema(artifactPassSchema) as Record<string, unknown>;
}

export function synthesisPassJsonSchema(): Record<string, unknown> {
  return z.toJSONSchema(synthesisPassSchema) as Record<string, unknown>;
}
