import { z } from "zod";

import { conceptTagIdsSchema } from "@/data/conceptTags";

export const SET_TYPES = ["weapon", "armor", "mod", "pair", "fashion"] as const;
export type SetType = (typeof SET_TYPES)[number];

export const WEAPON_SLOTS = ["primary", "special", "heavy"] as const;
export const ARMOR_SLOTS = ["helmet", "arms", "chest", "legs", "class_item"] as const;
export const PAIR_SLOTS = ["exotic_weapon", "exotic_armor"] as const;

export const EQUIPMENT_SLOTS = [
  ...WEAPON_SLOTS,
  ...ARMOR_SLOTS,
  ...PAIR_SLOTS,
] as const;

export type EquipmentSlot = (typeof EQUIPMENT_SLOTS)[number];

export const SLOTS_BY_SET_TYPE: Record<
  SetType,
  readonly EquipmentSlot[] | "mods_only" | "cosmetic"
> = {
  weapon: WEAPON_SLOTS,
  armor: ARMOR_SLOTS,
  mod: "mods_only",
  pair: PAIR_SLOTS,
  fashion: "cosmetic",
};

export function isSlotValidForSetType(type: SetType, slot: string): slot is EquipmentSlot {
  const allowed = SLOTS_BY_SET_TYPE[type];
  if (allowed === "mods_only" || allowed === "cosmetic") return false;
  return (allowed as readonly string[]).includes(slot);
}

export const setTypeSchema = z.enum(SET_TYPES);

export const createSetSchema = z.object({
  name: z.string().trim().min(1).max(120),
  type: setTypeSchema,
  tagIds: conceptTagIdsSchema.default([]),
});

export const updateSetSchema = createSetSchema.partial();

export const setItemInputSchema = z.object({
  slot: z.string().min(1),
  itemHash: z.number().int().positive(),
  itemName: z.string().trim().min(1).optional(),
  selectedPerks: z.array(z.number().int()).optional(),
  masterworkHash: z.number().int().nullable().optional(),
  modHashes: z.array(z.number().int()).optional(),
  confirmReplace: z.boolean().optional(),
});

export type CreateSetInput = z.infer<typeof createSetSchema>;
export type UpdateSetInput = z.infer<typeof updateSetSchema>;
export type SetItemInput = z.infer<typeof setItemInputSchema>;
