/**
 * Server enforcement of DBR-CMP-007 / DAC-DST-001 after equipment resolve.
 */

import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import { evaluateExoticLimits } from "@/lib/builds/destinyBuildConstraints";
import type { SlotClaim } from "@/lib/builds/resolveVariant";
import { getServices } from "@/lib/services";

/**
 * Count exotic weapon / armor hashes among equipment claims.
 * Uses entity-cache exotic stores plus known exotic claim sources/slots.
 */
export async function collectExoticComposition(
  claims: SlotClaim[],
): Promise<{ exoticWeaponHashes: number[]; exoticArmorHashes: number[] }> {
  const { entityCache } = await getServices();
  const [exoticWeapons, exoticArmor] = await Promise.all([
    entityCache.getStore("exotic-weapons"),
    entityCache.getStore("exotic-armor"),
  ]);
  const weaponSet = new Set(exoticWeapons.map((w) => w.hash));
  const armorSet = new Set(exoticArmor.map((a) => a.hash));

  const exoticWeaponHashes: number[] = [];
  const exoticArmorHashes: number[] = [];

  for (const claim of claims) {
    const isExoticWeapon =
      weaponSet.has(claim.itemHash) ||
      claim.slot === "exotic_weapon" ||
      claim.source === "variant_exotic_weapon";
    const isExoticArmor =
      armorSet.has(claim.itemHash) ||
      claim.slot === "exotic_armor" ||
      claim.source === "build_exotic_armor";

    if (isExoticWeapon) exoticWeaponHashes.push(claim.itemHash);
    if (isExoticArmor) exoticArmorHashes.push(claim.itemHash);
  }

  return { exoticWeaponHashes, exoticArmorHashes };
}

export async function assertExoticLimits(claims: SlotClaim[]): Promise<void> {
  const composition = await collectExoticComposition(claims);
  const { hardBlocks } = evaluateExoticLimits(composition);
  if (hardBlocks.length === 0) return;
  throw new ApiError(
    API_ERROR_CODES.TOO_MANY_EXOTICS,
    hardBlocks.map((b) => b.message).join("; "),
    {
      hardBlocks,
      exoticWeaponHashes: [...new Set(composition.exoticWeaponHashes)],
      exoticArmorHashes: [...new Set(composition.exoticArmorHashes)],
    },
    400,
  );
}
