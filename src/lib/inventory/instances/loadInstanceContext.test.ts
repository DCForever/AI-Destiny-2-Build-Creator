import { describe, expect, it, vi } from "vitest";

import type { EntityCache, ManifestService } from "@/lib/manifest/types/services";
import type { EntityStores, StoreName } from "@/lib/manifest/types/stores";

import { ringingNailManifestPlugs, ringingNailRollPlugs } from "./__fixtures__/plugFixtures";
import { buildPlugMapForInventory } from "./loadInstanceContext";

function createFakeCache(stores: Partial<EntityStores>): EntityCache {
  return {
    getMeta: async () => null,
    rebuild: async () => {
      throw new Error("not implemented in tests");
    },
    getStore: async <TName extends StoreName>(name: TName) => {
      const store = stores[name];
      if (!store) {
        throw new Error(`missing fixture store: ${name}`);
      }
      return store as EntityStores[TName];
    },
  };
}

function createFakeManifest(names: Record<number, string>): ManifestService {
  return {
    getStatus: async () => ({ cachedVersion: "test-version" }),
    loadRawTable: async () => {
      const table: Record<string, unknown> = {};
      for (const [hash, name] of Object.entries(names)) {
        table[String(hash)] = {
          hash: Number(hash),
          displayProperties: { name, icon: "" },
          redacted: false,
        };
      }
      return table;
    },
  } as unknown as ManifestService;
}

describe("buildPlugMapForInventory", () => {
  const entityCache = createFakeCache({
    "weapon-perks": Object.entries(ringingNailRollPlugs).map(([hash, name]) => ({
      hash: Number(hash),
      name,
      searchName: name.toLowerCase(),
      icon: null,
      description: "",
    })),
    mods: [],
    "origin-traits": [],
  });

  it("merges entity stores with manifest fallback for unresolved plug hashes", async () => {
    const manifest = createFakeManifest(ringingNailManifestPlugs);
    const plugHashes = [
      ...Object.keys(ringingNailManifestPlugs).map(Number),
      ...Object.keys(ringingNailRollPlugs).map(Number),
    ];

    const map = await buildPlugMapForInventory(
      entityCache,
      manifest,
      "test-version",
      plugHashes,
    );

    expect(map.get(3634656993)).toBe("Synergy");
    expect(map.get(1636108362)).toBe("Precision Frame");
    expect(map.get(1001)).toBe("Fluted Barrel");
  });

  it("returns entity map only when manifest version is missing", async () => {
    const manifest = createFakeManifest(ringingNailManifestPlugs);
    const map = await buildPlugMapForInventory(entityCache, manifest, null, [1636108362]);

    expect(map.get(1001)).toBe("Fluted Barrel");
    expect(map.has(1636108362)).toBe(false);
  });

  it("skips manifest lookup when all plug hashes resolve from entity stores", async () => {
    const loadRawTable = vi.fn();
    const manifest = {
      getStatus: async () => ({ cachedVersion: "test-version" }),
      loadRawTable,
    } as unknown as ManifestService;

    const map = await buildPlugMapForInventory(entityCache, manifest, "test-version", [1001]);

    expect(map.get(1001)).toBe("Fluted Barrel");
    expect(loadRawTable).not.toHaveBeenCalled();
  });
});
