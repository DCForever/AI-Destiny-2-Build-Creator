/**
 * System prompts for the two-phase generation pipeline, adapted from the
 * original destiny-2-build-helper skill (src/data/meta/skill-source.md) and
 * updated to the 9.7.0 "Monument of Triumph" baseline. The sandbox digest is
 * rendered from the rule tables in src/data/rules so prompt and validator
 * never disagree.
 */

import {
  ARMOR_ARCHETYPES,
} from "@/data/rules/armorArchetypes";
import {
  BASE_FRAME_COUNTERS,
  FRAME_OVERRIDES,
  SUBCLASS_VERB_COUNTERS,
} from "@/data/rules/championCounters";
import {
  ABILITY_ECONOMY_NOTES,
  CLASS_STAT_SCALING_ABILITIES,
  STAT_BENEFITS,
} from "@/data/rules/statBenefits";

import type { BuildRequest } from "./buildSchema";

export const ROLE = `You are an expert Destiny 2 build crafter working on the final, frozen sandbox: Update 9.7.0 "Monument of Triumph" (June 9, 2026). You produce one complete, synergistic build per request, with clear rationale for every major choice (synergies, ability uptime, survivability, damage profile, activity fit).

Critical rules:
- Use exact in-game display names for every item, perk, aspect, fragment, mod, and artifact. Never invent names and never output numeric hashes; the app resolves names against the game database and flags anything it cannot verify.
- Recommendations must reflect the 9.7.0 sandbox digest below, which supersedes anything you remember from before June 2026 (the old "100 Resilience" guidance is obsolete).`;

function renderChampionDigest(): string {
  const base = Object.entries(BASE_FRAME_COUNTERS)
    .map(([frame, counter]) => `${frame} = ${counter}`)
    .join(", ");
  const overrides = FRAME_OVERRIDES.map(
    (rule) => `${rule.frame}${rule.weaponType ? ` (${rule.weaponType})` : ""} = ${rule.counters}`,
  ).join("; ");
  const verbs = Object.entries(SUBCLASS_VERB_COUNTERS)
    .map(([verb, counter]) => `${verb} = ${counter}`)
    .join(", ");
  return `Anti-Champion 2.0: champion mods are gone. Every weapon stuns champions intrinsically by frame, activated simply by hitting the target.
- Base frame families: ${base}.
- Frame overrides: ${overrides}.
- Subclass verbs: ${verbs}. Stasis shatter stuns Unstoppable again (including the new Shatter Grenade).
- Radiant and Volatile Rounds NO LONGER stun Barrier champions; they grant +10% weapon damage vs champions instead. Barrier coverage must come from a weapon frame.
- A complete endgame PvE build covers Barrier, Overload, and Unstoppable across its three weapons and subclass verbs.`;
}

function renderStatDigest(): string {
  const statLines = Object.values(STAT_BENEFITS).map((definition) => {
    const enhanced = definition.enhancedScaling
      .map((benefit) => benefit.template.replace("{v}", String(benefit.max)))
      .join("; ");
    return `- ${definition.stat} past 100 (max at 200): ${enhanced || "see notes"}`;
  });
  return `Armor 3.0 stats (Health, Melee, Grenade, Super, Class, Weapons) run 0-200 and scale per point. Every stat grants an enhanced benefit from 101-200:
${statLines.join("\n")}
Damaging class abilities that additionally scale with Class above 100: ${CLASS_STAT_SCALING_ABILITIES.join(", ")}.
Ability economy (9.7.0): ${ABILITY_ECONOMY_NOTES.join("; ")}. Net effect: weapon damage carries DPS phases; pure ability-spam builds are weaker than pre-9.7.0 guides claim.`;
}

function renderArmorDigest(): string {
  const archetypes = ARMOR_ARCHETYPES.map(
    (archetype) => `${archetype.name} (${archetype.primary}/${archetype.secondary})`,
  ).join(", ");
  return `Armor recommendations use Armor 3.0 archetypes plus an optional set bonus, never legacy "high-stat piece" language. The 12 archetypes (primary/secondary stat): ${archetypes}. Each piece also rolls a random tertiary stat. All Armor 3.0 exotics are Tier 5 with all tuning mods. Raid mod slots exist only on Armor 2.0 raid gear (focusable at Hawthorne for 10 Spoils).`;
}

const ARTIFACT_DIGEST = `Artifacts 2.0: seven permanent artifacts (Queensfoil Censer, Slayer Baron Apothecary Satchel, Hunters Journal, Tablet of Ruin, Implement of Curiosity, Encrypted Data Disc, NPA Repulsion Regulator), each a curated perk grid. Champion mods were removed from all artifacts. Artifact and perk picks save to in-game loadouts. Artifacts are DISABLED in Trials of Osiris and Competitive Crucible: for those activities the build's artifact section must be null. Use the get_artifact_perks tool to see real perk grids before picking.`;

export function renderSandboxDigest(): string {
  return [
    "## 9.7.0 sandbox digest",
    renderChampionDigest(),
    renderStatDigest(),
    renderArmorDigest(),
    ARTIFACT_DIGEST,
  ].join("\n\n");
}

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
    if (prefs.include?.length) lines.push(`Preferred weapon types: ${prefs.include.join(", ")}`);
    if (prefs.exclude?.length) lines.push(`Excluded weapon types: ${prefs.exclude.join(", ")}`);
    if (prefs.prioritizeOwned) lines.push("Prioritize weapons the user already owns when possible.");
  }
  return lines.join("\n");
}

export function composeUserPrompt(request: BuildRequest, inventorySummary?: string | null): string {
  const sections = [`Create a build for the following request:\n${renderRequest(request)}`];
  if (inventorySummary) {
    sections.push(
      "## User inventory summary (prefer owned weapons when prioritizeOwned is set)\n"
      + inventorySummary,
    );
  }
  return sections.join("\n\n");
}

export function composeResearchSystemPrompt(metaPack: string): string {
  return [
    ROLE,
    renderSandboxDigest(),
    "## Curated meta notes (verified against 9.7.0 sources; trust these over memory)",
    metaPack,
    `## Research phase instructions
You have tools: search_items, get_weapon_perks, search_weapon_perks, find_weapons_with_perk, get_exotic_details, get_artifact_perks, web_search. Before composing the build:
1. Verify your exotic armor pick and its 9.7.0 behavior with get_exotic_details.
2. For EACH weapon slot (Kinetic, Energy, Power):
   a. If exploring perk synergies → search_weapon_perks(query) to see which columns each perk rolls in.
   b. If you need a weapon with a specific perk → find_weapons_with_perk(perkName, slot=<slot>); use ownedOnly=true when the user has synced inventory and prioritizeOwned is set.
   c. If exploring options → search_items(query, category=weapons, slot=<slot>).
   d. Before finalizing perks → get_weapon_perks(weaponName); pick perks only from columns returned by the tools.
3. Never assign a weapon to a slot unless the tool result shows that exact slot.
4. Never recommend a perk in a column where that perk cannot roll on that weapon.
5. Check the chosen artifact's actual perk grid with get_artifact_perks.
6. If unsure about the current meta for the activity, use web_search once or twice; if search is unavailable, rely on the curated meta notes above.
Be economical: at most 12 tool calls total. When your picks are verified, reply with a short plain-text summary of your verified choices and stop calling tools.`,
  ].join("\n\n");
}

/**
 * Phase B: composition with schema-constrained decoding (no tools).
 */
export function composeFinalizeSystemPrompt(metaPack: string): string {
  return [
    ROLE,
    renderSandboxDigest(),
    "## Curated meta notes (verified against 9.7.0 sources; trust these over memory)",
    metaPack,
    `## Composition instructions
Using the research findings in the conversation, output the final build as JSON matching the provided schema. Every name must be an exact in-game display name you verified during research or found in the meta notes. Include all six stat targets with rationale that cites the enhanced benefit when a target exceeds 100. Cover all three champion types for endgame PvE activities. Set "artifact" to null only for Trials of Osiris or Competitive Crucible builds.`,
  ].join("\n\n");
}
