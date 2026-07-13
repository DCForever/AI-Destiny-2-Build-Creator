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
    loadRawTable: async (version: string, table: string) => {
      void version;
      if (table === "DestinySandboxPerkDefinition") {
        return {};
      }
      const out: Record<string, unknown> = {};
      for (const [hash, name] of Object.entries(names)) {
        out[String(hash)] = {
          hash: Number(hash),
          displayProperties: {
            name,
            description: `Desc for ${name}`,
            icon: `/icon/${hash}.png`,
          },
          redacted: false,
        };
      }
      return out;
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

    expect(map.get(3634656993)?.name).toBe("Synergy");
    expect(map.get(1636108362)?.name).toBe("Precision Frame");
    expect(map.get(1636108362)?.icon).toBe("/icon/1636108362.png");
    expect(map.get(1636108362)?.description).toContain("Precision Frame");
    expect(map.get(1001)?.name).toBe("Fluted Barrel");
  });

  it("returns entity map only when manifest version is missing", async () => {
    const manifest = createFakeManifest(ringingNailManifestPlugs);
    const map = await buildPlugMapForInventory(entityCache, manifest, null, [
      1636108362,
    ]);

    // Entity-known plug remains; unresolved hash not filled without version
    expect(map.get(1001)?.name).toBe("Fluted Barrel");
    expect(map.has(1636108362)).toBe(false);
  });

  it("fills missing icon/description from manifest even when name is known", async () => {
    const loadRawTable = vi.fn(async (_v: string, table: string) => {
      if (table === "DestinySandboxPerkDefinition") return {};
      return {
        "1001": {
          hash: 1001,
          displayProperties: {
            name: "Fluted Barrel",
            description: "Greatly improved handling.",
            icon: "/flute.png",
          },
          redacted: false,
        },
      };
    });
    const manifest = {
      getStatus: async () => ({ cachedVersion: "test-version" }),
      loadRawTable,
    } as unknown as ManifestService;

    const map = await buildPlugMapForInventory(
      entityCache,
      manifest,
      "test-version",
      [1001],
    );

    expect(map.get(1001)?.name).toBe("Fluted Barrel");
    expect(map.get(1001)?.icon).toBe("/flute.png");
    expect(map.get(1001)?.description).toContain("handling");
    expect(loadRawTable).toHaveBeenCalled();
  });

  it("skips manifest when presentation is already complete", async () => {
    const completeCache = createFakeCache({
      "weapon-perks": [
        {
          hash: 1001,
          name: "Fluted Barrel",
          searchName: "fluted barrel",
          icon: "/complete.png",
          description: "Already captured.",
        },
      ],
      mods: [],
      "origin-traits": [],
    });
    const loadRawTable = vi.fn();
    const manifest = {
      getStatus: async () => ({ cachedVersion: "test-version" }),
      loadRawTable,
    } as unknown as ManifestService;

    const map = await buildPlugMapForInventory(
      completeCache,
      manifest,
      "test-version",
      [1001],
    );

    expect(map.get(1001)?.icon).toBe("/complete.png");
    expect(loadRawTable).not.toHaveBeenCalled();
  });
});
