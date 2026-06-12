/**
 * Renders the curated meta pack into prompt text, filtered to the requested
 * class so the local model's context stays small. Artifact guidance is
 * omitted for activities where artifacts are disabled.
 */

import { isArtifactAllowed } from "@/data/rules/activityRules";

import { ARTIFACT_GUIDANCE } from "./artifacts";
import { EXOTIC_ARMOR_NOTES, HIGHLIGHTED_BUILDS, STAT_GUIDANCE } from "./classNotes";
import { EXOTIC_WEAPON_NOTES, SET_BONUS_COMBOS, SET_BONUS_GUIDANCE } from "./gearNotes";
import type { MetaClassName } from "./types";

function renderBuilds(className: MetaClassName): string {
  const builds = HIGHLIGHTED_BUILDS.filter((b) => b.className === className);
  const lines = builds.map(
    (b) => `- ${b.title} (${b.subclass}): ${b.summary}`,
  );
  return `Proven ${className} builds on 9.7.0:\n${lines.join("\n")}`;
}

function renderExoticArmor(className: MetaClassName): string {
  const notes = EXOTIC_ARMOR_NOTES.filter((n) => n.className === className);
  const lines = notes.map((n) => `- ${n.name}: ${n.note}`);
  return `${className} exotic armor 9.7.0 notes:\n${lines.join("\n")}`;
}

function renderExoticWeapons(): string {
  const lines = EXOTIC_WEAPON_NOTES.map((n) => `- ${n.name}: ${n.note}`);
  return `Exotic weapon 9.7.0 notes:\n${lines.join("\n")}`;
}

function renderSetBonuses(): string {
  const sets = SET_BONUS_GUIDANCE.map(
    (s) =>
      `- ${s.setName} (${s.source}): 2pc ${s.twoPiece}. 4pc ${s.fourPiece}. ${s.assessment}.`,
  );
  const combos = SET_BONUS_COMBOS.map((c) => `- ${c.pieces}: ${c.useCase}`);
  return `Armor set bonuses:\n${sets.join("\n")}\nStrong 2+2 combos:\n${combos.join("\n")}`;
}

function renderArtifacts(): string {
  const lines = ARTIFACT_GUIDANCE.map((a) => {
    const notes = a.rebalanceNotes.map((n) => `${n}`).join("; ");
    return `- ${a.name}: ${a.identity} Best for: ${a.bestFor} 9.7.0 changes: ${notes}.`;
  });
  return `The seven permanent artifacts:\n${lines.join("\n")}`;
}

function renderStatGuidance(): string {
  const lines = STAT_GUIDANCE.map((s) => `- ${s.context}: ${s.guidance}`);
  return `Stat target guidance:\n${lines.join("\n")}`;
}

export function renderMetaPack(
  className: MetaClassName,
  activity: string,
): string {
  const sections = [
    renderBuilds(className),
    renderExoticArmor(className),
    renderExoticWeapons(),
    renderSetBonuses(),
    renderStatGuidance(),
  ];
  if (isArtifactAllowed(activity)) {
    sections.push(renderArtifacts());
  } else {
    sections.push(
      "Artifacts are disabled in this activity (Trials/Competitive): the build's artifact section must be null.",
    );
  }
  return sections.join("\n\n");
}
