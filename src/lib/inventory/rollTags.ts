import { getChampionCounterForFrame, type ChampionType } from "@/data/rules/championCounters";
import type { RollTag } from "@/lib/db/types";
import type { WeaponRecord } from "@/lib/manifest/types/records";

export interface ComputeRollTagsOptions {
  isCrafted?: boolean;
}

const CHAMPION_TAG: Record<ChampionType, RollTag> = {
  Barrier: "ChampionBarrier",
  Overload: "ChampionOverload",
  Unstoppable: "ChampionUnstoppable",
};

const PERK_CHAMPION_PATTERNS: { pattern: RegExp; tag: RollTag }[] = [
  { pattern: /\banti-?barrier\b/i, tag: "ChampionBarrier" },
  { pattern: /\bbarrier\b/i, tag: "ChampionBarrier" },
  { pattern: /\boverload\b/i, tag: "ChampionOverload" },
  { pattern: /\bunstoppable\b/i, tag: "ChampionUnstoppable" },
];

function perkNamesFromHashes(
  plugHashes: number[],
  perkNameMap: Map<number, string>,
): string[] {
  return plugHashes
    .map((hash) => perkNameMap.get(hash))
    .filter((name): name is string => Boolean(name));
}

function hasPerk(names: string[], target: string): boolean {
  const needle = target.toLowerCase();
  return names.some((name) => name.toLowerCase().includes(needle));
}

function championTagFromPerks(names: string[]): RollTag | null {
  for (const { pattern, tag } of PERK_CHAMPION_PATTERNS) {
    if (names.some((name) => pattern.test(name))) return tag;
  }
  return null;
}

/**
 * Rule-based roll tag assignment from plug hashes and optional weapon metadata.
 * Tags are computed at sync time and stored on inventory rows.
 */
export function computeRollTags(
  plugHashes: number[],
  perkNameMap: Map<number, string>,
  weaponRecord?: WeaponRecord | null,
  options?: ComputeRollTagsOptions,
): RollTag[] {
  const tags = new Set<RollTag>();
  const perkNames = perkNamesFromHashes(plugHashes, perkNameMap);

  if (options?.isCrafted) {
    tags.add("Crafted");
  }

  if (weaponRecord) {
    const intrinsic = getChampionCounterForFrame(
      weaponRecord.frame,
      weaponRecord.itemTypeName,
    );
    if (intrinsic) tags.add(CHAMPION_TAG[intrinsic]);
  }

  const perkChampion = championTagFromPerks(perkNames);
  if (perkChampion) tags.add(perkChampion);

  if (
    weaponRecord?.itemTypeName === "Hand Cannon"
    && hasPerk(perkNames, "Pugilist")
    && hasPerk(perkNames, "Swashbuckler")
  ) {
    tags.add("MeleeBuildCandidate");
  }

  if (hasPerk(perkNames, "Demolitionist") && hasPerk(perkNames, "Adrenaline Junkie")) {
    tags.add("OrbitBuild");
  }

  return [...tags];
}
