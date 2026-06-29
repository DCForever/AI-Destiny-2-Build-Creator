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
  synergyIds: z.array(z.string().min(1)).optional(),
  tagIds: conceptTagIdsSchema.optional(),
  defaultVariant: buildVariantSchema
    .extend({
      attachments: z
        .array(
          z.object({
            setId: z.string().min(1),
            mode: z.enum(["live", "snapshot"]),
          }),
        )
        .optional(),
    })
    .optional(),
});

export const updateBuildSchema = createBuildSchema
  .omit({ defaultVariant: true })
  .partial()
  .extend({
    synergyIds: z.array(z.string().min(1)).min(1).optional(),
  });

export const updateVariantSchema = buildVariantSchema.extend({
  attachments: z
    .array(
      z.object({
        setId: z.string().min(1),
        mode: z.enum(["live", "snapshot"]),
      }),
    )
    .optional(),
});

export type SetAttachmentInput = z.infer<
  typeof updateVariantSchema
>["attachments"] extends infer T
  ? T extends Array<infer U>
    ? U
    : never
  : never;

export type BuildVariantInput = z.infer<typeof buildVariantSchema>;
export type CreateBuildInput = z.infer<typeof createBuildSchema>;
export type UpdateBuildInput = z.infer<typeof updateBuildSchema>;
export type UpdateVariantInput = z.infer<typeof updateVariantSchema>;
