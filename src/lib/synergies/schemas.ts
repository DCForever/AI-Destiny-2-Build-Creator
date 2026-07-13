import { z } from "zod";

/** Legacy types remain readable from DB; not creatable via API. */
export const LEGACY_SYNERGY_TYPES = ["kinetic_weapon", "damage"] as const;

export const CREATABLE_SYNERGY_TYPES = [
  "melee",
  "verb",
  "grenade",
  "super",
  "element",
  "primary_weapon",
  "special_weapon",
  "heavy_weapon",
  "dps",
  "healing",
  "solo",
  "damage_resist",
  "general_weapon",
  "weapon_archetype",
  "team",
] as const;

export type CreatableSynergyType = (typeof CREATABLE_SYNERGY_TYPES)[number];

export const SYNERGY_TYPES = [...CREATABLE_SYNERGY_TYPES, ...LEGACY_SYNERGY_TYPES] as const;

export type SynergyType = (typeof SYNERGY_TYPES)[number];

export const synergyLinkKindSchema = z.enum([
  "weapon",
  "weapon_perk",
  "origin_trait",
  "armor_set_bonus",
  "exotic_armor",
  "artifact_perk",
]);

export const synergyLinkSchema = z.object({
  kind: synergyLinkKindSchema,
  displayName: z.string().trim().min(1),
  itemHash: z.number().int().optional(),
  perkHash: z.number().int().optional(),
  parentItemHash: z.number().int().optional(),
  originTraitName: z.string().optional(),
  originTraitHash: z.number().int().optional(),
  armorSetName: z.string().optional(),
  bonusPieces: z.union([z.literal(2), z.literal(4)]).optional(),
  bonusName: z.string().optional(),
  armorSetHash: z.number().int().optional(),
});

export const createSynergySchema = z.object({
  name: z.string().trim().min(1).max(120).optional(),
  type: z.enum(CREATABLE_SYNERGY_TYPES),
  subType: z.string().trim().min(1).nullable().optional(),
  description: z.string().max(2000).optional(),
  links: z.array(synergyLinkSchema).default([]),
});

export type SynergyLinkInput = z.infer<typeof synergyLinkSchema>;
export type CreateSynergyInput = z.infer<typeof createSynergySchema>;

export const updateSynergySchema = createSynergySchema.partial();
export type UpdateSynergyInput = z.infer<typeof updateSynergySchema>;

/** Merge multiple library rows into one survivor (same type + subType). */
export const mergeSynergiesSchema = z.object({
  /** Row that keeps its id; receives unioned links. */
  survivorId: z.string().min(1),
  /** Other rows to absorb and delete (must not include survivor). */
  sourceIds: z.array(z.string().min(1)).min(1),
});
export type MergeSynergiesInput = z.infer<typeof mergeSynergiesSchema>;
