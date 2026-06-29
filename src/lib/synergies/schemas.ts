import { z } from "zod";

export const SYNERGY_TYPES = [
  "melee",
  "verb",
  "grenade",
  "primary_weapon",
  "special_weapon",
  "heavy_weapon",
  "kinetic_weapon",
  "super",
  "damage",
  "healing",
] as const;

export type SynergyType = (typeof SYNERGY_TYPES)[number];

export const synergyLinkKindSchema = z.enum([
  "weapon",
  "weapon_perk",
  "origin_trait",
  "armor_set_bonus",
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
  name: z.string().trim().min(1).max(120),
  type: z.enum(SYNERGY_TYPES),
  description: z.string().max(2000).optional(),
  links: z.array(synergyLinkSchema).default([]),
});

export type SynergyLinkInput = z.infer<typeof synergyLinkSchema>;
export type CreateSynergyInput = z.infer<typeof createSynergySchema>;

export const updateSynergySchema = createSynergySchema.partial();
export type UpdateSynergyInput = z.infer<typeof updateSynergySchema>;
