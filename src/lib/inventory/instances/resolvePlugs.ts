import type { ResolvedPlug } from "./types";

export type PlugPresentation = {
  name: string;
  icon: string | null;
  description: string;
};

type PlugStoreRecord = {
  hash: number;
  name: string;
  icon?: string | null;
  description?: string;
};

type PlugStores = {
  "weapon-perks"?: PlugStoreRecord[];
  mods?: PlugStoreRecord[];
  "origin-traits"?: PlugStoreRecord[];
};

/** Map of plug hash → display name (legacy callers / tests). */
export function buildPlugNameMap(stores: PlugStores): Map<number, string> {
  const map = new Map<number, string>();
  for (const [hash, p] of buildPlugPresentationMap(stores)) {
    map.set(hash, p.name);
  }
  return map;
}

export function buildPlugPresentationMap(
  stores: PlugStores,
): Map<number, PlugPresentation> {
  const map = new Map<number, PlugPresentation>();
  for (const store of [
    stores["weapon-perks"] ?? [],
    stores.mods ?? [],
    stores["origin-traits"] ?? [],
  ]) {
    for (const record of store) {
      map.set(record.hash, {
        name: record.name,
        icon: record.icon ?? null,
        description: record.description?.trim() ?? "",
      });
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

export function mergeManifestPlugPresentation(
  entityMap: Map<number, PlugPresentation>,
  manifestMap: Map<number, string>,
): Map<number, PlugPresentation> {
  const merged = new Map(entityMap);
  for (const [hash, name] of manifestMap) {
    if (!merged.has(hash)) {
      merged.set(hash, { name, icon: null, description: "" });
    }
  }
  return merged;
}

export type PlugLookup = Map<number, string> | Map<number, PlugPresentation>;

function lookupPlug(
  plugMap: PlugLookup,
  hash: number,
): PlugPresentation | null {
  const raw = plugMap.get(hash);
  if (raw == null) return null;
  if (typeof raw === "string") {
    return { name: raw, icon: null, description: "" };
  }
  return raw;
}

/** Resolve display name from either string or presentation maps. */
export function plugNameFromMap(
  plugMap: PlugLookup,
  hash: number,
): string | null {
  return lookupPlug(plugMap, hash)?.name ?? null;
}

/** Full presentation when available (icon + description). */
export function plugPresentationFromMap(
  plugMap: PlugLookup,
  hash: number,
): PlugPresentation | null {
  return lookupPlug(plugMap, hash);
}

export function resolvePlugs(
  plugHashes: number[],
  plugMap: PlugLookup,
): ResolvedPlug[] {
  return plugHashes.map((hash) => {
    const p = lookupPlug(plugMap, hash);
    return {
      hash,
      name: p?.name ?? null,
      displayName: p?.name ?? String(hash),
      resolved: p != null,
      icon: p?.icon ?? null,
      description: p?.description ?? "",
    };
  });
}
