import fs from "node:fs/promises";
import path from "node:path";

import { getBungieApiKey } from "../config/env";
import {
  currentVersionFilePath,
  entityCacheMetaPath,
  rawTablePath,
} from "./cachePaths";
import {
  RAW_TABLES,
  type ManifestService,
  type ManifestStatus,
  type RawTable,
  type RawTableName,
} from "./types/services";
import type { EntityCacheMeta } from "./types/stores";

const MANIFEST_URL = "https://www.bungie.net/Platform/Destiny2/Manifest/";
const BUNGIE_BASE_URL = "https://www.bungie.net";
const MISSING_API_KEY_MESSAGE =
  "BUNGIE_API_KEY environment variable is required to download manifest data";

interface BungieManifestServiceOptions {
  apiKey: string | null;
  fetchFn?: typeof fetch;
}

interface ManifestMetadata {
  version: string;
  tablePaths: Record<string, string>;
}

interface CurrentVersionFile {
  version: string;
}

function isNodeError(error: unknown): error is NodeJS.ErrnoException {
  return error instanceof Error && "code" in error;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isRawTable(value: unknown): value is RawTable {
  return isRecord(value);
}

function isCurrentVersionFile(value: unknown): value is CurrentVersionFile {
  return isRecord(value) && typeof value.version === "string";
}

function isEntityCacheMeta(value: unknown): value is EntityCacheMeta {
  if (!isRecord(value)) return false;
  if (typeof value.manifestVersion !== "string") return false;
  if (typeof value.builtAt !== "string") return false;
  return isRecord(value.counts);
}

function parseManifestResponse(json: unknown): ManifestMetadata {
  if (!isRecord(json) || !isRecord(json.Response)) {
    throw new Error("Unexpected Bungie manifest response shape");
  }

  const response = json.Response;
  if (typeof response.version !== "string") {
    throw new Error("Manifest response missing version");
  }

  const pathsRoot = response.jsonWorldComponentContentPaths;
  if (!isRecord(pathsRoot) || !isRecord(pathsRoot.en)) {
    throw new Error("Manifest response missing English table paths");
  }

  const tablePaths: Record<string, string> = {};
  for (const [tableName, tablePath] of Object.entries(pathsRoot.en)) {
    if (typeof tablePath === "string") {
      tablePaths[tableName] = tablePath;
    }
  }

  return { version: response.version, tablePaths };
}

async function readJsonFile(filePath: string): Promise<unknown | null> {
  try {
    const content = await fs.readFile(filePath, "utf-8");
    return JSON.parse(content) as unknown;
  } catch (error) {
    if (isNodeError(error) && error.code === "ENOENT") {
      return null;
    }
    return null;
  }
}

async function writeJsonFile(filePath: string, data: unknown): Promise<void> {
  await fs.mkdir(path.dirname(filePath), { recursive: true });
  await fs.writeFile(filePath, JSON.stringify(data), "utf-8");
}

async function fileExists(filePath: string): Promise<boolean> {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function readCurrentVersion(): Promise<string | null> {
  const json = await readJsonFile(currentVersionFilePath());
  if (!isCurrentVersionFile(json)) {
    return null;
  }
  return json.version;
}

async function readEntityCacheMeta(
  version: string,
): Promise<EntityCacheMeta | null> {
  const json = await readJsonFile(entityCacheMetaPath(version));
  if (!isEntityCacheMeta(json)) {
    return null;
  }
  return json;
}

function computeIsStale(
  cachedVersion: string | null,
  remoteVersion: string | null,
): boolean {
  if (cachedVersion === null) {
    return true;
  }
  if (remoteVersion === null) {
    return false;
  }
  return cachedVersion !== remoteVersion;
}

export class BungieManifestService implements ManifestService {
  private readonly apiKey: string | null;
  private readonly fetchFn: typeof fetch;

  constructor(options: BungieManifestServiceOptions) {
    this.apiKey = options.apiKey;
    this.fetchFn = options.fetchFn ?? fetch;
  }

  async getStatus(): Promise<ManifestStatus> {
    const cachedVersion = await readCurrentVersion();
    const remoteVersion = await this.fetchRemoteVersion();
    const entityCache =
      cachedVersion === null
        ? null
        : await readEntityCacheMeta(cachedVersion);

    return {
      cachedVersion,
      remoteVersion,
      isStale: computeIsStale(cachedVersion, remoteVersion),
      entityCache,
    };
  }

  async ensureCurrent(): Promise<string> {
    if (this.apiKey === null) {
      throw new Error(MISSING_API_KEY_MESSAGE);
    }

    const metadata = await this.fetchManifestMetadata(this.apiKey);
    await this.downloadMissingTables(metadata);
    await writeJsonFile(currentVersionFilePath(), {
      version: metadata.version,
    });
    return metadata.version;
  }

  async loadRawTable(
    version: string,
    table: RawTableName,
  ): Promise<RawTable> {
    const filePath = rawTablePath(version, table);

    let content: string;
    try {
      content = await fs.readFile(filePath, "utf-8");
    } catch (error) {
      if (isNodeError(error) && error.code === "ENOENT") {
        throw new Error(
          `Raw table "${table}" for version "${version}" is not on disk. Call ensureCurrent() to download manifest tables.`,
        );
      }
      throw error;
    }

    const parsed: unknown = JSON.parse(content);
    if (!isRawTable(parsed)) {
      throw new Error(
        `Raw table "${table}" for version "${version}" is not a valid JSON object.`,
      );
    }
    return parsed;
  }

  private async fetchRemoteVersion(): Promise<string | null> {
    if (this.apiKey === null) {
      return null;
    }

    try {
      const metadata = await this.fetchManifestMetadata(this.apiKey);
      return metadata.version;
    } catch {
      return null;
    }
  }

  private async fetchManifestMetadata(apiKey: string): Promise<ManifestMetadata> {
    const response = await this.fetchFn(MANIFEST_URL, {
      headers: { "X-API-Key": apiKey },
    });

    if (!response.ok) {
      throw new Error(`Manifest version check failed with status ${response.status}`);
    }

    const json: unknown = await response.json();
    return parseManifestResponse(json);
  }

  private async downloadMissingTables(metadata: ManifestMetadata): Promise<void> {
    const apiKey = this.apiKey;
    if (apiKey === null) {
      throw new Error(MISSING_API_KEY_MESSAGE);
    }

    for (const table of RAW_TABLES) {
      const destination = rawTablePath(metadata.version, table);
      if (await fileExists(destination)) {
        continue;
      }

      await this.downloadTable(apiKey, metadata, table, destination);
    }
  }

  private async downloadTable(
    apiKey: string,
    metadata: ManifestMetadata,
    table: RawTableName,
    destination: string,
  ): Promise<void> {
    const relativePath = metadata.tablePaths[table];
    if (!relativePath) {
      throw new Error(`Manifest response missing download path for ${table}`);
    }

    const url = `${BUNGIE_BASE_URL}${relativePath}`;
    const response = await this.fetchFn(url, {
      headers: { "X-API-Key": apiKey },
    });

    if (!response.ok) {
      throw new Error(
        `Failed to download ${table}: HTTP ${response.status}`,
      );
    }

    const json: unknown = await response.json();
    if (!isRawTable(json)) {
      throw new Error(`Downloaded ${table} is not a valid JSON object`);
    }

    await writeJsonFile(destination, json);
  }
}

export function createManifestService(): ManifestService {
  return new BungieManifestService({ apiKey: getBungieApiKey() });
}
