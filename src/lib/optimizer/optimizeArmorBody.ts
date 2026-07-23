import { z } from "zod";

import {
  armorStatNameSchema,
  setBonusCoverageGoalSchema,
  softThresholdsSchema,
} from "./types";

/** Zod contract for `POST /api/user/armor/optimize` (armor-optimize-contract.md). */
export const armorOptimizeBodySchema = z
  .object({
    buildId: z.string().min(1).optional(),
    variantId: z.string().min(1).optional(),
    armorSetId: z.string().min(1).optional(),
    classType: z.enum(["Titan", "Hunter", "Warlock"]).optional(),
    lockedExoticItemHash: z.number().int().positive().nullable().optional(),
    requireExotic: z.boolean().optional(),
    setBonusGoals: z.array(setBonusCoverageGoalSchema).optional(),
    statPriorities: z.array(armorStatNameSchema).optional(),
    statThresholds: softThresholdsSchema.optional(),
    requireThresholds: z.boolean().optional(),
    includeModEstimates: z.boolean().optional(),
    preferReuse: z.boolean().optional(),
    maxResults: z.number().int().min(1).max(50).optional(),
  })
  .refine((body) => body.buildId != null || body.classType != null, {
    message: "classType is required when buildId is omitted",
    path: ["classType"],
  });

export type ArmorOptimizeBody = z.infer<typeof armorOptimizeBodySchema>;
