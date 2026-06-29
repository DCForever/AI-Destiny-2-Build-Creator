import Fuse, { type IFuseOptions } from "fuse.js";

import type {
  ExoticArmorRecord,
  ExoticWeaponRecord,
  WeaponRecord,
} from "@/lib/manifest/types/records";

import type { CatalogFilterParams, CatalogItem } from "./types";

export const WEAPON_INVENTORY_BUCKETS = new Set(["Kinetic", "Energy", "Power"]);
export const ARMOR_INVENTORY_BUCKETS = new Set([
  "Helmet",
  "Gauntlets",
  "Chest",
  "Legs",
  "ClassItem",
]);

type SearchableCatalogRow = CatalogItem & { searchName: string };

const FUSE_OPTIONS: IFuseOptions<SearchableCatalogRow> = {
  keys: ["searchName", "name", "itemTypeName", "frame"],
  threshold: 0.35,
  ignoreLocation: true,
};

export type WeaponCatalogSource = {
  weapons: WeaponRecord[];
  exoticWeapons: ExoticWeaponRecord[];
};

export type ArmorCatalogSource = {
  exoticArmor: ExoticArmorRecord[];
};

export type InventoryBucketRow = { itemHash: number; bucket: string };

export function ownedHashesFromInventory(
  items: InventoryBucketRow[],
  kind: "weapons" | "armor",
): Map<number, number> {
  const buckets = kind === "weapons" ? WEAPON_INVENTORY_BUCKETS : ARMOR_INVENTORY_BUCKETS;
  const counts = new Map<number, number>();
  for (const item of items) {
    if (!buckets.has(item.bucket)) continue;
    counts.set(item.itemHash, (counts.get(item.itemHash) ?? 0) + 1);
  }
  return counts;
}

function weaponToCatalog(
  record: WeaponRecord | ExoticWeaponRecord,
  isExotic: boolean,
  ownedCount: number,
): SearchableCatalogRow {
  return {
    hash: record.hash,
    name: record.name,
    searchName: record.searchName,
    icon: record.icon,
    slot: record.slot,
    element: record.element,
    itemTypeName: "itemTypeName" in record ? record.itemTypeName : undefined,
    frame: record.frame,
    isExotic,
    owned: ownedCount > 0,
    ownedCount,
  };
}

function armorToCatalog(record: ExoticArmorRecord, ownedCount: number): SearchableCatalogRow {
  return {
    hash: record.hash,
    name: record.name,
    searchName: record.searchName,
    icon: record.icon,
    slot: record.slot,
    classType: record.classType,
    frame: record.archetype ?? undefined,
    isExotic: true,
    owned: ownedCount > 0,
    ownedCount,
  };
}

function applyFieldFilters(rows: SearchableCatalogRow[], params: CatalogFilterParams): SearchableCatalogRow[] {
  return rows.filter((row) => {
    if (params.slot && row.slot !== params.slot) return false;
    if (params.itemType && row.itemTypeName !== params.itemType) return false;
    if (params.frame && row.frame !== params.frame) return false;
    if (params.className && row.classType !== params.className) return false;
    return true;
  });
}

function applySearch(rows: SearchableCatalogRow[], q?: string): SearchableCatalogRow[] {
  if (!q?.trim()) return rows;
  const fuse = new Fuse(rows, FUSE_OPTIONS);
  return fuse.search(q.trim()).map((hit) => hit.item);
}

function finalize(rows: SearchableCatalogRow[], limit?: number): CatalogItem[] {
  const capped = limit ? rows.slice(0, limit) : rows;
  return capped.map((row) => {
    const { searchName, ...item } = row;
    void searchName;
    return item;
  });
}

export function filterWeaponCatalog(
  source: WeaponCatalogSource,
  params: CatalogFilterParams & { ownedHashes?: Map<number, number> },
): CatalogItem[] {
  const owned = params.ownedHashes ?? new Map<number, number>();
  const manifestRows: SearchableCatalogRow[] = [
    ...source.weapons.map((w) => weaponToCatalog(w, false, owned.get(w.hash) ?? 0)),
    ...source.exoticWeapons.map((w) => weaponToCatalog(w, true, owned.get(w.hash) ?? 0)),
  ];

  let rows = manifestRows;
  if (params.scope === "owned") {
    rows = manifestRows.filter((row) => owned.has(row.hash));
    for (const [hash, count] of owned) {
      if (rows.some((r) => r.hash === hash)) continue;
      rows.push({
        hash,
        name: `Unknown (${hash})`,
        searchName: String(hash),
        icon: null,
        isExotic: false,
        owned: true,
        ownedCount: count,
      });
    }
  }

  rows = applyFieldFilters(rows, params);
  rows = applySearch(rows, params.q);
  return finalize(rows, params.limit);
}

export function filterArmorCatalog(
  source: ArmorCatalogSource,
  params: CatalogFilterParams & { ownedHashes?: Map<number, number> },
): CatalogItem[] {
  const owned = params.ownedHashes ?? new Map<number, number>();
  let rows: SearchableCatalogRow[] = source.exoticArmor.map((a) =>
    armorToCatalog(a, owned.get(a.hash) ?? 0),
  );

  if (params.scope === "owned") {
    rows = rows.filter((row) => owned.has(row.hash));
    for (const [hash, count] of owned) {
      if (rows.some((r) => r.hash === hash)) continue;
      rows.push({
        hash,
        name: `Unknown (${hash})`,
        searchName: String(hash),
        icon: null,
        isExotic: false,
        owned: true,
        ownedCount: count,
      });
    }
  }

  rows = applyFieldFilters(rows, params);
  rows = applySearch(rows, params.q);
  return finalize(rows, params.limit);
}
