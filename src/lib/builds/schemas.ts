import { z } from "zod";

import { conceptTagIdsSchema } from "@/data/conceptTags";
import { generatedBuildSchema } from "@/lib/llm/buildSchema";
import { CREATABLE_SYNERGY_TYPES } from "@/lib/synergies/schemas";

export const buildVariantSchema = z.object({
  name: z.string().trim().min(1).max(120).optional(),
  notes: z.string().trim().max(500).nullable().optional(),
  exoticWeaponHash: z.number().int().positive().nullable().optional(),
  exoticWeaponName: z.string().nullable().optional(),
  artifactHash: z.number().int().positive().nullable().optional(),
  artifactName: z.string().trim().min(1).nullable().optional(),
  artifactConfig: z.array(z.number().int().positive()).optional(),
});

export const synergyTypeDesignationSchema = z.object({
  type: z.enum(CREATABLE_SYNERGY_TYPES),
  subType: z.string().trim().min(1).nullable().optional(),
});

export const createBuildSchema = z.object({
  name: z.string().trim().max(120).optional(),
  className: z.enum(["Titan", "Hunter", "Warlock"]),
  subclass: generatedBuildSchema.shape.subclass,
  exoticArmorHash: z.number().int().positive().nullable().optional(),
  exoticArmorName: z.string().trim().min(1).nullable().optional(),
  exoticWeaponHash: z.number().int().positive().nullable().optional(),
  exoticWeaponName: z.string().trim().min(1).nullable().optional(),
  pinnedSuper: z.string().trim().min(1).nullable().optional(),
  softStatTargets: z.record(z.string(), z.number().int()).optional().nullable(),
  synergyTypes: z.array(synergyTypeDesignationSchema).min(1),
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
    synergyTypes: z.array(synergyTypeDesignationSchema).min(1).optional(),
    identityAction: z.enum(["confirm", "fork"]).optional(),
    softStatTargets: z.record(z.string(), z.number().int()).optional().nullable(),
    acceptStatNudges: z.boolean().optional(),
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
export type SynergyTypeDesignationInput = z.infer<typeof synergyTypeDesignationSchema>;
