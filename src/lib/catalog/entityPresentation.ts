/**
 * Resolve display presentation (name, icon, description, element) for game
 * entities from the derived entity cache. Server-side only.
 */

import { normalizeName } from "@/lib/manifest/normalize";
import type { EntityStores, StoreName } from "@/lib/manifest/types/stores";
import { getServices } from "@/lib/services";

/** Stores that can yield a usable UI presentation. */
export type PresentationStore = Exclude<StoreName, "stats">;

export const DEFAULT_HASH_STORES: readonly PresentationStore[] = [
  "weapons",
  "exotic-weapons",
  "exotic-armor",
  "weapon-perks",
  "origin-traits",
  "mods",
  "aspects",
  "fragments",
  "abilities",
  "artifacts",
  "set-bonuses",
] as const;

export const SUBCLASS_STORES: readonly PresentationStore[] = [
  "abilities",
  "aspects",
  "fragments",
] as const;

export type EntityRef =
  | { by: "hash"; hash: number; stores?: PresentationStore[] }
  | { by: "name"; name: string; stores: PresentationStore[] };

export type EntityPresentation = {
  hash: number | null;
  name: string;
  icon: string | null;
  description: string;
  element: string | null;
  kindLabel: string | null;
  /** Source store when resolved. */
  store: PresentationStore | null;
};

const KIND_LABEL: Partial<Record<PresentationStore, string>> = {
  weapons: "Weapon",
  "exotic-weapons": "Exotic weapon",
  "exotic-armor": "Exotic armor",
  "weapon-perks": "Weapon perk",
  "origin-traits": "Origin trait",
  mods: "Mod",
  aspects: "Aspect",
  fragments: "Fragment",
  abilities: "Ability",
  artifacts: "Artifact",
  "set-bonuses": "Armor set bonus",
};

function emptyPresentation(fallbackName: string): EntityPresentation {
  return {
    hash: null,
    name: fallbackName,
    icon: null,
    description: "",
    element: null,
    kindLabel: null,
    store: null,
  };
}

type AnyRecord = EntityStores[PresentationStore][number];

function recordDescription(
  store: PresentationStore,
  record: AnyRecord,
): string {
  if (store === "exotic-weapons") {
    const r = record as EntityStores["exotic-weapons"][number];
    return (
      r.intrinsic?.description?.trim() ||
      r.catalyst?.description?.trim() ||
      ""
    );
  }
  if (store === "exotic-armor") {
    const r = record as EntityStores["exotic-armor"][number];
    return r.intrinsic?.description?.trim() || "";
  }
  if (store === "weapons") {
    const r = record as EntityStores["weapons"][number];
    return r.frame?.trim()
      ? `${r.itemTypeName} · ${r.frame}`
      : (r.itemTypeName ?? "");
  }
  if (store === "artifacts") {
    const r = record as EntityStores["artifacts"][number];
    return r.description?.trim() ?? "";
  }
  if (store === "set-bonuses") {
    const r = record as EntityStores["set-bonuses"][number];
    const first = r.perks[0];
    return first?.description?.trim() ?? "";
  }
  if ("description" in record && typeof record.description === "string") {
    return record.description.trim();
  }
  return "";
}

function recordElement(
  store: PresentationStore,
  record: AnyRecord,
): string | null {
  if (
    store === "weapons" ||
    store === "exotic-weapons" ||
    store === "aspects" ||
    store === "fragments" ||
    store === "abilities"
  ) {
    const el = (record as { element?: string }).element;
    return el ?? null;
  }
  return null;
}

function fromRecord(
  store: PresentationStore,
  record: AnyRecord,
): EntityPresentation {
  return {
    hash: record.hash,
    name: record.name,
    icon: "icon" in record ? (record.icon ?? null) : null,
    description: recordDescription(store, record),
    element: recordElement(store, record),
    kindLabel: KIND_LABEL[store] ?? store,
    store,
  };
}

/** Nested artifact perk match (hash). */
function findArtifactPerk(
  artifacts: EntityStores["artifacts"],
  hash: number,
): EntityPresentation | null {
  for (const art of artifacts) {
    const perk = art.perks.find((p) => p.hash === hash);
    if (perk) {
      return {
        hash: perk.hash,
        name: perk.name,
        icon: perk.icon ?? null,
        description: perk.description?.trim() ?? "",
        element: null,
        kindLabel: "Artifact perk",
        store: "artifacts",
      };
    }
  }
  return null;
}

function findArtifactPerkByName(
  artifacts: EntityStores["artifacts"],
  search: string,
): EntityPresentation | null {
  for (const art of artifacts) {
    const perk = art.perks.find(
      (p) =>
        normalizeName(p.name) === search ||
        p.name.trim().toLowerCase() === search,
    );
    if (perk) {
      return {
        hash: perk.hash,
        name: perk.name,
        icon: perk.icon ?? null,
        description: perk.description?.trim() ?? "",
        element: null,
        kindLabel: "Artifact perk",
        store: "artifacts",
      };
    }
  }
  return null;
}

type StoreIndex = {
  byHash: Map<number, AnyRecord>;
  bySearchName: Map<string, AnyRecord>;
  records: AnyRecord[];
};

type LoadedIndexes = Partial<Record<PresentationStore, StoreIndex>>;

/** Reuse hash/name indexes when entityCache returns the same store array refs. */
const storeIndexCache = new WeakMap<AnyRecord[], StoreIndex>();

function indexStore(records: AnyRecord[]): StoreIndex {
  const cached = storeIndexCache.get(records);
  if (cached) return cached;
  const byHash = new Map<number, AnyRecord>();
  const bySearchName = new Map<string, AnyRecord>();
  for (const r of records) {
    byHash.set(r.hash, r);
    const sn =
      "searchName" in r && typeof r.searchName === "string"
        ? r.searchName
        : normalizeName(r.name);
    if (sn && !bySearchName.has(sn)) bySearchName.set(sn, r);
  }
  const index = { byHash, bySearchName, records };
  storeIndexCache.set(records, index);
  return index;
}

async function loadStores(
  names: readonly PresentationStore[],
): Promise<LoadedIndexes> {
  const { entityCache } = await getServices();
  const unique = [...new Set(names)];
  const pairs = await Promise.all(
    unique.map(async (name) => {
      const records = (await entityCache.getStore(name)) as AnyRecord[];
      return [name, indexStore(records)] as const;
    }),
  );
  return Object.fromEntries(pairs);
}

function lookupHash(
  loaded: LoadedIndexes,
  hash: number,
  stores: readonly PresentationStore[],
): EntityPresentation | null {
  for (const store of stores) {
    if (store === "artifacts") {
      const arts = loaded.artifacts;
      if (arts) {
        const top = arts.byHash.get(hash);
        if (top) return fromRecord("artifacts", top);
        const nested = findArtifactPerk(
          arts.records as EntityStores["artifacts"],
          hash,
        );
        if (nested) return nested;
      }
      continue;
    }
    const index = loaded[store];
    if (!index) continue;
    const match = index.byHash.get(hash);
    if (match) return fromRecord(store, match);
  }
  return null;
}

function lookupName(
  loaded: LoadedIndexes,
  name: string,
  stores: readonly PresentationStore[],
): EntityPresentation | null {
  const search = normalizeName(name);
  if (!search) return null;

  for (const store of stores) {
    if (store === "artifacts") {
      const arts = loaded.artifacts;
      if (arts) {
        const top = arts.bySearchName.get(search);
        if (top) return fromRecord("artifacts", top);
        const nested = findArtifactPerkByName(
          arts.records as EntityStores["artifacts"],
          search,
        );
        if (nested) return nested;
      }
      continue;
    }
    const index = loaded[store];
    if (!index) continue;
    const match = index.bySearchName.get(search);
    if (match) return fromRecord(store, match);
  }
  return null;
}

/**
 * Resolve one or many entity refs. Loads each needed store once per call.
 */
export async function resolveEntityPresentations(
  refs: EntityRef[],
): Promise<EntityPresentation[]> {
  if (refs.length === 0) return [];

  const storesNeeded = new Set<PresentationStore>();
  for (const ref of refs) {
    if (ref.by === "hash") {
      for (const s of ref.stores ?? DEFAULT_HASH_STORES) storesNeeded.add(s);
    } else {
      for (const s of ref.stores) storesNeeded.add(s);
    }
  }

  const loaded = await loadStores([...storesNeeded]);

  return refs.map((ref) => {
    if (ref.by === "hash") {
      const stores = ref.stores ?? DEFAULT_HASH_STORES;
      return (
        lookupHash(loaded, ref.hash, stores) ??
        emptyPresentation(`Unknown (${ref.hash})`)
      );
    }
    const hit = lookupName(loaded, ref.name, ref.stores);
    return hit ?? emptyPresentation(ref.name);
  });
}

export async function resolveEntityPresentation(
  ref: EntityRef,
): Promise<EntityPresentation> {
  const [one] = await resolveEntityPresentations([ref]);
  return one ?? emptyPresentation(ref.by === "name" ? ref.name : `Unknown`);
}

/** Convenience: batch resolve hashes. */
export async function presentByHashes(
  hashes: number[],
  stores?: PresentationStore[],
): Promise<Map<number, EntityPresentation>> {
  const unique = [...new Set(hashes.filter((h) => Number.isFinite(h)))];
  const results = await resolveEntityPresentations(
    unique.map((hash) => ({ by: "hash" as const, hash, stores })),
  );
  const map = new Map<number, EntityPresentation>();
  unique.forEach((hash, i) => {
    map.set(hash, results[i]!);
  });
  return map;
}

/** Convenience: batch resolve names against given stores. */
export async function presentByNames(
  names: string[],
  stores: PresentationStore[],
): Promise<Map<string, EntityPresentation>> {
  const unique = [
    ...new Set(names.map((n) => n.trim()).filter(Boolean)),
  ];
  const results = await resolveEntityPresentations(
    unique.map((name) => ({ by: "name" as const, name, stores })),
  );
  const map = new Map<string, EntityPresentation>();
  unique.forEach((name, i) => {
    map.set(name, results[i]!);
    map.set(normalizeName(name), results[i]!);
  });
  return map;
}
