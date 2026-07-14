/**
 * Single source of truth for on-disk cache locations, so the manifest
 * service, entity cache, and extractors never disagree about layout:
 *
 *   <cacheRoot>/manifest/<version>/<RawTableName>.json   raw Bungie tables
 *   <cacheRoot>/entities/<version>/<StoreName>.json      derived entity stores
 *   <cacheRoot>/entities/<version>/meta.json             EntityCacheMeta sidecar
 *
 * Default root is `<cwd>/.cache`. Packaged desktop builds set
 * `D2BC_CACHE_ROOT` to the Electron userData directory (see
 * docs/packaging-desktop.md).
 */

import path from "node:path";

import type { RawTableName } from "./types/services";
import type { StoreName } from "./types/stores";

/** Optional absolute/relative override for packaged installs. */
export const CACHE_ROOT_ENV = "D2BC_CACHE_ROOT";

/** Resolves the on-disk cache root (evaluated at call time so env can vary in tests). */
export function getCacheRoot(): string {
  const fromEnv = process.env[CACHE_ROOT_ENV]?.trim();
  if (fromEnv) {
    return path.resolve(fromEnv);
  }
  return path.join(process.cwd(), ".cache");
}

/** Manifest versions can contain characters unsafe in directory names. */
export function versionToDirName(version: string): string {
  return version.replace(/[^a-zA-Z0-9._-]+/g, "_");
}

export function rawTablePath(version: string, table: RawTableName): string {
  return path.join(
    getCacheRoot(),
    "manifest",
    versionToDirName(version),
    `${table}.json`,
  );
}

export function entityStorePath(version: string, store: StoreName): string {
  return path.join(
    getCacheRoot(),
    "entities",
    versionToDirName(version),
    `${store}.json`,
  );
}

export function entityCacheMetaPath(version: string): string {
  return path.join(
    getCacheRoot(),
    "entities",
    versionToDirName(version),
    "meta.json",
  );
}

export function perkWeaponIndexPath(version: string): string {
  return path.join(
    getCacheRoot(),
    "entities",
    versionToDirName(version),
    "perk-weapon-index.json",
  );
}

export function appDbPath(): string {
  return path.join(getCacheRoot(), "app.db");
}

export function userPreferencesPath(bungieMembershipId: string): string {
  return path.join(getCacheRoot(), "users", bungieMembershipId, "preferences.json");
}

/** Tracks which version's stores are current, for cheap status checks. */
export function currentVersionFilePath(): string {
  return path.join(getCacheRoot(), "current-version.json");
}
