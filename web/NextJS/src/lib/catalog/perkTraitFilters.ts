import type { OriginTraitRecord, PerkRecord, WeaponRecord } from "@/lib/manifest/types/records";
import type { PerkWeaponIndex } from "@/lib/manifest/perkWeaponIndex";
import { matchByNameOrDescription } from "@/lib/search/descriptionMatch";

export type PerkFilterResolution =
  | { ok: true; weaponHashes: Set<number> }
  | { ok: false };

export type OriginTraitFilterResolution =
  | { ok: true; weaponHashes: Set<number> }
  | { ok: false };

function parseNumericHash(value: string): number | null {
  const trimmed = value.trim();
  if (!/^\d+$/.test(trimmed)) return null;
  const hash = Number(trimmed);
  return Number.isFinite(hash) && hash > 0 ? hash : null;
}

export function resolvePerkFilter(
  perk: string,
  perks: PerkRecord[],
  index: PerkWeaponIndex | null,
): PerkFilterResolution {
  const numeric = parseNumericHash(perk);
  const perkHashes =
    numeric !== null ? [numeric] : matchByNameOrDescription(perk, perks).map((p) => p.hash);
  if (perkHashes.length === 0) return { ok: false };
  if (!index) return { ok: false };

  const weaponHashes = new Set<number>();
  for (const hash of perkHashes) {
    for (const entry of index.byPerk[String(hash)] ?? []) {
      weaponHashes.add(entry.weaponHash);
    }
  }

  if (weaponHashes.size === 0) return { ok: false };
  return { ok: true, weaponHashes };
}

export function resolveOriginTraitFilter(
  originTrait: string,
  traits: OriginTraitRecord[],
  weapons: WeaponRecord[],
): OriginTraitFilterResolution {
  const numeric = parseNumericHash(originTrait);
  const traitHashes =
    numeric !== null ? [numeric] : matchByNameOrDescription(originTrait, traits).map((t) => t.hash);
  if (traitHashes.length === 0) return { ok: false };

  const traitHashSet = new Set(traitHashes);
  const weaponHashes = new Set<number>();
  for (const weapon of weapons) {
    if (weapon.originTraitHashes.some((hash) => traitHashSet.has(hash))) {
      weaponHashes.add(weapon.hash);
    }
  }

  if (weaponHashes.size === 0) return { ok: false };
  return { ok: true, weaponHashes };
}

export function combineWeaponAllowlists(
  perkHashes: Set<number> | undefined,
  traitHashes: Set<number> | undefined,
): Set<number> | undefined {
  if (!perkHashes && !traitHashes) return undefined;
  if (perkHashes && traitHashes) {
    const intersection = new Set<number>();
    for (const hash of perkHashes) {
      if (traitHashes.has(hash)) intersection.add(hash);
    }
    return intersection;
  }
  return perkHashes ?? traitHashes;
}
