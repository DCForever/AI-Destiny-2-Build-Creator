import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import type { RawTableName } from "./types/services";
import { RAW_TABLES } from "./types/services";
import type { EntityCacheMeta } from "./types/stores";

const { cacheState } = vi.hoisted(() => ({
  cacheState: { root: "" },
}));

vi.mock("./cachePaths", async () => {
  const nodePath = await import("node:path");

  function versionToDirName(version: string): string {
    return version.replace(/[^a-zA-Z0-9._-]+/g, "_");
  }

  return {
    versionToDirName,
    rawTablePath: (version: string, table: RawTableName) =>
      nodePath.join(
        cacheState.root,
        "manifest",
        versionToDirName(version),
        `${table}.json`,
      ),
    entityCacheMetaPath: (version: string) =>
      nodePath.join(
        cacheState.root,
        "entities",
        versionToDirName(version),
        "meta.json",
      ),
    currentVersionFilePath: () =>
      nodePath.join(cacheState.root, "current-version.json"),
  };
});

import {
  currentVersionFilePath,
  entityCacheMetaPath,
  rawTablePath,
} from "./cachePaths";
import { BungieManifestService } from "./manifestService";

const MANIFEST_URL = "https://www.bungie.net/Platform/Destiny2/Manifest/";
const TEST_VERSION = "test.manifest.version";
const OTHER_VERSION = "other.manifest.version";
const TABLE_FIXTURE = { "123": { hash: 123 } };

function buildManifestResponse(version: string) {
  const en: Record<string, string> = {};
  for (const table of RAW_TABLES) {
    en[table] = `/common/destiny2/content/json/en/${table}.json`;
  }

  return {
    Response: {
      version,
      jsonWorldComponentContentPaths: { en },
    },
  };
}

function createTableFetchMock(version: string) {
  return vi.fn(async (input: RequestInfo | URL) => {
    const url = String(input);

    if (url === MANIFEST_URL) {
      return new Response(JSON.stringify(buildManifestResponse(version)), {
        status: 200,
      });
    }

    for (const table of RAW_TABLES) {
      if (url.endsWith(`${table}.json`)) {
        return new Response(JSON.stringify(TABLE_FIXTURE), { status: 200 });
      }
    }

    return new Response("not found", { status: 404 });
  });
}

async function writeCurrentVersion(version: string): Promise<void> {
  const filePath = currentVersionFilePath();
  await fs.mkdir(path.dirname(filePath), { recursive: true });
  await fs.writeFile(filePath, JSON.stringify({ version }), "utf-8");
}

async function writeTableFile(
  version: string,
  table: RawTableName,
  data: unknown = TABLE_FIXTURE,
): Promise<void> {
  const filePath = rawTablePath(version, table);
  await fs.mkdir(path.dirname(filePath), { recursive: true });
  await fs.writeFile(filePath, JSON.stringify(data), "utf-8");
}

describe("BungieManifestService", () => {
  let tempDir: string;

  beforeEach(async () => {
    tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "manifest-service-"));
    cacheState.root = tempDir;
  });

  afterEach(async () => {
    await fs.rm(tempDir, { recursive: true, force: true });
    vi.restoreAllMocks();
  });

  it("ensureCurrent downloads all RAW_TABLES and writes the version file", async () => {
    const fetchFn = createTableFetchMock(TEST_VERSION);
    const service = new BungieManifestService({
      apiKey: "test-api-key",
      fetchFn,
    });

    const version = await service.ensureCurrent();

    expect(version).toBe(TEST_VERSION);
    expect(fetchFn).toHaveBeenCalledTimes(1 + RAW_TABLES.length);

    for (const table of RAW_TABLES) {
      const filePath = rawTablePath(TEST_VERSION, table);
      const content = JSON.parse(await fs.readFile(filePath, "utf-8")) as unknown;
      expect(content).toEqual(TABLE_FIXTURE);
    }

    const versionFile = JSON.parse(
      await fs.readFile(currentVersionFilePath(), "utf-8"),
    ) as { version: string };
    expect(versionFile.version).toBe(TEST_VERSION);
  });

  it("ensureCurrent skips tables already on disk", async () => {
    for (const table of RAW_TABLES) {
      await writeTableFile(TEST_VERSION, table);
    }

    const fetchFn = createTableFetchMock(TEST_VERSION);
    const service = new BungieManifestService({
      apiKey: "test-api-key",
      fetchFn,
    });

    const version = await service.ensureCurrent();

    expect(version).toBe(TEST_VERSION);
    expect(fetchFn).toHaveBeenCalledTimes(1);
  });

  it("ensureCurrent throws without apiKey", async () => {
    const service = new BungieManifestService({ apiKey: null });

    await expect(service.ensureCurrent()).rejects.toThrow("BUNGIE_API_KEY");
  });

  it("getStatus reports isStale=true when versions differ", async () => {
    await writeCurrentVersion(TEST_VERSION);

    const fetchFn = createTableFetchMock(OTHER_VERSION);
    const service = new BungieManifestService({
      apiKey: "test-api-key",
      fetchFn,
    });

    const status = await service.getStatus();

    expect(status.cachedVersion).toBe(TEST_VERSION);
    expect(status.remoteVersion).toBe(OTHER_VERSION);
    expect(status.isStale).toBe(true);
  });

  it("getStatus reports isStale=true when nothing is cached", async () => {
    const fetchFn = createTableFetchMock(TEST_VERSION);
    const service = new BungieManifestService({
      apiKey: "test-api-key",
      fetchFn,
    });

    const status = await service.getStatus();

    expect(status.cachedVersion).toBeNull();
    expect(status.remoteVersion).toBe(TEST_VERSION);
    expect(status.isStale).toBe(true);
  });

  it("getStatus reports isStale=false when versions match", async () => {
    await writeCurrentVersion(TEST_VERSION);

    const fetchFn = createTableFetchMock(TEST_VERSION);
    const service = new BungieManifestService({
      apiKey: "test-api-key",
      fetchFn,
    });

    const status = await service.getStatus();

    expect(status.cachedVersion).toBe(TEST_VERSION);
    expect(status.remoteVersion).toBe(TEST_VERSION);
    expect(status.isStale).toBe(false);
  });

  it("getStatus returns remoteVersion null when fetch rejects", async () => {
    const fetchFn = vi.fn().mockRejectedValue(new Error("network down"));
    const service = new BungieManifestService({
      apiKey: "test-api-key",
      fetchFn,
    });

    const status = await service.getStatus();

    expect(status.remoteVersion).toBeNull();
    expect(status.cachedVersion).toBeNull();
    expect(status.isStale).toBe(true);
  });

  it("getStatus returns entity cache meta when present", async () => {
    await writeCurrentVersion(TEST_VERSION);

    const meta: EntityCacheMeta = {
      manifestVersion: TEST_VERSION,
      builtAt: "2026-06-12T00:00:00.000Z",
      counts: {
        "exotic-armor": 1,
        "exotic-weapons": 2,
        weapons: 3,
        "weapon-perks": 4,
        "origin-traits": 5,
        artifacts: 6,
        aspects: 7,
        fragments: 8,
        abilities: 9,
        mods: 10,
        "set-bonuses": 11,
        stats: 12,
      },
    };

    const metaPath = entityCacheMetaPath(TEST_VERSION);
    await fs.mkdir(path.dirname(metaPath), { recursive: true });
    await fs.writeFile(metaPath, JSON.stringify(meta), "utf-8");

    const fetchFn = createTableFetchMock(TEST_VERSION);
    const service = new BungieManifestService({
      apiKey: "test-api-key",
      fetchFn,
    });

    const status = await service.getStatus();

    expect(status.entityCache).toEqual(meta);
  });

  it("loadRawTable round-trips written JSON", async () => {
    const table = RAW_TABLES[0];
    await writeTableFile(TEST_VERSION, table, TABLE_FIXTURE);

    const service = new BungieManifestService({ apiKey: "test-api-key" });
    const loaded = await service.loadRawTable(TEST_VERSION, table);

    expect(loaded).toEqual(TABLE_FIXTURE);
  });

  it("loadRawTable memoizes parsed tables within a service instance", async () => {
    const table = RAW_TABLES[0];
    await writeTableFile(TEST_VERSION, table, TABLE_FIXTURE);
    const service = new BungieManifestService({ apiKey: "test-api-key" });

    const a = await service.loadRawTable(TEST_VERSION, table);
    const b = await service.loadRawTable(TEST_VERSION, table);
    expect(a).toBe(b);
  });

  it("loadRawTable can disable memoization", async () => {
    const table = RAW_TABLES[0];
    await writeTableFile(TEST_VERSION, table, TABLE_FIXTURE);
    const service = new BungieManifestService({
      apiKey: "test-api-key",
      cacheRawTables: false,
    });

    const a = await service.loadRawTable(TEST_VERSION, table);
    const b = await service.loadRawTable(TEST_VERSION, table);
    expect(a).toEqual(b);
    expect(a).not.toBe(b);
  });

  it("loadRawTable throws when the table file is missing", async () => {
    const service = new BungieManifestService({ apiKey: "test-api-key" });

    await expect(
      service.loadRawTable(TEST_VERSION, RAW_TABLES[0]),
    ).rejects.toThrow("ensureCurrent()");
  });
});
