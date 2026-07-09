import Fuse, { type IFuseOptions } from "fuse.js";

import { normalizeName } from "./normalize";
import type {
  EntityCache,
  ItemResolver,
  ResolveResult,
} from "./types/services";
import type { EntityStores, StoreName } from "./types/stores";

type StoreRecord<TName extends StoreName> = EntityStores[TName][number];

type SearchableRecord = {
  hash: number;
  searchName: string;
  description?: string;
  intrinsicDescription?: string;
};

interface StoreIndex<TRecord> {
  exactMap: Map<string, TRecord>;
  fuse: Fuse<TRecord>;
}

const DEFAULT_FUSE_OPTIONS: IFuseOptions<SearchableRecord> = {
  keys: ["searchName"],
  includeScore: true,
  threshold: 0.35,
  ignoreLocation: true,
};

const DESCRIPTION_FUSE_OPTIONS: IFuseOptions<SearchableRecord> = {
  keys: ["searchName", "description"],
  includeScore: true,
  threshold: 0.35,
  ignoreLocation: true,
};

const EXOTIC_FUSE_OPTIONS: IFuseOptions<SearchableRecord> = {
  keys: ["searchName", "description", "intrinsicDescription"],
  includeScore: true,
  threshold: 0.35,
  ignoreLocation: true,
};

function fuseOptionsForStore(store: StoreName): IFuseOptions<SearchableRecord> {
  if (store === "exotic-weapons" || store === "exotic-armor") {
    return EXOTIC_FUSE_OPTIONS;
  }
  if (
    store === "mods" ||
    store === "aspects" ||
    store === "fragments" ||
    store === "artifacts" ||
    store === "abilities"
  ) {
    return DESCRIPTION_FUSE_OPTIONS;
  }
  return DEFAULT_FUSE_OPTIONS;
}

function toSearchableRecord(
  store: StoreName,
  record: StoreRecord<StoreName>,
): SearchableRecord {
  const searchName =
    "searchName" in record && typeof record.searchName === "string"
      ? record.searchName
      : "name" in record && typeof record.name === "string"
        ? normalizeName(record.name)
        : (() => {
            throw new Error("Record is missing a searchable name");
          })();

  const base: SearchableRecord = { hash: record.hash, searchName };

  if (store === "exotic-weapons" && "intrinsic" in record) {
    const exotic = record as EntityStores["exotic-weapons"][number];
    return {
      ...base,
      description: exotic.intrinsic.description,
      intrinsicDescription: exotic.intrinsic.description,
    };
  }

  if (store === "exotic-armor" && "intrinsic" in record) {
    const exotic = record as EntityStores["exotic-armor"][number];
    return {
      ...base,
      description: exotic.intrinsic.description,
      intrinsicDescription: exotic.intrinsic.description,
    };
  }

  if ("description" in record && typeof record.description === "string") {
    return { ...base, description: record.description };
  }

  return base;
}

function buildStoreIndex<TRecord extends SearchableRecord>(
  records: TRecord[],
  options: IFuseOptions<TRecord>,
): StoreIndex<TRecord> {
  const exactMap = new Map<string, TRecord>();
  for (const record of records) {
    exactMap.set(record.searchName, record);
  }
  return { exactMap, fuse: new Fuse(records, options) };
}

function fuseHitToResult<TRecord>(
  record: TRecord,
  score: number | undefined,
): ResolveResult<TRecord> | null {
  if (score === undefined) {
    return null;
  }
  return { record, confidence: 1 - score };
}

type LoadedStore<TName extends StoreName> = {
  searchable: SearchableRecord[];
  byHash: Map<number, StoreRecord<TName>>;
};

export class StoreItemResolver implements ItemResolver {
  private readonly indexes = new Map<
    StoreName,
    StoreIndex<SearchableRecord>
  >();
  private readonly recordsByStore = new Map<StoreName, LoadedStore<StoreName>>();

  constructor(private readonly cache: EntityCache) {}

  async resolve<TName extends StoreName>(
    store: TName,
    name: string,
  ): Promise<ResolveResult<StoreRecord<TName>> | null> {
    const normalized = normalizeName(name);
    if (!normalized) {
      return null;
    }

    const { index, byHash } = await this.loadStore(store);
    const exact = index.exactMap.get(normalized);
    if (exact) {
      const record = byHash.get(exact.hash);
      if (record) {
        return { record, confidence: 1 };
      }
    }

    const hits = index.fuse.search(normalized);
    if (hits.length === 0) {
      return null;
    }

    const record = byHash.get(hits[0].item.hash);
    if (!record) {
      return null;
    }

    const best = fuseHitToResult(record, hits[0].score);
    return best;
  }

  async search<TName extends StoreName>(
    store: TName,
    query: string,
    limit = 5,
  ): Promise<ResolveResult<StoreRecord<TName>>[]> {
    const normalized = normalizeName(query);
    if (!normalized) {
      return [];
    }

    const { index, byHash } = await this.loadStore(store);
    const ranked: ResolveResult<StoreRecord<TName>>[] = [];
    const seen = new Set<number>();

    const exact = index.exactMap.get(normalized);
    if (exact) {
      const record = byHash.get(exact.hash);
      if (record) {
        ranked.push({ record, confidence: 1 });
        seen.add(exact.hash);
      }
    }

    for (const hit of index.fuse.search(normalized)) {
      if (seen.has(hit.item.hash)) {
        continue;
      }
      const record = byHash.get(hit.item.hash);
      if (!record) {
        continue;
      }
      const result = fuseHitToResult(record, hit.score);
      if (!result) {
        continue;
      }
      ranked.push(result);
      seen.add(hit.item.hash);
      if (ranked.length >= limit) {
        break;
      }
    }

    return ranked.slice(0, limit);
  }

  private async loadStore<TName extends StoreName>(
    store: TName,
  ): Promise<{ index: StoreIndex<SearchableRecord>; byHash: Map<number, StoreRecord<TName>> }> {
    const cachedRecords = this.recordsByStore.get(store) as
      | LoadedStore<TName>
      | undefined;
    const cachedIndex = this.indexes.get(store);

    if (cachedRecords && cachedIndex) {
      return { index: cachedIndex, byHash: cachedRecords.byHash };
    }

    const records = await this.cache.getStore(store);
    const byHash = new Map<number, StoreRecord<TName>>();
    const searchable: SearchableRecord[] = [];

    for (const record of records) {
      byHash.set(record.hash, record);
      searchable.push(toSearchableRecord(store, record));
    }

    const index = buildStoreIndex(searchable, fuseOptionsForStore(store));
    this.indexes.set(store, index);
    this.recordsByStore.set(store, { searchable, byHash } as LoadedStore<StoreName>);

    return { index, byHash };
  }
}

export function createItemResolver(cache: EntityCache): ItemResolver {
  return new StoreItemResolver(cache);
}
