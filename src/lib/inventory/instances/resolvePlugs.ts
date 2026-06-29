import type { ResolvedPlug } from "./types";

type PlugStoreRecord = { hash: number; name: string };

type PlugStores = {
  "weapon-perks"?: PlugStoreRecord[];
  mods?: PlugStoreRecord[];
  "origin-traits"?: PlugStoreRecord[];
};

export function buildPlugNameMap(stores: PlugStores): Map<number, string> {
  const map = new Map<number, string>();
  for (const store of [
    stores["weapon-perks"] ?? [],
    stores.mods ?? [],
    stores["origin-traits"] ?? [],
  ]) {
    for (const record of store) {
      map.set(record.hash, record.name);
    }
  }
  return map;
}

export function mergeManifestPlugNames(
  entityMap: Map<number, string>,
  manifestMap: Map<number, string>,
): Map<number, string> {
  const merged = new Map(entityMap);
  for (const [hash, name] of manifestMap) {
    if (!merged.has(hash)) {
      merged.set(hash, name);
    }
  }
  return merged;
}

export function resolvePlugs(plugHashes: number[], plugMap: Map<number, string>): ResolvedPlug[] {
  return plugHashes.map((hash) => {
    const name = plugMap.get(hash) ?? null;
    return {
      hash,
      name,
      displayName: name ?? String(hash),
      resolved: name !== null,
    };
  });
}
