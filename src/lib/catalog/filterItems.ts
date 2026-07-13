import Fuse, { type IFuseOptions } from "fuse.js";

import type {
  ExoticArmorRecord,
  ExoticWeaponRecord,
  WeaponRecord,
} from "@/lib/manifest/types/records";

import { compareDisplayName } from "@/lib/sortByName";
import type { LegendaryArmorRow } from "./legendaryArmor";
import type { CatalogFilterParams, CatalogItem } from "./types";

export const WEAPON_INVENTORY_BUCKETS = new Set(["Kinetic", "Energy", "Power"]);
export const ARMOR_INVENTORY_BUCKETS = new Set([
  "Helmet",
  "Gauntlets",
  "Chest",
  "Legs",
  "ClassItem",
]);

type SearchableCatalogRow = CatalogItem & {
  searchName: string;
  intrinsicName?: string;
  intrinsicDescription?: string;
};

const FUSE_OPTIONS: IFuseOptions<SearchableCatalogRow> = {
  keys: ["searchName", "name", "itemTypeName", "frame", "intrinsicName", "intrinsicDescription"],
  threshold: 0.35,
  ignoreLocation: true,
};

export type WeaponCatalogSource = {
  weapons: WeaponRecord[];
  exoticWeapons: ExoticWeaponRecord[];
};

export type ArmorCatalogSource = {
  exoticArmor: ExoticArmorRecord[];
  legendaryArmor?: LegendaryArmorRow[];
};

export type InventoryBucketRow = { itemHash: number; bucket: string };

export type InventoryHashProjection = {
  name: string;
  searchName: string;
  icon: string | null;
};

export function aggregateOwnedCountsBySearchName(
  manifestRows: Array<{ hash: number; searchName: string }>,
  owned: Map<number, number>,
  projections: Map<number, InventoryHashProjection>,
): Map<number, number> {
  const representativeBySearchName = new Map<string, number>();
  for (const row of manifestRows) {
    if (!representativeBySearchName.has(row.searchName)) {
      representativeBySearchName.set(row.searchName, row.hash);
    }
  }

  const manifestHashSet = new Set(manifestRows.map((row) => row.hash));
  const counts = new Map<number, number>();

  for (const [hash, count] of owned) {
    if (manifestHashSet.has(hash)) {
      counts.set(hash, (counts.get(hash) ?? 0) + count);
      continue;
    }

    const projection = projections.get(hash);
    if (projection) {
      const representative = representativeBySearchName.get(projection.searchName);
      if (representative !== undefined) {
        counts.set(representative, (counts.get(representative) ?? 0) + count);
        continue;
      }
    }

    counts.set(hash, (counts.get(hash) ?? 0) + count);
  }

  return counts;
}

function applyAggregatedOwnedCounts(
  rows: SearchableCatalogRow[],
  aggregated: Map<number, number>,
): void {
  for (const row of rows) {
    const ownedCount = aggregated.get(row.hash) ?? 0;
    row.ownedCount = ownedCount;
    row.owned = ownedCount > 0;
  }
}

function isOwnedHashCoveredByRows(
  hash: number,
  count: number,
  rows: SearchableCatalogRow[],
  projections: Map<number, InventoryHashProjection>,
): boolean {
  if (count <= 0) return true;
  if (rows.some((row) => row.hash === hash && row.ownedCount > 0)) return true;
  const projection = projections.get(hash);
  if (projection) {
    return rows.some((row) => row.searchName === projection.searchName && row.ownedCount > 0);
  }
  return false;
}

function unknownOwnedRow(
  hash: number,
  count: number,
  projection: InventoryHashProjection | undefined,
): SearchableCatalogRow {
  return {
    hash,
    name: projection?.name ?? `Unknown (${hash})`,
    searchName: projection?.searchName ?? String(hash),
    icon: projection?.icon ?? null,
    isExotic: false,
    owned: true,
    ownedCount: count,
  };
}

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
  const intrinsic =
    isExotic && "intrinsic" in record ? record.intrinsic : undefined;
  return {
    hash: record.hash,
    name: record.name,
    searchName: record.searchName,
    icon: record.icon,
    slot: record.slot,
    element: record.element,
    ammo: "ammo" in record ? record.ammo : undefined,
    itemTypeName: "itemTypeName" in record ? record.itemTypeName : undefined,
    frame: record.frame,
    isExotic,
    owned: ownedCount > 0,
    ownedCount,
    intrinsicName: intrinsic?.name,
    intrinsicDescription: intrinsic?.description,
    description: intrinsic?.description,
  };
}

function armorToCatalog(
  record: ExoticArmorRecord,
  ownedCount: number,
): SearchableCatalogRow {
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
    intrinsicName: record.intrinsic.name,
    intrinsicDescription: record.intrinsic.description,
    description: record.intrinsic.description,
  };
}

function legendaryArmorToCatalog(record: LegendaryArmorRow, ownedCount: number): SearchableCatalogRow {
  return {
    hash: record.hash,
    name: record.name,
    searchName: record.searchName,
    icon: record.icon,
    slot: record.slot,
    classType: record.classType,
    setBonusName: record.setBonusName,
    setBonusHash: record.setBonusHash,
    isExotic: false,
    owned: ownedCount > 0,
    ownedCount,
  };
}

function applyHashAllowlist(
  rows: SearchableCatalogRow[],
  allowlist: Set<number> | undefined,
): SearchableCatalogRow[] {
  if (!allowlist) return rows;
  return rows.filter((row) => allowlist.has(row.hash));
}

function multiOrMatch(
  selected: string[] | undefined,
  value: string | undefined,
): boolean {
  if (!selected?.length) return true;
  if (!value) return false;
  return selected.includes(value);
}

/** Archetype match: exact itemTypeName, or frame containing the type (exotics). */
function matchesArchetype(
  selected: string[] | undefined,
  row: SearchableCatalogRow,
): boolean {
  if (!selected?.length) return true;
  if (row.itemTypeName && selected.includes(row.itemTypeName)) return true;
  if (row.frame) {
    return selected.some(
      (t) =>
        row.frame === t ||
        row.frame!.includes(t) ||
        t.includes(row.frame!.replace(/\s*Frame$/i, "").trim()),
    );
  }
  return false;
}

function applyFieldFilters(rows: SearchableCatalogRow[], params: CatalogFilterParams): SearchableCatalogRow[] {
  const itemTypes =
    params.itemTypes?.length
      ? params.itemTypes
      : params.itemType
        ? [params.itemType]
        : undefined;
  const frames =
    params.frames?.length
      ? params.frames
      : params.frame
        ? [params.frame]
        : undefined;

  return rows.filter((row) => {
    if (params.slot && row.slot !== params.slot) return false;
    if (!matchesArchetype(itemTypes, row)) return false;
    if (!multiOrMatch(frames, row.frame)) return false;
    if (!multiOrMatch(params.elements, row.element)) return false;
    if (!multiOrMatch(params.ammos, row.ammo)) return false;
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
  const sorted = [...rows].sort((a, b) => compareDisplayName(a.name, b.name));
  const capped = limit ? sorted.slice(0, limit) : sorted;
  return capped.map((row) => {
    const { searchName, intrinsicName, intrinsicDescription, ...item } = row;
    void searchName;
    void intrinsicName;
    void intrinsicDescription;
    return item;
  });
}

export function filterWeaponCatalog(
  source: WeaponCatalogSource,
  params: CatalogFilterParams & {
    ownedHashes?: Map<number, number>;
    inventoryProjections?: Map<number, InventoryHashProjection>;
  },
): CatalogItem[] {
  const owned = params.ownedHashes ?? new Map<number, number>();
  const projections = params.inventoryProjections ?? new Map<number, InventoryHashProjection>();
  const manifestRows: SearchableCatalogRow[] = [
    ...source.weapons.map((w) => weaponToCatalog(w, false, 0)),
    ...source.exoticWeapons.map((w) => weaponToCatalog(w, true, 0)),
  ];

  const aggregated = aggregateOwnedCountsBySearchName(manifestRows, owned, projections);
  applyAggregatedOwnedCounts(manifestRows, aggregated);

  let rows = manifestRows;
  if (params.scope === "owned") {
    rows = manifestRows.filter((row) => row.ownedCount > 0);
    for (const [hash, count] of owned) {
      if (isOwnedHashCoveredByRows(hash, count, rows, projections)) continue;
      rows.push(unknownOwnedRow(hash, count, projections.get(hash)));
    }
  }

  rows = applyFieldFilters(rows, params);
  rows = applyHashAllowlist(rows, params.weaponHashAllowlist);
  rows = applySearch(rows, params.q);
  return finalize(rows, params.limit);
}

export function filterArmorCatalog(
  source: ArmorCatalogSource,
  params: CatalogFilterParams & {
    ownedHashes?: Map<number, number>;
    inventoryProjections?: Map<number, InventoryHashProjection>;
  },
): CatalogItem[] {
  const owned = params.ownedHashes ?? new Map<number, number>();
  const projections = params.inventoryProjections ?? new Map<number, InventoryHashProjection>();
  const includeLegendary = Boolean(params.setBonus?.trim() || params.armorHashAllowlist);
  let rows: SearchableCatalogRow[] = source.exoticArmor.map((a) => armorToCatalog(a, 0));
  if (includeLegendary && source.legendaryArmor) {
    rows = [
      ...rows,
      ...source.legendaryArmor.map((a) => legendaryArmorToCatalog(a, 0)),
    ];
  }

  const aggregated = aggregateOwnedCountsBySearchName(rows, owned, projections);
  applyAggregatedOwnedCounts(rows, aggregated);

  if (params.scope === "owned") {
    rows = rows.filter((row) => row.ownedCount > 0);
    for (const [hash, count] of owned) {
      if (isOwnedHashCoveredByRows(hash, count, rows, projections)) continue;
      rows.push(unknownOwnedRow(hash, count, projections.get(hash)));
    }
  }

  rows = applyFieldFilters(rows, params);
  rows = applyHashAllowlist(rows, params.armorHashAllowlist);
  rows = applySearch(rows, params.q);
  return finalize(rows, params.limit);
}
