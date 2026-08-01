/**
 * Single source of truth for on-disk cache locations, so the manifest
 * service, entity cache, and extractors never disagree about layout:
 *
 *   .cache/manifest/<version>/<RawTableName>.json   raw Bungie tables
 *   .cache/entities/<version>/<StoreName>.json      derived entity stores
 *   .cache/entities/<version>/meta.json             EntityCacheMeta sidecar
 */

import path from "node:path";

import type { RawTableName } from "./types/services";
import type { StoreName } from "./types/stores";

const CACHE_ROOT = path.join(process.cwd(), ".cache");

/** Manifest versions can contain characters unsafe in directory names. */
export function versionToDirName(version: string): string {
  return version.replace(/[^a-zA-Z0-9._-]+/g, "_");
}

export function rawTablePath(version: string, table: RawTableName): string {
  return path.join(
    CACHE_ROOT,
    "manifest",
    versionToDirName(version),
    `${table}.json`,
  );
}

export function entityStorePath(version: string, store: StoreName): string {
  return path.join(
    CACHE_ROOT,
    "entities",
    versionToDirName(version),
    `${store}.json`,
  );
}

export function entityCacheMetaPath(version: string): string {
  return path.join(
    CACHE_ROOT,
    "entities",
    versionToDirName(version),
    "meta.json",
  );
}

export function perkWeaponIndexPath(version: string): string {
  return path.join(
    CACHE_ROOT,
    "entities",
    versionToDirName(version),
    "perk-weapon-index.json",
  );
}

export function appDbPath(): string {
  return path.join(CACHE_ROOT, "app.db");
}

export function userPreferencesPath(bungieMembershipId: string): string {
  return path.join(CACHE_ROOT, "users", bungieMembershipId, "preferences.json");
}

/** Tracks which version's stores are current, for cheap status checks. */
export function currentVersionFilePath(): string {
  return path.join(CACHE_ROOT, "current-version.json");
}
