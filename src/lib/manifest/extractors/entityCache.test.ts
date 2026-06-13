/**
 * Integration tests for FileEntityCache: rebuild, getStore, getMeta, memoization.
 */

import { describe, it, expect, vi, beforeAll, afterAll, beforeEach } from "vitest";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";

import { RAW_TABLES } from "../__fixtures__/rawTables";
import type { RawTableName } from "../types/services";

// ─── Mock cachePaths ─────────────────────────────────────────────────────
// The variable is module-level so mock closures capture it by reference.
let tmpDir = "";

vi.mock("../cachePaths", () => ({
  versionToDirName: (v: string) => v.replace(/[^a-zA-Z0-9._-]+/g, "_"),
  entityStorePath: (v: string, s: string) =>
    path.join(tmpDir, `${v.replace(/[^a-zA-Z0-9._-]+/g, "_")}-${s}.json`),
  entityCacheMetaPath: (v: string) =>
    path.join(tmpDir, `${v.replace(/[^a-zA-Z0-9._-]+/g, "_")}-meta.json`),
  perkWeaponIndexPath: (v: string) =>
    path.join(tmpDir, `${v.replace(/[^a-zA-Z0-9._-]+/g, "_")}-perk-index.json`),
  rawTablePath: (v: string, t: string) =>
    path.join(tmpDir, `raw-${v}-${t}.json`),
  currentVersionFilePath: () => path.join(tmpDir, "current-version.json"),
}));

// ─── FileEntityCache (imported after mock is registered) ─────────────────
import { FileEntityCache } from "../entityCache";

// ─── Test setup ───────────────────────────────────────────────────────────

beforeAll(async () => {
  tmpDir = await mkdtemp(path.join(tmpdir(), "entity-cache-test-"));
});

afterAll(async () => {
  await rm(tmpDir, { recursive: true, force: true });
});

function makeLoader() {
  return async (table: RawTableName) => RAW_TABLES[table];
}

function makeCache(version: string | null = null) {
  return new FileEntityCache({ version, loadRawTable: makeLoader() });
}

// ─── Tests ────────────────────────────────────────────────────────────────

describe("FileEntityCache.getMeta", () => {
  it("returns null when version is null", async () => {
    const cache = makeCache(null);
    expect(await cache.getMeta()).toBeNull();
  });

  it("returns null when no meta file exists", async () => {
    const cache = makeCache("no-such-version");
    expect(await cache.getMeta()).toBeNull();
  });
});

describe("FileEntityCache.rebuild", () => {
  const VERSION = "test-1.0";

  it("writes meta and returns it", async () => {
    const cache = makeCache();
    const meta = await cache.rebuild(VERSION);
    expect(meta.manifestVersion).toBe(VERSION);
    expect(meta.builtAt).toBeTruthy();
    expect(typeof meta.counts["exotic-armor"]).toBe("number");
  });

  it("meta counts match fixture sizes", async () => {
    const cache = makeCache();
    const meta = await cache.rebuild(VERSION);
    expect(meta.counts["exotic-armor"]).toBe(1);
    expect(meta.counts["exotic-weapons"]).toBe(1);
    expect(meta.counts.weapons).toBe(1);
    expect(meta.counts["weapon-perks"]).toBe(4);
    expect(meta.counts["origin-traits"]).toBe(1);
    expect(meta.counts.artifacts).toBe(1);
    expect(meta.counts.aspects).toBe(2);
    expect(meta.counts.fragments).toBe(2);
    expect(meta.counts.abilities).toBe(5);
    expect(meta.counts.mods).toBe(3);
    expect(meta.counts["set-bonuses"]).toBe(1);
    expect(meta.counts.stats).toBe(7);
  });

  it("meta is persisted to disk and getMeta() reads it back", async () => {
    const cache = makeCache();
    await cache.rebuild(VERSION);
    const meta = await cache.getMeta();
    expect(meta?.manifestVersion).toBe(VERSION);
  });
});

describe("FileEntityCache.getStore", () => {
  const VERSION = "test-store";

  beforeEach(async () => {
    const cache = makeCache();
    await cache.rebuild(VERSION);
  });

  it("returns the exotic-armor store after rebuild", async () => {
    const cache = makeCache(VERSION);
    const store = await cache.getStore("exotic-armor");
    expect(store).toHaveLength(1);
    expect(store[0].name).toBe("Celestial Nighthawk");
  });

  it("memoizes: second getStore call returns the same array reference", async () => {
    const cache = makeCache(VERSION);
    const store1 = await cache.getStore("exotic-armor");
    const store2 = await cache.getStore("exotic-armor");
    // Object identity — no re-parse, same reference
    expect(store1).toBe(store2);
  });

  it("throws descriptive error when store is missing", async () => {
    const cache = makeCache("nonexistent-version");
    await expect(cache.getStore("exotic-armor")).rejects.toThrow(
      /store "exotic-armor" not found/,
    );
  });

  it("throws when version is null", async () => {
    const cache = makeCache(null);
    await expect(cache.getStore("stats")).rejects.toThrow(/no version/i);
  });
});

describe("FileEntityCache raw-table memoization during rebuild", () => {
  it("loads DestinyInventoryItemDefinition only once across all extractors", async () => {
    const callCounts: Partial<Record<RawTableName, number>> = {};
    const countingLoader = async (table: RawTableName) => {
      callCounts[table] = (callCounts[table] ?? 0) + 1;
      return RAW_TABLES[table];
    };

    const cache = new FileEntityCache({ version: null, loadRawTable: countingLoader });
    await cache.rebuild("memoize-test");

    expect(callCounts["DestinyInventoryItemDefinition"]).toBe(1);
  });
});
