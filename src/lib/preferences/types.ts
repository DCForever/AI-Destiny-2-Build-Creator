import { z } from "zod";

export const userPreferencesSchema = z.object({
  defaultClass: z.enum(["Titan", "Hunter", "Warlock"]).optional(),
  defaultGenerationMode: z.enum(["standard", "multi-pass"]).optional(),
  weaponTypeFilters: z
    .object({
      include: z.array(z.string()).optional(),
      exclude: z.array(z.string()).optional(),
      prioritizeOwned: z.boolean().optional(),
    })
    .optional(),
});

export type UserPreferences = z.infer<typeof userPreferencesSchema>;

export const DEFAULT_PREFERENCES: UserPreferences = {
  defaultClass: "Titan",
  defaultGenerationMode: "standard",
  weaponTypeFilters: { include: [], exclude: [], prioritizeOwned: false },
};
