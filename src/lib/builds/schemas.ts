import { z } from "zod";

import { conceptTagIdsSchema } from "@/data/conceptTags";
import { generatedBuildSchema } from "@/lib/llm/buildSchema";

export const buildVariantSchema = z.object({
  name: z.string().trim().min(1).max(120).optional(),
  notes: z.string().trim().max(500).nullable().optional(),
  exoticWeaponHash: z.number().int().positive().nullable().optional(),
  exoticWeaponName: z.string().nullable().optional(),
});

export const createBuildSchema = z.object({
  name: z.string().trim().min(1).max(120),
  className: z.enum(["Titan", "Hunter", "Warlock"]),
  subclass: generatedBuildSchema.shape.subclass,
  exoticArmorHash: z.number().int().positive(),
  exoticArmorName: z.string().trim().min(1).optional(),
  synergyIds: z.array(z.string().uuid()).min(1),
  tagIds: conceptTagIdsSchema.optional(),
  defaultVariant: buildVariantSchema.optional(),
});

export type BuildVariantInput = z.infer<typeof buildVariantSchema>;
export type CreateBuildInput = z.infer<typeof createBuildSchema>;
