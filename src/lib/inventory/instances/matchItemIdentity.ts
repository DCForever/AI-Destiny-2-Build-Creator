import { resolveInventoryHashProjections } from "@/lib/catalog/inventoryHashProjections";
import type { EntityCache, ManifestService } from "@/lib/manifest/types/services";

const ENTITY_STORES = ["weapons", "exotic-weapons", "exotic-armor"] as const;

export async function resolveCatalogItemSearchName(
  itemHash: number,
  entityCache: EntityCache,
  manifest: ManifestService,
  version: string | null,
): Promise<string | null> {
  for (const store of ENTITY_STORES) {
    const records = await entityCache.getStore(store);
    const match = records.find((record) => record.hash === itemHash);
    if (match) return match.searchName;
  }

  if (!version) return null;
  const projections = await resolveInventoryHashProjections(manifest, version, [itemHash]);
  return projections.get(itemHash)?.searchName ?? null;
}

export async function buildInventorySearchNameMap(
  itemHashes: number[],
  entityCache: EntityCache,
  manifest: ManifestService,
  version: string | null,
): Promise<Map<number, string>> {
  const map = new Map<number, string>();
  const hashSet = new Set(itemHashes);
  const unresolved: number[] = [];

  for (const store of ENTITY_STORES) {
    const records = await entityCache.getStore(store);
    for (const record of records) {
      if (hashSet.has(record.hash)) {
        map.set(record.hash, record.searchName);
      }
    }
  }

  for (const hash of itemHashes) {
    if (!map.has(hash)) unresolved.push(hash);
  }

  if (unresolved.length > 0 && version) {
    const projections = await resolveInventoryHashProjections(manifest, version, unresolved);
    for (const [hash, projection] of projections) {
      map.set(hash, projection.searchName);
    }
  }

  return map;
}

export function itemMatchesCatalogIdentity(
  itemHash: number,
  criteria: { itemHash?: number; itemSearchName?: string | null },
  inventorySearchNames: Map<number, string>,
): boolean {
  if (criteria.itemHash === undefined) return true;
  if (itemHash === criteria.itemHash) return true;
  const targetName = criteria.itemSearchName;
  if (targetName && inventorySearchNames.get(itemHash) === targetName) return true;
  return false;
}
