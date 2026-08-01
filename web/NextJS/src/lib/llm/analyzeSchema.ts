/**
 * Contract for the loadout analyzer. The model receives a pasted (or
 * Bungie-imported) loadout description and returns an assessment plus an
 * optimized build reusing the generator's build schema, so the resolved
 * sheet, validation badges, and DIM exports all work unchanged.
 */

import { z } from "zod";

import { generatedBuildSchema } from "./buildSchema";

const trimmed = z.string().trim().min(1);

export const analyzeRequestSchema = z.object({
  className: z.enum(["Titan", "Hunter", "Warlock"]),
  activity: trimmed.describe('Target activity, e.g. "Grandmaster Nightfall"'),
  playstyle: z.string().trim().optional(),
  loadoutText: trimmed
    .max(8000)
    .describe("The current loadout: subclass, weapons, exotic, mods, stats"),
  notes: z.string().trim().optional(),
});
export type AnalyzeRequest = z.infer<typeof analyzeRequestSchema>;

const swapSection = z.object({
  replace: trimmed.describe("Exact name of the item/perk/fragment to swap out"),
  with: trimmed.describe("Exact name of the replacement"),
  rationale: trimmed,
});

export const loadoutAnalysisSchema = z.object({
  assessment: trimmed.describe(
    "3-5 sentence verdict on the loadout for the target activity",
  ),
  strengths: z.array(trimmed).min(1).max(5),
  gaps: z
    .array(trimmed)
    .max(5)
    .describe("Concrete problems: champion holes, anti-synergies, dead stats"),
  swaps: z
    .array(swapSection)
    .max(6)
    .describe("Highest-impact changes, ordered by priority"),
  optimizedBuild: generatedBuildSchema,
});
export type LoadoutAnalysis = z.infer<typeof loadoutAnalysisSchema>;

/** JSON Schema for Phase B structured output (analyzer). */
export function analysisJsonSchema(): Record<string, unknown> {
  return z.toJSONSchema(loadoutAnalysisSchema) as Record<string, unknown>;
}
