/**
 * Entry point: converts a GeneratedBuild (name-based LLM output) into a fully
 * resolved, validated ResolvedBuildSheet.
 */

import type { GeneratedBuild } from "@/lib/llm/buildSchema";
import type {
  ResolvedBuildSheet,
  ResolvedReference,
  ResolvedPerkPick,
  ResolvedSubclass,
  ResolvedWeapon,
  ResolvedArtifact,
  ValidationSummary,
} from "./types";
import {
  resolveSubclass,
  resolveExoticArmor,
  resolveWeapon,
  resolveMods,
  resolveStatTargets,
  resolveArtifact,
} from "./resolveHelpers";
import type { ResolveBuildDeps } from "./resolveHelpers";
import { computeChampionCoverage } from "./championCoverage";

export type { ResolveBuildDeps };

// --- Validation summary ---

interface ValidationInput {
  subclass: ResolvedSubclass;
  exoticArmor: ResolvedReference & { alternatives: ResolvedReference[] };
  weapons: ResolvedWeapon[];
  mods: { slot: string; picks: ResolvedPerkPick[] }[];
  artifact: ResolvedArtifact | null;
}

function addRef(ref: ResolvedReference, counts: ValidationSummary): void {
  if (ref.status === "verified") counts.verified++;
  else if (ref.status === "fuzzy") counts.fuzzy++;
  else counts.unresolved++;
}

function addPick(pick: ResolvedPerkPick, counts: ValidationSummary): void {
  addRef(pick, counts);
  if (pick.legality !== null && !pick.legality.legal) counts.illegalPerks++;
}

function computeValidation(input: ValidationInput): ValidationSummary {
  const counts: ValidationSummary = { verified: 0, fuzzy: 0, unresolved: 0, illegalPerks: 0 };

  for (const r of input.subclass.aspects) addRef(r, counts);
  for (const r of input.subclass.fragments) addRef(r, counts);
  for (const { reference } of input.subclass.abilities) addRef(reference, counts);

  addRef(input.exoticArmor, counts);
  for (const r of input.exoticArmor.alternatives) addRef(r, counts);

  for (const w of input.weapons) {
    addRef(w.reference, counts);
    for (const p of w.perks) addPick(p, counts);
  }

  for (const { picks } of input.mods) {
    for (const p of picks) addPick(p, counts);
  }

  if (input.artifact) {
    addRef(input.artifact.reference, counts);
    for (const p of input.artifact.perks) addPick(p, counts);
  }

  return counts;
}

// --- Main entry point ---

export async function resolveBuild(
  build: GeneratedBuild,
  activity: string,
  deps: ResolveBuildDeps,
): Promise<ResolvedBuildSheet> {
  const [subclassResult, exoticArmor, weapons, mods, artifact] = await Promise.all([
    resolveSubclass(build, deps),
    resolveExoticArmor(build, deps),
    Promise.all(build.weapons.map(w => resolveWeapon(w, deps))),
    resolveMods(build, deps),
    resolveArtifact(build, activity, deps),
  ]);

  const statTargets = resolveStatTargets(build);
  const championCoverage = computeChampionCoverage(weapons, subclassResult.verbCheckItems);

  const partial: ValidationInput = {
    subclass: subclassResult.subclass,
    exoticArmor,
    weapons,
    mods,
    artifact,
  };

  return {
    build,
    activity,
    subclass: subclassResult.subclass,
    exoticArmor,
    weapons,
    statTargets,
    mods,
    artifact,
    championCoverage,
    validation: computeValidation(partial),
  };
}
