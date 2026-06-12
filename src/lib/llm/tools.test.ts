import { describe, expect, it, vi } from "vitest";

import { createItemResolver } from "@/lib/manifest/itemResolver";
import { normalizeName } from "@/lib/manifest/normalize";
import type { EntityCache, ItemResolver } from "@/lib/manifest/types/services";
import type {
  ArtifactRecord,
  ExoticArmorRecord,
  ExoticWeaponRecord,
  PerkRecord,
  WeaponRecord,
} from "@/lib/manifest/types/records";
import type { EntityStores, StoreName } from "@/lib/manifest/types/stores";

import {
  buildToolDefinitions,
  createToolExecutor,
  ManifestToolExecutor,
  type WebSearcher,
} from "./tools";

function baseRecord(hash: number, name: string) {
  return { hash, name, searchName: normalizeName(name), icon: null };
}

const WEAPON_PERKS: PerkRecord[] = [
  { ...baseRecord(101, "Explosive Payload"), description: "Solar explosions." },
  { ...baseRecord(102, "Firefly"), description: "Precision kills explode." },
  { ...baseRecord(103, "Frenzy"), description: "Rampage variant." },
  { ...baseRecord(201, "Opening Shot"), description: "First shot accuracy." },
  { ...baseRecord(202, "Kill Clip"), description: "Reload buff." },
  { ...baseRecord(203, "Outlaw"), description: "Reload speed." },
];

const WEAPONS: WeaponRecord[] = [
  {
    ...baseRecord(410412271, "Fatebringer (Timelost)"),
    slot: "Energy",
    element: "Solar",
    ammo: "Primary",
    frame: "Scout Rifle",
    itemTypeName: "Scout Rifle",
    originTraitHashes: [],
    perkColumns: [
      { column: 0, curated: [101], randomized: [102, 103] },
      { column: 2, curated: [201], randomized: [202, 203] },
    ],
  },
];

const EXOTIC_WEAPONS: ExoticWeaponRecord[] = [
  {
    ...baseRecord(3084923842, "Le Monarque"),
    slot: "Kinetic",
    element: "Void",
    ammo: "Primary",
    frame: "Combat Bow",
    intrinsic: { name: "Poison Arrows", description: "Poison on full draw." },
    catalyst: null,
    flavorText: "Queen's bow.",
  },
];

const EXOTIC_ARMOR: ExoticArmorRecord[] = [
  {
    ...baseRecord(3341713435, "Heart of Inmost Light"),
    classType: "Titan",
    slot: "Chest",
    intrinsic: { name: "Inmost Light", description: "Ability loop." },
    archetype: null,
    flavorText: "Inner fire.",
  },
];

const ARTIFACTS: ArtifactRecord[] = [
  {
    ...baseRecord(9001, "Avant-Garde"),
    description: "Season artifact.",
    perks: [
      {
        ...baseRecord(9101, "Anti-Barrier Scout Rifle"),
        description: "Scout barrier champion mod with a very long description that should be truncated by the tool executor when returned to the model for compact context windows.",
        column: 0,
        row: 0,
      },
    ],
  },
  {
    ...baseRecord(9002, "Renegade"),
    description: "Another artifact.",
    perks: [],
  },
];

function createFakeCache(stores: Partial<EntityStores>): EntityCache {
  return {
    getMeta: async () => null,
    rebuild: async () => {
      throw new Error("not implemented in tests");
    },
    getStore: async <TName extends StoreName>(name: TName) => {
      const store = stores[name];
      if (!store) throw new Error(`missing fixture store: ${name}`);
      return store as EntityStores[TName];
    },
  };
}

function createManyPerks(count: number): PerkRecord[] {
  return Array.from({ length: count }, (_, i) => ({
    ...baseRecord(10_000 + i, `Perk ${i}`),
    description: "Test perk.",
  }));
}

function createWideWeapon(perks: PerkRecord[]): WeaponRecord {
  const hashes = perks.map((p) => p.hash);
  return {
    ...baseRecord(999, "Wide Pool Rifle"),
    slot: "Kinetic",
    element: "Kinetic",
    ammo: "Primary",
    frame: "Auto Rifle",
    itemTypeName: "Auto Rifle",
    originTraitHashes: [],
    perkColumns: [{ column: 0, curated: [], randomized: hashes }],
  };
}

function createExecutor(
  resolver: ItemResolver,
  cache: EntityCache,
  searcher: WebSearcher,
): ManifestToolExecutor {
  return new ManifestToolExecutor({ resolver, cache, searcher });
}

describe("buildToolDefinitions", () => {
  it("defines all five research tools", () => {
    const names = buildToolDefinitions().map((t) => t.function.name);
    expect(names).toEqual([
      "search_items",
      "get_weapon_perks",
      "get_exotic_details",
      "get_artifact_perks",
      "web_search",
    ]);
  });
});

describe("ManifestToolExecutor", () => {
  const cache = createFakeCache({
    weapons: WEAPONS,
    "exotic-weapons": EXOTIC_WEAPONS,
    "exotic-armor": EXOTIC_ARMOR,
    artifacts: ARTIFACTS,
    "weapon-perks": WEAPON_PERKS,
  });
  const resolver = createItemResolver(cache);
  const searcher: WebSearcher = {
    search: vi.fn(async () => ({
      available: true,
      results: [{ title: "Meta", snippet: "Solar 3.0 notes", url: "https://example.com" }],
    })),
  };
  const executor = createExecutor(resolver, cache, searcher);

  it("search_items merges default stores and caps matches at 5", async () => {
    const result = await executor.execute("search_items", { query: "fate" });
    const matches = result.matches as { name: string }[];
    expect(matches.length).toBeLessThanOrEqual(5);
    expect(matches[0]?.name).toContain("Fatebringer");
  });

  it("get_weapon_perks returns legendary columns with curated-first perk names", async () => {
    const result = await executor.execute("get_weapon_perks", { weaponName: "Fatebringer (Timelost)" });
    expect(result.weapon).toBe("Fatebringer (Timelost)");
    const columns = result.columns as { column: number; perks: string[] }[];
    expect(columns[0]?.perks[0]).toBe("Explosive Payload");
    expect(columns[0]?.perks.length).toBeLessThanOrEqual(12);
  });

  it("get_weapon_perks caps perk names per column at 12", async () => {
    const manyPerks = createManyPerks(20);
    const wideCache = createFakeCache({
      weapons: [createWideWeapon(manyPerks)],
      "weapon-perks": manyPerks,
    });
    const wideExecutor = createExecutor(createItemResolver(wideCache), wideCache, searcher);
    const result = await wideExecutor.execute("get_weapon_perks", { weaponName: "Wide Pool Rifle" });
    const columns = result.columns as { perks: string[] }[];
    expect(columns[0]?.perks.length).toBe(12);
  });

  it("get_weapon_perks returns exotic intrinsics", async () => {
    const result = await executor.execute("get_weapon_perks", { weaponName: "Le Monarque" });
    expect(result.weapon).toBe("Le Monarque");
    expect(result.intrinsic).toEqual({ name: "Poison Arrows", description: "Poison on full draw." });
    expect(result).not.toHaveProperty("columns");
  });

  it("get_weapon_perks returns error on miss", async () => {
    const result = await executor.execute("get_weapon_perks", { weaponName: "Missing Gun" });
    expect(result.error).toContain('no weapon matching "Missing Gun"');
  });

  it("get_exotic_details returns armor details", async () => {
    const result = await executor.execute("get_exotic_details", { name: "Heart of Inmost Light" });
    expect(result.name).toBe("Heart of Inmost Light");
    expect(result.class).toBe("Titan");
    expect(result.intrinsic).toEqual({ name: "Inmost Light", description: "Ability loop." });
  });

  it("get_exotic_details returns weapon details", async () => {
    const result = await executor.execute("get_exotic_details", { name: "Le Monarque" });
    expect(result.slot).toBe("Kinetic");
    expect(result.frame).toBe("Combat Bow");
  });

  it("get_exotic_details returns error on miss", async () => {
    const result = await executor.execute("get_exotic_details", { name: "Unknown Exotic" });
    expect(result.error).toContain('no exotic matching "Unknown Exotic"');
  });

  it("get_artifact_perks returns truncated perk descriptions", async () => {
    const result = await executor.execute("get_artifact_perks", { artifactName: "Avant-Garde" });
    expect(result.artifact).toBe("Avant-Garde");
    const perks = result.perks as { description: string }[];
    expect(perks[0]?.description.length).toBeLessThanOrEqual(141);
  });

  it("get_artifact_perks lists available artifacts on miss", async () => {
    const result = await executor.execute("get_artifact_perks", { artifactName: "Missing" });
    expect(result.error).toContain("Available: Avant-Garde, Renegade");
  });

  it("web_search returns truncated results when available", async () => {
    const result = await executor.execute("web_search", { query: "solar titan" });
    expect(result.results).toHaveLength(1);
    expect(result.results).toEqual([
      { title: "Meta", snippet: "Solar 3.0 notes", url: "https://example.com" },
    ]);
  });

  it("web_search returns unavailable error", async () => {
    const offlineSearcher: WebSearcher = {
      search: vi.fn(async () => ({ available: false, reason: "SearXNG offline" })),
    };
    const offline = createExecutor(resolver, cache, offlineSearcher);
    const result = await offline.execute("web_search", { query: "meta" });
    expect(result.error).toContain("web search unavailable: SearXNG offline");
  });

  it("validates required string args", async () => {
    expect(await executor.execute("search_items", { query: "  " })).toEqual({
      error: "query must be a non-empty string",
    });
  });

  it("createToolExecutor returns a working executor", async () => {
    const created = createToolExecutor({ resolver, cache, searcher });
    const result = await created.execute("search_items", { query: "Le Monarque" });
    expect((result.matches as { name: string }[])[0]?.name).toBe("Le Monarque");
  });
});
