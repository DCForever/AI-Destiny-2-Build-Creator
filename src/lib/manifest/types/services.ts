/**
 * Service contracts for the manifest data layer. Implementations live in
 * sibling modules; consumers (LLM tools, API routes, validators) depend only
 * on these interfaces.
 */

import type { Hash } from "./records";
import type { EntityCacheMeta, EntityStores, StoreName } from "./stores";

/** Raw manifest tables we download (DestinyInventoryItemDefinition etc.). */
export const RAW_TABLES = [
  "DestinyInventoryItemDefinition",
  "DestinyStatDefinition",
  "DestinyPlugSetDefinition",
  "DestinySocketTypeDefinition",
  "DestinySocketCategoryDefinition",
  "DestinyDamageTypeDefinition",
  "DestinyInventoryBucketDefinition",
  "DestinyClassDefinition",
  "DestinySandboxPerkDefinition",
  "DestinyArtifactDefinition",
  "DestinyEquipmentSlotDefinition",
  "DestinyEquipableItemSetDefinition",
] as const;

export type RawTableName = (typeof RAW_TABLES)[number];

/** A raw table is a hash-keyed map of Bungie definition objects. */
export type RawTable = Record<string, unknown>;

export interface ManifestStatus {
  /** Version currently on disk, null if never downloaded. */
  cachedVersion: string | null;
  /** Latest version reported by Bungie, null if the check failed. */
  remoteVersion: string | null;
  isStale: boolean;
  entityCache: EntityCacheMeta | null;
}

/**
 * Stage 1: versioned download of raw manifest tables to
 * `.cache/manifest/<version>/<table>.json`. Only the extraction pipeline
 * reads raw tables; nothing on the request path does.
 */
export interface ManifestService {
  getStatus(): Promise<ManifestStatus>;
  /** Downloads tables for the latest version if missing. Returns version. */
  ensureCurrent(): Promise<string>;
  /** Loads one raw table for a downloaded version from disk. */
  loadRawTable(version: string, table: RawTableName): Promise<RawTable>;
}

/**
 * Stage 2: derived entity stores. `rebuild` runs every extractor against the
 * raw tables; `getStore` reads (and memoizes) a single store JSON.
 */
export interface EntityCache {
  getMeta(): Promise<EntityCacheMeta | null>;
  getStore<TName extends StoreName>(
    name: TName,
  ): Promise<EntityStores[TName]>;
  rebuild(version: string): Promise<EntityCacheMeta>;
}

/** One extractor projects raw tables into a single entity store. */
export interface Extractor<TName extends StoreName = StoreName> {
  store: TName;
  extract(
    loadTable: (table: RawTableName) => Promise<RawTable>,
  ): Promise<EntityStores[TName]>;
}

export interface ResolveResult<TRecord> {
  record: TRecord;
  /** 1 = exact normalized match; lower values are fuzzy matches. */
  confidence: number;
}

/**
 * Name-to-record resolution over the entity stores. Exact normalized match
 * first, then fuzzy fallback; null when nothing clears the threshold.
 */
export interface ItemResolver {
  resolve<TName extends StoreName>(
    store: TName,
    name: string,
  ): Promise<ResolveResult<EntityStores[TName][number]> | null>;
  /** Ranked fuzzy search, for the LLM `search_items` tool. */
  search<TName extends StoreName>(
    store: TName,
    query: string,
    limit?: number,
  ): Promise<ResolveResult<EntityStores[TName][number]>[]>;
}

export type PerkLegality =
  | { legal: true; column: number; curated: boolean }
  | { legal: false; reason: string };

export interface FragmentCountCheck {
  legal: boolean;
  capacity: number;
  requested: number;
}

/** Deterministic legality checks served from the entity cache. */
export interface PerkValidator {
  checkWeaponPerk(weaponHash: Hash, perkHash: Hash): Promise<PerkLegality>;
  checkArtifactPerk(artifactHash: Hash, perkHash: Hash): Promise<PerkLegality>;
  checkFragmentCount(
    aspectHashes: Hash[],
    fragmentCount: number,
  ): Promise<FragmentCountCheck>;
}
