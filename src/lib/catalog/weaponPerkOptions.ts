import type { WeaponPerkColumn } from "@/lib/manifest/types/records";

export interface WeaponPerkOption {
  hash: number;
  name: string;
}

export interface WeaponPerkOptionColumn {
  column: number;
  options: WeaponPerkOption[];
}

export interface WeaponPerkOptions {
  itemHash: number;
  columns: WeaponPerkOptionColumn[];
}

/**
 * Compose the per-socket plug options a weapon can hold (curated ∪ randomized,
 * de-duplicated, socket-ordered) with resolved perk names. Degrades to empty
 * `columns` for unknown/non-weapon items so callers can fall back to equipped.
 */
export function resolveWeaponPerkOptions(
  itemHash: number,
  weapon: { perkColumns?: WeaponPerkColumn[] } | null | undefined,
  perkNames: Map<number, string>,
): WeaponPerkOptions {
  const perkColumns = weapon?.perkColumns ?? [];

  const columns: WeaponPerkOptionColumn[] = perkColumns.map((perkColumn) => {
    const seen = new Set<number>();
    const options: WeaponPerkOption[] = [];
    for (const hash of [...perkColumn.curated, ...perkColumn.randomized]) {
      if (seen.has(hash)) continue;
      seen.add(hash);
      options.push({ hash, name: perkNames.get(hash) ?? String(hash) });
    }
    return { column: perkColumn.column, options };
  });

  return { itemHash, columns };
}
