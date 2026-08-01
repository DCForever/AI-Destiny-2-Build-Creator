/**
 * Prompts for partial LLM refine with locked slots.
 */

import type { GeneratedBuild } from "./buildSchema";
import { composeFinalizeSystemPrompt, renderSandboxDigest, ROLE } from "./prompts";

export interface RefineRequest {
  lockedSections: string[];
  changeRequest: string;
  priorBuild: GeneratedBuild;
  activity: string;
  className: "Titan" | "Hunter" | "Warlock";
}

function renderLockedSections(locked: string[]): string {
  if (locked.length === 0) return "No sections locked — you may change any part of the build.";
  return `LOCKED (do not change item names, slots, or perk picks): ${locked.join(", ")}.`;
}

export function composeRefineResearchPrompt(metaPack: string, req: RefineRequest): string {
  return [
    ROLE,
    renderSandboxDigest(),
    "## Curated meta notes",
    metaPack,
    `## Partial refine instructions
The user wants to adjust an existing build. ${renderLockedSections(req.lockedSections)}
Change request: ${req.changeRequest}
Activity: ${req.activity}
Use tools to verify any new picks. Be economical: at most 8 tool calls.`,
  ].join("\n\n");
}

export function composeRefineFinalizePrompt(metaPack: string, req: RefineRequest): string {
  return [
    composeFinalizeSystemPrompt(metaPack),
    `## Refine composition
Output the full build JSON. ${renderLockedSections(req.lockedSections)}
Apply the change request while preserving locked sections exactly.`,
  ].join("\n\n");
}

export function composeRefineUserPrompt(req: RefineRequest): string {
  return `Refine this build for ${req.activity}:

Change request: ${req.changeRequest}

Current build:
${JSON.stringify(req.priorBuild, null, 2)}`;
}

export const REFINE_COMPOSE_PROMPT =
  "Output the refined build as a single JSON object matching the required schema. No prose.";
