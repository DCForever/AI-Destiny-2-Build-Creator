/**
 * System prompts for the loadout analyzer pipeline. Reuses the build-crafter
 * role and 9.7.0 sandbox digest so the analyzer and generator never disagree
 * on game rules.
 */

import type { AnalyzeRequest } from "./analyzeSchema";
import { renderSandboxDigest, ROLE } from "./prompts";

const ANALYZE_FOCUS = `## Analysis focus
You are reviewing a player's EXISTING loadout, not building from scratch. Judge it against the 9.7.0 sandbox for the stated activity:
- Champion coverage: do the three weapons + subclass verbs cover Barrier, Overload, and Unstoppable where the activity demands it?
- Synergy: do the exotic, aspects, fragments, and weapon perks feed one engine, or fight each other?
- Stats: are the six Armor 3.0 stats allocated sensibly, including enhanced benefits past 100?
- Artifact: is the artifact pick legal for the activity and are its perks aligned with the build?
Keep what works. Prefer minimal, high-impact swaps over wholesale rebuilds; the optimized build should be recognizably the player's loadout, improved.`;

/** Phase A: research loop with tools enabled, no format constraint. */
export function composeAnalyzeResearchSystemPrompt(metaPack: string): string {
  return [
    ROLE,
    renderSandboxDigest(),
    "## Curated meta notes (verified against 9.7.0 sources; trust these over memory)",
    metaPack,
    ANALYZE_FOCUS,
    `## Research phase instructions
You have tools: search_items, get_weapon_perks, get_exotic_details, get_artifact_perks, web_search. Before writing the analysis:
1. Verify the loadout's exotic armor with get_exotic_details.
2. Verify perk pools with get_weapon_perks for any weapon whose perks you question or replace.
3. Check the artifact grid with get_artifact_perks if you change artifact perks.
Be economical: at most 8 tool calls total. When done, reply with a short plain-text summary of your verified findings and stop calling tools.`,
  ].join("\n\n");
}

/** Phase B: composition with schema-constrained decoding (no tools). */
export function composeAnalyzeFinalizeSystemPrompt(metaPack: string): string {
  return [
    ROLE,
    renderSandboxDigest(),
    "## Curated meta notes (verified against 9.7.0 sources; trust these over memory)",
    metaPack,
    ANALYZE_FOCUS,
    `## Composition instructions
Using the research findings in the conversation, output the analysis as JSON matching the provided schema. Every name in swaps and optimizedBuild must be an exact in-game display name. The optimizedBuild must be complete (all six stat targets, three weapons, champion coverage for endgame PvE) and must keep the player's working pieces where they hold up. Set optimizedBuild.artifact to null only for Trials of Osiris or Competitive Crucible.`,
  ].join("\n\n");
}

export function composeAnalyzeUserPrompt(request: AnalyzeRequest): string {
  const lines = [
    `Class: ${request.className}`,
    `Activity: ${request.activity}`,
  ];
  if (request.playstyle) lines.push(`Playstyle: ${request.playstyle}`);
  if (request.notes) lines.push(`Notes: ${request.notes}`);
  return [
    "Analyze this loadout and propose an optimized version:",
    lines.join("\n"),
    "## Current loadout",
    request.loadoutText,
  ].join("\n\n");
}
