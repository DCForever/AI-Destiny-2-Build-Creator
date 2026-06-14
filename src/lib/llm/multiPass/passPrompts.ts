/**
 * Domain-focused system prompts for each multi-pass specialist.
 */

import type { BuildRequest } from "../buildSchema";
import {
  composeResearchSystemPrompt,
  composeFinalizeSystemPrompt,
  renderSandboxDigest,
  ROLE,
} from "../prompts";
import type {
  AbilitiesPassOutput,
  ArmorPassOutput,
  WeaponsPassOutput,
} from "./passSchemas";

function renderRequest(request: BuildRequest): string {
  const lines = [
    `Class: ${request.className}`,
    `Subclass: ${request.subclass}`,
    `Activity: ${request.activity}`,
    `Playstyle: ${request.playstyle}`,
  ];
  if (request.preferredExotic) lines.push(`Preferred exotic: ${request.preferredExotic}`);
  if (request.preferredWeapon) lines.push(`Preferred weapon: ${request.preferredWeapon}`);
  if (request.notes) lines.push(`Notes: ${request.notes}`);
  if (request.weaponTypePreferences) {
    const prefs = request.weaponTypePreferences;
    if (prefs.include?.length) lines.push(`Include weapon types: ${prefs.include.join(", ")}`);
    if (prefs.exclude?.length) lines.push(`Exclude weapon types: ${prefs.exclude.join(", ")}`);
    if (prefs.prioritizeOwned) lines.push("Prioritize weapons the user owns when possible.");
  }
  return lines.join("\n");
}

function renderPriorContext(label: string, json: unknown): string {
  return `## Prior pass: ${label}\n\`\`\`json\n${JSON.stringify(json, null, 2)}\n\`\`\``;
}

const ABILITIES_TOOLS = `Tools available (budget 4): search_items (aspects, fragments), get_exotic_details, web_search.
Focus ONLY on subclass abilities, aspects, fragments, and stat targets. Do NOT pick weapons, armor, mods, or artifact yet.
Verify aspect and fragment names with search_items. Pick exactly six stat targets with rationale citing enhanced benefits above 100.`;

const WEAPONS_TOOLS = `Tools available (budget 6): search_items, get_weapon_perks, search_weapon_perks, find_weapons_with_perk, get_exotic_details, web_search.
Focus ONLY on the three weapon slots (Kinetic, Energy, Power). Verify each weapon's slot with tools before finalizing.
For EACH slot: search_items or find_weapons_with_perk, then get_weapon_perks to confirm perk columns.
Cover Barrier, Overload, and Unstoppable across the three weapons plus subclass verbs from the abilities pass.`;

const ARMOR_TOOLS = `Tools available (budget 4): search_items (exotic-armor, mods), get_exotic_details, web_search.
Focus ONLY on exotic armor, Armor 3.0 archetype, set bonus, and armor mod picks per slot.
Verify exotic armor with get_exotic_details. Mod names must be exact in-game display names.`;

const ARTIFACT_TOOLS = `Tools available (budget 2): get_artifact_perks, web_search.
Focus ONLY on the Artifacts 2.0 pick. Use get_artifact_perks to see the real perk grid.
Set artifact to null for Trials of Osiris or Competitive Crucible.`;

export function composeAbilitiesResearchPrompt(metaPack: string, request: BuildRequest): string {
  return [
    composeResearchSystemPrompt(metaPack),
    "## Abilities pass scope",
    ABILITIES_TOOLS,
    `Request:\n${renderRequest(request)}`,
  ].join("\n\n");
}

export function composeAbilitiesFinalizePrompt(metaPack: string): string {
  return [
    composeFinalizeSystemPrompt(metaPack),
    "## Abilities pass composition",
    "Output ONLY the abilities pass JSON: build name, subclass section, and six stat targets. No weapons, armor, mods, or artifact.",
  ].join("\n\n");
}

export function composeAbilitiesUserPrompt(request: BuildRequest): string {
  return `Design the subclass and stat targets for:\n${renderRequest(request)}`;
}

export function composeWeaponsResearchPrompt(
  metaPack: string,
  request: BuildRequest,
  abilities: AbilitiesPassOutput,
): string {
  return [
    composeResearchSystemPrompt(metaPack),
    renderPriorContext("Abilities", abilities),
    "## Weapons pass scope",
    WEAPONS_TOOLS,
    `Request:\n${renderRequest(request)}`,
  ].join("\n\n");
}

export function composeWeaponsFinalizePrompt(metaPack: string): string {
  return [
    composeFinalizeSystemPrompt(metaPack),
    "## Weapons pass composition",
    "Output ONLY the weapons pass JSON: exactly three weapons (Kinetic, Energy, Power) with perks and rationale.",
  ].join("\n\n");
}

export function composeWeaponsUserPrompt(
  request: BuildRequest,
  inventorySummary?: string | null,
): string {
  const lines = [`Pick three synergistic weapons for:\n${renderRequest(request)}`];
  if (inventorySummary) {
    lines.push(
      "## Owned inventory (prefer these when prioritizeOwned is set; use find_weapons_with_perk with ownedOnly)",
      inventorySummary,
    );
  }
  return lines.join("\n\n");
}

export function composeArmorResearchPrompt(
  metaPack: string,
  request: BuildRequest,
  abilities: AbilitiesPassOutput,
  weapons: WeaponsPassOutput,
): string {
  return [
    composeResearchSystemPrompt(metaPack),
    renderPriorContext("Abilities", abilities),
    renderPriorContext("Weapons", weapons),
    "## Armor pass scope",
    ARMOR_TOOLS,
    `Request:\n${renderRequest(request)}`,
  ].join("\n\n");
}

export function composeArmorFinalizePrompt(metaPack: string): string {
  return [
    composeFinalizeSystemPrompt(metaPack),
    "## Armor pass composition",
    "Output ONLY the armor pass JSON: exotic armor, archetype/set bonus, and mods per slot.",
  ].join("\n\n");
}

export function composeArmorUserPrompt(request: BuildRequest): string {
  return `Pick exotic armor, archetype, and mods for:\n${renderRequest(request)}`;
}

export function composeArtifactResearchPrompt(
  metaPack: string,
  request: BuildRequest,
  prior: { abilities: AbilitiesPassOutput; weapons: WeaponsPassOutput; armor: ArmorPassOutput },
): string {
  return [
    composeResearchSystemPrompt(metaPack),
    renderPriorContext("Abilities", prior.abilities),
    renderPriorContext("Weapons", prior.weapons),
    renderPriorContext("Armor", prior.armor),
    "## Artifact pass scope",
    ARTIFACT_TOOLS,
    `Request:\n${renderRequest(request)}`,
  ].join("\n\n");
}

export function composeArtifactFinalizePrompt(metaPack: string): string {
  return [
    composeFinalizeSystemPrompt(metaPack),
    "## Artifact pass composition",
    "Output ONLY the artifact pass JSON. Set artifact to null when disabled for the activity.",
  ].join("\n\n");
}

export function composeArtifactUserPrompt(request: BuildRequest): string {
  return `Pick the artifact (or null) for:\n${renderRequest(request)}`;
}

export function composeSynthesisSystemPrompt(metaPack: string): string {
  return [
    ROLE,
    renderSandboxDigest(),
    "## Curated meta notes",
    metaPack,
    `## Synthesis pass rules
You receive a mechanically merged build draft. Item names, slots, and perk picks from prior passes are IMMUTABLE.
You MAY edit: summary, gameplayLoop, acquisitionNotes, and all rationale fields.
You MAY NOT swap any item names, slots, or perk picks.
Output the synthesis pass JSON with narrative fields and updated rationales only.`,
  ].join("\n\n");
}

export function composeSynthesisUserPrompt(mergedDraftJson: string): string {
  return `Fill narrative gaps for this merged build draft. Do not change any item names or perk picks.

\`\`\`json
${mergedDraftJson}
\`\`\`

Output the synthesis pass JSON now.`;
}

export const PASS_COMPOSE_PROMPTS = {
  abilities: "Output the abilities pass JSON matching the schema. No prose.",
  weapons: "Output the weapons pass JSON matching the schema. No prose.",
  armor: "Output the armor pass JSON matching the schema. No prose.",
  artifact: "Output the artifact pass JSON matching the schema. No prose.",
  synthesis: "Output the synthesis pass JSON matching the schema. No prose.",
} as const;
