/**
 * Shared indexes for evidence matching (coverage + required links).
 * Kept separate from coverageService so save paths can load indexes without
 * importing soft-coverage evaluation (softSave.coverage invariant).
 */

import { buildSetBonusByItemHash } from "@/lib/inventory/instances/armorSetBonus";
import type { SetBonusRecord } from "@/lib/manifest/types/records";
import { getServices } from "@/lib/services";
import { buildPerkFamilyIndex } from "@/lib/synergies/perkFamily";

export type MatchEvidenceIndexes = {
  setBonusByItemHash: Map<number, SetBonusRecord>;
  weaponElementByHash: Map<number, string>;
  perkFamilyByHash: Map<number, ReadonlySet<number>>;
  exoticClassItemHashes: Set<number>;
};

/** Indexes for DBR-SYN-014a (perk family) and DBR-ID-011 (class-item perks). */
export async function loadMatchEvidenceIndexes(): Promise<MatchEvidenceIndexes> {
  try {
    const { entityCache } = await getServices();
    const [bonuses, weapons, exoticWeapons, weaponPerks, exoticArmor] = await Promise.all([
      entityCache.getStore("set-bonuses"),
      entityCache.getStore("weapons"),
      entityCache.getStore("exotic-weapons"),
      entityCache.getStore("weapon-perks"),
      entityCache.getStore("exotic-armor"),
    ]);
    const setBonusByItemHash = buildSetBonusByItemHash(bonuses);
    const weaponElementByHash = new Map<number, string>();
    for (const w of [...weapons, ...exoticWeapons] as Array<{ hash: number; element?: string }>) {
      if (w.element) weaponElementByHash.set(w.hash, w.element);
    }
    const perkFamilyByHash = buildPerkFamilyIndex(weaponPerks ?? []);
    const exoticClassItemHashes = new Set<number>();
    for (const a of exoticArmor ?? []) {
      if (a.slot === "ClassItem") exoticClassItemHashes.add(a.hash);
    }
    return {
      setBonusByItemHash,
      weaponElementByHash,
      perkFamilyByHash,
      exoticClassItemHashes,
    };
  } catch {
    return {
      setBonusByItemHash: new Map(),
      weaponElementByHash: new Map(),
      perkFamilyByHash: new Map(),
      exoticClassItemHashes: new Set(),
    };
  }
}
