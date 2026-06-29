import { z } from "zod";

const armorSlotSchema = z.enum(["Helmet", "Gauntlets", "Chest", "Legs", "ClassItem"]);
const weaponSlotSchema = z.enum(["Kinetic", "Energy", "Power"]);
const filterModeSchema = z.enum(["exact", "slot"]);

export const armorExoticFilterSchema = z.discriminatedUnion("mode", [
  z.object({
    mode: z.literal("exact"),
    hash: z.number().int().positive().optional(),
    name: z.string().trim().min(1).optional(),
  }).refine((v) => v.hash !== undefined || v.name !== undefined, {
    message: "exact armor filter requires hash or name",
  }),
  z.object({
    mode: z.literal("slot"),
    slot: armorSlotSchema,
  }),
]);

export const weaponExoticFilterSchema = z.discriminatedUnion("mode", [
  z.object({
    mode: z.literal("exact"),
    hash: z.number().int().positive().optional(),
    name: z.string().trim().min(1).optional(),
  }).refine((v) => v.hash !== undefined || v.name !== undefined, {
    message: "exact weapon filter requires hash or name",
  }),
  z.object({
    mode: z.literal("slot"),
    slot: weaponSlotSchema,
  }),
]);

export const exoticFilterCriteriaSchema = z.object({
  armor: armorExoticFilterSchema.nullable().optional(),
  weapon: weaponExoticFilterSchema.nullable().optional(),
});

export { armorSlotSchema, weaponSlotSchema, filterModeSchema };
