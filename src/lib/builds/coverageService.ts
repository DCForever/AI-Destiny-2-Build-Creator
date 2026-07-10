import type { AppDatabase } from "@/lib/db/client";
import { getBuild } from "@/lib/db/repositories/buildRepository";
import { getSynergiesByIds } from "@/lib/db/repositories/synergyRepository";
import { getVariant, listAttachments } from "@/lib/db/repositories/variantRepository";
import { listInventoryItems } from "@/lib/db/repositories/inventoryRepository";
import {
  coverageGapsForSuggest,
  evaluateCoverage,
  type CoverageResult,
} from "@/lib/builds/coverage";
import { estimateLoadoutStats } from "@/lib/builds/statEstimate";
import { effectiveExoticWeapon, resolveVariantEquipment } from "@/lib/builds/resolveVariant";
import { buildSetBonusByItemHash } from "@/lib/inventory/instances/armorSetBonus";
import { getServices } from "@/lib/services";

async function loadCoverageIndexes(): Promise<{
  setBonusByItemHash: Map<number, import("@/lib/manifest/types/records").SetBonusRecord>;
  weaponElementByHash: Map<number, string>;
}> {
  try {
    const { entityCache } = await getServices();
    const [bonuses, weapons, exoticWeapons] = await Promise.all([
      entityCache.getStore("set-bonuses"),
      entityCache.getStore("weapons"),
      entityCache.getStore("exotic-weapons"),
    ]);
    const setBonusByItemHash = buildSetBonusByItemHash(bonuses);
    const weaponElementByHash = new Map<number, string>();
    for (const w of [...weapons, ...exoticWeapons] as Array<{ hash: number; element?: string }>) {
      if (w.element) weaponElementByHash.set(w.hash, w.element);
    }
    return { setBonusByItemHash, weaponElementByHash };
  } catch {
    return { setBonusByItemHash: new Map(), weaponElementByHash: new Map() };
  }
}

export async function getVariantCoverage(
  db: AppDatabase,
  userId: number,
  buildId: string,
  variantId: string,
): Promise<CoverageResult | null> {
  const build = getBuild(db, userId, buildId);
  const variant = getVariant(db, buildId, variantId);
  if (!build || !variant) return null;

  const attachments = listAttachments(db, variantId);
  const weapon = effectiveExoticWeapon(build, variant);
  const resolved = await resolveVariantEquipment(db, userId, build, variant, attachments, {
    exoticWeaponSlot: weapon.exoticWeaponHash ? "primary" : null,
    exoticArmorSlot: build.exoticArmorHash ? "chest" : null,
  });

  const claims = Object.values(resolved.equipment);
  const synergies = getSynergiesByIds(db, userId, build.synergyIds);
  const indexes = await loadCoverageIndexes();
  const inventory = listInventoryItems(db, userId);
  const byInstance = new Map(inventory.map((i) => [i.instanceId, i]));
  const statEstimate = estimateLoadoutStats(claims, byInstance);

  return evaluateCoverage({
    claims,
    synergies,
    subclass: build.subclass,
    setBonusByItemHash: indexes.setBonusByItemHash,
    weaponElementByHash: indexes.weaponElementByHash,
    softStatTargets: build.softStatTargets,
    statEstimate,
  });
}

export async function getCoverageGapsForSuggest(
  db: AppDatabase,
  userId: number,
  buildId: string,
  variantId: string,
) {
  const build = getBuild(db, userId, buildId);
  if (!build) return [];
  const coverage = await getVariantCoverage(db, userId, buildId, variantId);
  if (!coverage) return [];
  const synergies = getSynergiesByIds(db, userId, build.synergyIds);
  return coverageGapsForSuggest(coverage, synergies);
}
