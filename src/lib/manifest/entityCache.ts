import { readFile, writeFile, mkdir } from "node:fs/promises";
import path from "node:path";

import type { EntityCache } from "./types/services";
import type { RawTable, RawTableName } from "./types/services";
import type { EntityCacheMeta, EntityStores, StoreName } from "./types/stores";
import { STORE_NAMES } from "./types/stores";
import { entityStorePath, entityCacheMetaPath } from "./cachePaths";
import { EXTRACTORS } from "./extractors/index";
import { buildPerkWeaponIndex, writePerkWeaponIndex } from "./perkWeaponIndex";

// ─── Node error helper ────────────────────────────────────────────────────

function isNotFoundError(err: unknown): boolean {
  return (
    typeof err === "object" &&
    err !== null &&
    (err as NodeJS.ErrnoException).code === "ENOENT"
  );
}

// ─── FileEntityCache ──────────────────────────────────────────────────────

interface FileEntityCacheOptions {
  /** The manifest version whose stores to read, or null if none built yet. */
  version: string | null;
  /** Underlying loader that reads a raw table from disk for a given version. */
  loadRawTable: (table: RawTableName) => Promise<RawTable>;
}

export class FileEntityCache implements EntityCache {
  private version: string | null;
  private readonly loadRawTable: (table: RawTableName) => Promise<RawTable>;
  private readonly storeCache = new Map<StoreName, unknown>();

  constructor(opts: FileEntityCacheOptions) {
    this.version = opts.version;
    this.loadRawTable = opts.loadRawTable;
  }

  async getMeta(): Promise<EntityCacheMeta | null> {
    if (this.version == null) return null;
    const filePath = entityCacheMetaPath(this.version);
    try {
      const text = await readFile(filePath, "utf8");
      return JSON.parse(text) as EntityCacheMeta;
    } catch (err) {
      if (isNotFoundError(err)) return null;
      throw err;
    }
  }

  async getStore<TName extends StoreName>(name: TName): Promise<EntityStores[TName]> {
    const cached = this.storeCache.get(name);
    if (cached !== undefined) return cached as EntityStores[TName];

    if (this.version == null) {
      throw new Error(
        "EntityCache: no version is set — call rebuild() first or pass a version to the constructor",
      );
    }

    const filePath = entityStorePath(this.version, name);
    let text: string;
    try {
      text = await readFile(filePath, "utf8");
    } catch (err) {
      if (isNotFoundError(err)) {
        throw new Error(
          `EntityCache: store "${name}" not found at ${filePath} — run rebuild() first`,
        );
      }
      throw err;
    }

    const store = JSON.parse(text) as EntityStores[TName];
    this.storeCache.set(name, store);
    return store;
  }

  async rebuild(version: string): Promise<EntityCacheMeta> {
    const tableCache = new Map<RawTableName, RawTable>();

    const memoizedLoad = async (table: RawTableName): Promise<RawTable> => {
      const cached = tableCache.get(table);
      if (cached !== undefined) return cached;
      const raw = await this.loadRawTable(table);
      tableCache.set(table, raw);
      return raw;
    };

    const counts = Object.fromEntries(
      STORE_NAMES.map((n) => [n, 0]),
    ) as Record<StoreName, number>;

    const builtStores = {} as EntityStores;

    for (const extractor of EXTRACTORS) {
      const data = await extractor.extract(memoizedLoad);
      const filePath = entityStorePath(version, extractor.store);
      await mkdir(path.dirname(filePath), { recursive: true });
      await writeFile(filePath, JSON.stringify(data), "utf8");
      counts[extractor.store] = (data as unknown[]).length;
      (builtStores as unknown as Record<string, unknown>)[extractor.store] = data;
    }

    const perkIndex = buildPerkWeaponIndex(version, {
      weapons: builtStores.weapons ?? [],
      "exotic-weapons": builtStores["exotic-weapons"] ?? [],
      "weapon-perks": builtStores["weapon-perks"] ?? [],
    });
    await writePerkWeaponIndex(version, perkIndex);

    const meta: EntityCacheMeta = {
      manifestVersion: version,
      builtAt: new Date().toISOString(),
      counts,
    };

    const metaPath = entityCacheMetaPath(version);
    await mkdir(path.dirname(metaPath), { recursive: true });
    await writeFile(metaPath, JSON.stringify(meta), "utf8");

    this.version = version;
    this.storeCache.clear();

    return meta;
  }
}

// ─── Factory ──────────────────────────────────────────────────────────────

export function createEntityCache(opts: FileEntityCacheOptions): EntityCache {
  return new FileEntityCache(opts);
}
