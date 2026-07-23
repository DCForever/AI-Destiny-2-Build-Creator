import { z } from "zod";

import { conceptTagIdsSchema } from "@/data/conceptTags";
import { armorSetOptimizerConstraintsSchema } from "@/lib/optimizer/constraintsSchema";
import {
  parseOptimizerConstraints,
  serializeOptimizerConstraints,
  type ArmorSetOptimizerConstraints,
} from "@/lib/optimizer/types";

export const SET_TYPES = ["weapon", "armor", "mod", "pair", "fashion"] as const;
export type SetType = (typeof SET_TYPES)[number];

export const WEAPON_SLOTS = ["primary", "special", "heavy"] as const;
export const ARMOR_SLOTS = ["helmet", "arms", "chest", "legs", "class_item"] as const;
export const PAIR_SLOTS = ["exotic_weapon", "exotic_armor"] as const;
export const FASHION_SLOTS = [
  "shader_ornament",
  "ghost",
  "sparrow",
  "ship",
  "emblem",
  "finisher",
] as const;

export const EQUIPMENT_SLOTS = [
  ...WEAPON_SLOTS,
  ...ARMOR_SLOTS,
  ...PAIR_SLOTS,
] as const;

export type EquipmentSlot = (typeof EQUIPMENT_SLOTS)[number];
export type FashionSlot = (typeof FASHION_SLOTS)[number];

export type ArmorSetSlot = (typeof ARMOR_SLOTS)[number];

export const SLOTS_BY_SET_TYPE: Record<SetType, readonly string[] | "mods_only"> = {
  weapon: WEAPON_SLOTS,
  armor: ARMOR_SLOTS,
  /** Dynamic keys: `{armorSlot}:{itemHash}` plus legacy `mod` / `mod:<hash>`. */
  mod: "mods_only",
  pair: PAIR_SLOTS,
  fashion: FASHION_SLOTS,
};

export function isArmorSetSlot(slot: string): slot is ArmorSetSlot {
  return (ARMOR_SLOTS as readonly string[]).includes(slot);
}

/**
 * Storage key for a mod plug on a piece so multiple mods coexist per piece.
 * Example: `helmet:123456789`
 */
export function modSetSlotKey(armorSlot: ArmorSetSlot | string, itemHash: number): string {
  return `${armorSlot}:${itemHash}`;
}

/** Parse `helmet:123` style keys. */
export function parseModSetSlot(
  slot: string,
): { armorSlot: ArmorSetSlot; itemHash: number } | null {
  const colon = slot.indexOf(":");
  if (colon <= 0) return null;
  const armorSlot = slot.slice(0, colon);
  const hashPart = slot.slice(colon + 1);
  if (!isArmorSetSlot(armorSlot)) return null;
  const itemHash = Number(hashPart);
  if (!Number.isInteger(itemHash) || itemHash <= 0) return null;
  return { armorSlot, itemHash };
}

/** Armor piece group for a mod-set item slot (new or legacy). */
export function modSetArmorSlotOf(slot: string): ArmorSetSlot | null {
  const parsed = parseModSetSlot(slot);
  if (parsed) return parsed.armorSlot;
  if (isArmorSetSlot(slot)) return slot;
  return null;
}

/**
 * Mod set item slots:
 * - Preferred: `helmet:hash`, `arms:hash`, …
 * - Legacy free-list: `mod`, `mod:<hash>`
 * - Bare armor slot names accepted for fill entry (normalized before write)
 */
export function isModSetSlot(slot: string): boolean {
  if (slot === "mod" || slot.startsWith("mod:")) return true;
  if (isArmorSetSlot(slot)) return true;
  return parseModSetSlot(slot) != null;
}

export function isLegacyModSetSlot(slot: string): boolean {
  return slot === "mod" || slot.startsWith("mod:");
}

export function isSlotValidForSetType(type: SetType, slot: string): boolean {
  const allowed = SLOTS_BY_SET_TYPE[type];
  if (allowed === "mods_only") return isModSetSlot(slot);
  return (allowed as readonly string[]).includes(slot);
}

/**
 * @deprecated Prefer {@link modSetSlotKey}. Legacy free-list uniqueness key.
 */
export function modSlotForHash(itemHash: number): string {
  return `mod:${itemHash}`;
}

export function isFashionSlot(slot: string): slot is FashionSlot {
  return (FASHION_SLOTS as readonly string[]).includes(slot);
}

export const setTypeSchema = z.enum(SET_TYPES);

export const createSetSchema = z.object({
  name: z.string().trim().min(1).max(120),
  type: setTypeSchema,
  tagIds: conceptTagIdsSchema.default([]),
  optimizerConstraints: armorSetOptimizerConstraintsSchema.nullable().optional(),
  linkedModSetId: z.string().min(1).nullable().optional(),
});

export const updateSetSchema = createSetSchema.partial();

export const setItemInputSchema = z.object({
  slot: z.string().min(1),
  itemHash: z.number().int().positive(),
  itemName: z.string().trim().min(1).optional(),
  instanceId: z.string().min(1).optional(),
  selectedPerks: z.array(z.number().int()).optional(),
  masterworkHash: z.number().int().nullable().optional(),
  modHashes: z.array(z.number().int()).optional(),
  confirmReplace: z.boolean().optional(),
});

export type CreateSetInput = z.infer<typeof createSetSchema>;
export type UpdateSetInput = z.infer<typeof updateSetSchema>;
export type SetItemInput = z.infer<typeof setItemInputSchema>;
export type { ArmorSetOptimizerConstraints };
export { parseOptimizerConstraints, serializeOptimizerConstraints };
