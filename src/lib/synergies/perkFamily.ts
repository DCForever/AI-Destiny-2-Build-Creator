/**
 * Weapon perk base/enhanced family matching (DBR-SYN-014a).
 *
 * Destiny enhanced traits often share a display name with the base plug
 * (suffix " Enhanced", prefix "Enhanced ", or "(Enhanced)"). When the family
 * is known, either plug satisfies coverage / required-link checks.
 * Saved rolls still store the specific plug hash.
 */

import type { PerkRecord } from "@/lib/manifest/types/records";

/** Normalize a perk display name to a family key (base ↔ enhanced). */
export function perkFamilyKey(name: string): string {
  return name
    .trim()
    .toLowerCase()
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/\s*\(enhanced\)\s*$/i, "")
    .replace(/\senhanced$/i, "")
    .replace(/^enhanced\s+/i, "")
    .replace(/\s+/g, " ")
    .trim();
}

/**
 * Map plug hash → set of all hashes in the same family (including self).
 * Built from weapon-perks (or any name+hash list) by family key.
 */
export function buildPerkFamilyIndex(
  perks: Array<Pick<PerkRecord, "hash" | "name">>,
): Map<number, ReadonlySet<number>> {
  const byKey = new Map<string, number[]>();
  for (const perk of perks) {
    const name = perk.name?.trim();
    if (!name) continue;
    const key = perkFamilyKey(name);
    if (!key) continue;
    const list = byKey.get(key);
    if (list) list.push(perk.hash);
    else byKey.set(key, [perk.hash]);
  }

  const index = new Map<number, ReadonlySet<number>>();
  for (const hashes of byKey.values()) {
    const family = new Set(hashes);
    for (const h of hashes) {
      index.set(h, family);
    }
  }
  return index;
}

/** All hashes that count as a match for `targetHash` (self if family unknown). */
export function familyHashesFor(
  targetHash: number,
  index: Map<number, ReadonlySet<number>> | null | undefined,
): ReadonlySet<number> {
  const family = index?.get(targetHash);
  if (family && family.size > 0) return family;
  return new Set([targetHash]);
}

/**
 * True when selected plug hashes include the target or a known family sibling.
 */
export function selectedPerksIncludeFamily(
  selectedPerks: number[] | null | undefined,
  targetHash: number,
  index?: Map<number, ReadonlySet<number>> | null,
): boolean {
  if (!selectedPerks?.length) return false;
  if (selectedPerks.includes(targetHash)) return true;
  const family = index?.get(targetHash);
  if (!family) return false;
  return selectedPerks.some((h) => family.has(h));
}
