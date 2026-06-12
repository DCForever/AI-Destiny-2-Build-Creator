/**
 * Resolution helpers for resolveBuild. Converts LLM name-based picks into
 * ResolvedReference / ResolvedPerkPick objects and assembles each sheet section.
 */

import type { GeneratedBuild } from "@/lib/llm/buildSchema";
import type { ItemResolver, PerkValidator, EntityCache, PerkLegality } from "@/lib/manifest/types/services";
import type { EntityRecordBase, ArtifactRecord, Hash } from "@/lib/manifest/types/records";
import type { StoreName } from "@/lib/manifest/types/stores";
import type {
  ResolvedReference,
  ResolvedPerkPick,
  ResolvedSubclass,
  ResolvedWeapon,
  ResolvedStatTarget,
  ResolvedArtifact,
  FragmentCheckView,
} from "./types";
import { normalizeName } from "@/lib/manifest/normalize";
import { computeBenefitsAt } from "@/data/rules/statBenefits";
import { isArtifactAllowed } from "@/data/rules/activityRules";
import { getChampionCounterForFrame } from "@/data/rules/championCounters";
import type { ChampionType } from "@/data/rules/championCounters";

export interface ResolveBuildDeps {
  resolver: ItemResolver;
  validator: PerkValidator;
  cache: EntityCache;
}

export interface SubclassResolutionResult {
  subclass: ResolvedSubclass;
  verbCheckItems: Array<{ name: string; description: string }>;
}

type BaseResolveResult = { record: EntityRecordBase; confidence: number } | null;

interface ResolvedWithDesc {
  ref: ResolvedReference;
  description: string;
}

type SubclassAbilityKey = "super" | "classAbility" | "movement" | "melee" | "grenade";
const ABILITY_KINDS: readonly SubclassAbilityKey[] = [
  "super", "classAbility", "movement", "melee", "grenade",
];

// --- Core ref-building utilities ---

function buildRef(requestedName: string, result: BaseResolveResult): ResolvedReference {
  if (!result) return { requestedName, resolved: null, confidence: 0, status: "unresolved" };
  const { record, confidence } = result;
  return {
    requestedName,
    resolved: { hash: record.hash, name: record.name, icon: record.icon },
    confidence,
    status: confidence === 1 ? "verified" : "fuzzy",
  };
}

async function resolveRef(
  store: StoreName,
  name: string,
  resolver: ItemResolver,
): Promise<ResolvedReference> {
  const result = await resolver.resolve(store, name);
  return buildRef(name, result as BaseResolveResult);
}

async function resolveWithDesc(
  store: "aspects" | "fragments" | "abilities",
  name: string,
  resolver: ItemResolver,
): Promise<ResolvedWithDesc> {
  const result = await resolver.resolve(store, name);
  const ref = buildRef(name, result as BaseResolveResult);
  const record = result?.record as { description?: string } | undefined;
  return { ref, description: record?.description ?? "" };
}

function mapPerkLegality(l: PerkLegality): { legal: boolean; reason?: string; curated?: boolean } {
  return l.legal ? { legal: true, curated: l.curated } : { legal: false, reason: l.reason };
}

// --- Subclass ---

function buildVerbCheckItems(
  aspectResults: ResolvedWithDesc[],
  fragmentResults: ResolvedWithDesc[],
  abilityResults: Array<{ kind: SubclassAbilityKey } & ResolvedWithDesc>,
): Array<{ name: string; description: string }> {
  const verbAbilities = abilityResults.filter(r => r.kind === "melee" || r.kind === "grenade");
  return [...aspectResults, ...fragmentResults, ...verbAbilities]
    .filter(r => r.ref.resolved !== null)
    .map(r => ({ name: r.ref.resolved!.name, description: r.description }));
}

async function computeFragmentCheck(
  aspects: ResolvedReference[],
  fragmentCount: number,
  validator: PerkValidator,
): Promise<FragmentCheckView | null> {
  const hashes = aspects.filter(a => a.resolved !== null).map(a => a.resolved!.hash);
  if (hashes.length === 0) return null;
  return validator.checkFragmentCount(hashes, fragmentCount);
}

async function resolveAllAbilities(
  subclass: GeneratedBuild["subclass"],
  resolver: ItemResolver,
): Promise<Array<{ kind: SubclassAbilityKey } & ResolvedWithDesc>> {
  return Promise.all(
    ABILITY_KINDS.map(async kind => ({
      kind,
      ...(await resolveWithDesc("abilities", subclass[kind], resolver)),
    }))
  );
}

export async function resolveSubclass(
  build: GeneratedBuild,
  deps: ResolveBuildDeps,
): Promise<SubclassResolutionResult> {
  const { subclass } = build;
  const { resolver, validator } = deps;
  const [aspectResults, fragmentResults] = await Promise.all([
    Promise.all(subclass.aspects.map(n => resolveWithDesc("aspects", n, resolver))),
    Promise.all(subclass.fragments.map(n => resolveWithDesc("fragments", n, resolver))),
  ]);
  const abilityResults = await resolveAllAbilities(subclass, resolver);
  const aspects = aspectResults.map(r => r.ref);
  const fragments = fragmentResults.map(r => r.ref);
  const abilities = abilityResults.map(r => ({ kind: r.kind as string, reference: r.ref }));
  const fragmentCheck = await computeFragmentCheck(aspects, subclass.fragments.length, validator);
  const verbCheckItems = buildVerbCheckItems(aspectResults, fragmentResults, abilityResults);
  return {
    subclass: { aspects, fragments, abilities, fragmentCheck, rationale: subclass.rationale },
    verbCheckItems,
  };
}

// --- Exotic armor ---

export async function resolveExoticArmor(
  build: GeneratedBuild,
  deps: ResolveBuildDeps,
): Promise<ResolvedReference & { alternatives: ResolvedReference[] }> {
  const mainRef = await resolveRef("exotic-armor", build.exoticArmor.name, deps.resolver);
  const alternatives = await Promise.all(
    build.exoticArmor.alternatives.map(alt => resolveRef("exotic-armor", alt.name, deps.resolver))
  );
  return { ...mainRef, alternatives };
}

// --- Weapons ---

function extractFrame(result: BaseResolveResult): string | null {
  if (!result) return null;
  return (result.record as unknown as { frame: string }).frame;
}

function extractElementAndAmmo(result: BaseResolveResult): {
  element: string | null;
  ammo: string | null;
} {
  if (!result) return { element: null, ammo: null };
  const record = result.record as unknown as { element?: string; ammo?: string };
  return { element: record.element ?? null, ammo: record.ammo ?? null };
}

function extractChampionCounter(
  frame: string | null,
  result: BaseResolveResult,
  isExotic: boolean,
): ChampionType | null {
  if (!frame || !result) return null;
  const typeName = isExotic ? "" : (result.record as unknown as { itemTypeName: string }).itemTypeName;
  return getChampionCounterForFrame(frame, typeName);
}

async function computeWeaponPerkLegality(
  ref: ResolvedReference,
  isExotic: boolean,
  weaponHash: Hash | null,
  validator: PerkValidator,
): Promise<{ legal: boolean; reason?: string; curated?: boolean } | null> {
  if (!ref.resolved || isExotic || weaponHash === null) return null;
  const legality = await validator.checkWeaponPerk(weaponHash, ref.resolved.hash);
  return mapPerkLegality(legality);
}

async function resolveWeaponPerks(
  weapon: GeneratedBuild["weapons"][number],
  weaponHash: Hash | null,
  deps: ResolveBuildDeps,
): Promise<ResolvedPerkPick[]> {
  return Promise.all(weapon.perks.map(async perk => {
    const result = await deps.resolver.resolve("weapon-perks", perk.name);
    const ref = buildRef(perk.name, result as BaseResolveResult);
    const legality = await computeWeaponPerkLegality(ref, weapon.isExotic, weaponHash, deps.validator);
    return { ...ref, legality, rationale: perk.rationale };
  }));
}

export async function resolveWeapon(
  weapon: GeneratedBuild["weapons"][number],
  deps: ResolveBuildDeps,
): Promise<ResolvedWeapon> {
  const store = weapon.isExotic ? "exotic-weapons" : "weapons";
  const result = await deps.resolver.resolve(store, weapon.name);
  const ref = buildRef(weapon.name, result as BaseResolveResult);
  const frame = extractFrame(result as BaseResolveResult);
  const championCounter = extractChampionCounter(frame, result as BaseResolveResult, weapon.isExotic);
  const perks = await resolveWeaponPerks(weapon, ref.resolved?.hash ?? null, deps);
  const { element, ammo } = extractElementAndAmmo(result as BaseResolveResult);
  return {
    slot: weapon.slot,
    reference: ref,
    isExotic: weapon.isExotic,
    frame,
    element,
    ammo,
    championCounter,
    perks,
    rationale: weapon.rationale,
  };
}

// --- Mods ---

export async function resolveMods(
  build: GeneratedBuild,
  deps: ResolveBuildDeps,
): Promise<{ slot: string; picks: ResolvedPerkPick[] }[]> {
  const slots = [
    { slot: "helmet", picks: build.mods.helmet },
    { slot: "arms", picks: build.mods.arms },
    { slot: "chest", picks: build.mods.chest },
    { slot: "legs", picks: build.mods.legs },
    { slot: "classItem", picks: build.mods.classItem },
  ] as const;
  return Promise.all(slots.map(async ({ slot, picks }) => ({
    slot,
    picks: await Promise.all(picks.map(async name => {
      const ref = await resolveRef("mods", name, deps.resolver);
      return { ...ref, legality: null };
    })),
  })));
}

// --- Stat targets ---

export function resolveStatTargets(build: GeneratedBuild): ResolvedStatTarget[] {
  return build.statTargets.map(({ stat, target, rationale }) => ({
    stat,
    target,
    rationale,
    benefits: computeBenefitsAt(stat, target),
  }));
}

// --- Artifact ---

function makeUnmatchedPerkPick(
  pickName: string,
  rationale: string | undefined,
  reason: string,
): ResolvedPerkPick {
  return {
    requestedName: pickName, resolved: null, confidence: 0, status: "unresolved",
    legality: { legal: false, reason }, rationale,
  };
}

async function resolveArtifactPerkPick(
  pickName: string,
  rationale: string | undefined,
  artifactRecord: ArtifactRecord | undefined,
  artifactHash: Hash | null,
  validator: PerkValidator,
): Promise<ResolvedPerkPick> {
  if (!artifactRecord || artifactHash === null) {
    return makeUnmatchedPerkPick(pickName, rationale, "artifact not resolved");
  }
  const perkRecord = artifactRecord.perks.find(p => p.searchName === normalizeName(pickName));
  if (!perkRecord) {
    return makeUnmatchedPerkPick(pickName, rationale, `"${pickName}" not found in artifact perk grid`);
  }
  const legalityResult = await validator.checkArtifactPerk(artifactHash, perkRecord.hash);
  return {
    requestedName: pickName,
    resolved: { hash: perkRecord.hash, name: perkRecord.name, icon: perkRecord.icon },
    confidence: 1, status: "verified",
    legality: mapPerkLegality(legalityResult), rationale,
  };
}

export async function resolveArtifact(
  build: GeneratedBuild,
  activity: string,
  deps: ResolveBuildDeps,
): Promise<ResolvedArtifact | null> {
  if (!build.artifact) return null;
  const { artifact } = build;
  const result = await deps.resolver.resolve("artifacts", artifact.name);
  const ref = buildRef(artifact.name, result as BaseResolveResult);
  const artifactRecord = result?.record as ArtifactRecord | undefined;
  const artifactHash = ref.resolved?.hash ?? null;
  const perks = await Promise.all(
    artifact.perks.map(pick =>
      resolveArtifactPerkPick(pick.name, pick.rationale, artifactRecord, artifactHash, deps.validator)
    )
  );
  return { reference: ref, perks, rationale: artifact.rationale, allowedInActivity: isArtifactAllowed(activity) };
}
