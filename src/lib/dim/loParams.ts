import type { ResolvedBuildSheet, ResolvedStatTarget } from "@/lib/build/types";

export interface LoadoutOptimizerParams {
  exoticArmorName: string | null;
  statPriorities: { stat: string; target: number }[];
  modsPerSlot: { slot: string; mods: string[] }[];
  armorArchetype: string;
  setBonus: string | null;
  notes: string[];
}

function buildStatBenefitNotes(targets: ResolvedStatTarget[]): string[] {
  return targets
    .filter((t) => t.target > 100 && t.benefits.length > 0)
    .map((t) => `${t.stat} ${t.target}: ${t.benefits[0]}`);
}

function buildFarmNote(archetype: string, setBonus: string | null): string {
  let line = `Farm ${archetype} archetype armor`;
  if (setBonus) {
    line += ` with the ${setBonus} set bonus`;
  }
  return line;
}

function buildArtifactNote(sheet: ResolvedBuildSheet): string | null {
  const artifact = sheet.artifact;
  if (!artifact || !artifact.allowedInActivity) {
    return null;
  }
  const name =
    artifact.reference.resolved?.name ?? artifact.reference.requestedName;
  return `Artifact: ${name} — save perks to the loadout in-game`;
}

function buildNotes(sheet: ResolvedBuildSheet): string[] {
  const notes: string[] = [
    ...buildStatBenefitNotes(sheet.statTargets),
    buildFarmNote(sheet.build.armor.archetype, sheet.build.armor.setBonus ?? null),
  ];

  const artifactNote = buildArtifactNote(sheet);
  if (artifactNote) {
    notes.push(artifactNote);
  }

  return notes;
}

function resolveModNames(
  picks: ResolvedBuildSheet["mods"][number]["picks"],
): string[] {
  return picks
    .filter((pick) => pick.resolved !== null)
    .map((pick) => pick.resolved!.name);
}

export function buildLoParams(sheet: ResolvedBuildSheet): LoadoutOptimizerParams {
  return {
    exoticArmorName: sheet.exoticArmor.resolved?.name ?? null,
    statPriorities: sheet.statTargets.map((t) => ({
      stat: t.stat,
      target: t.target,
    })),
    modsPerSlot: sheet.mods.map((entry) => ({
      slot: entry.slot,
      mods: resolveModNames(entry.picks),
    })),
    armorArchetype: sheet.build.armor.archetype,
    setBonus: sheet.build.armor.setBonus ?? null,
    notes: buildNotes(sheet),
  };
}

function renderExoticSection(name: string | null): string[] {
  return ["Exotic", name ?? "(unresolved)"];
}

function renderStatSection(
  priorities: LoadoutOptimizerParams["statPriorities"],
): string[] {
  const lines = ["Stat priorities"];
  for (const { stat, target } of priorities) {
    lines.push(`${stat}: ${target}`);
  }
  return lines;
}

function renderModsSection(
  modsPerSlot: LoadoutOptimizerParams["modsPerSlot"],
): string[] {
  const lines = ["Mods"];
  for (const { slot, mods } of modsPerSlot) {
    const modList = mods.length > 0 ? mods.join(", ") : "(none)";
    lines.push(`${slot}: ${modList}`);
  }
  return lines;
}

function renderNotesSection(notes: string[]): string[] {
  const lines = ["Notes"];
  for (const note of notes) {
    lines.push(`- ${note}`);
  }
  return lines;
}

export function renderLoParamsText(params: LoadoutOptimizerParams): string {
  const sections = [
    renderExoticSection(params.exoticArmorName),
    renderStatSection(params.statPriorities),
    renderModsSection(params.modsPerSlot),
    renderNotesSection(params.notes),
  ];

  return sections
    .map((lines, index) => (index < sections.length - 1 ? [...lines, ""] : lines))
    .flat()
    .join("\n");
}
