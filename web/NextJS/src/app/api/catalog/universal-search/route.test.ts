import { beforeEach, describe, expect, it, vi } from "vitest";

import { getServices } from "@/lib/services";

import { GET } from "./route";

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(),
}));

vi.mock("@/lib/db/client", () => ({
  getDb: vi.fn(() => ({})),
}));

vi.mock("@/app/api/catalog/_ownedFilter", () => ({
  resolveOwnedCatalogContext: vi.fn(async () => null),
}));

vi.mock("@/lib/catalog/legendaryArmor", () => ({
  loadLegendaryArmorRows: vi.fn(async () => []),
}));

describe("GET /api/catalog/universal-search", () => {
  beforeEach(() => {
    vi.mocked(getServices).mockReset();
  });

  it("returns 400 for invalid kinds", async () => {
    const response = await GET(
      new Request("http://localhost/api/catalog/universal-search?q=x&kinds=not_a_kind"),
    );
    const body = await response.json();
    expect(response.status).toBe(400);
    expect(body.error).toMatch(/Invalid kind/i);
  });

  it("returns 400 for invalid limit", async () => {
    const response = await GET(
      new Request("http://localhost/api/catalog/universal-search?q=x&limit=0"),
    );
    expect(response.status).toBe(400);
  });

  it("returns 503 MANIFEST_NOT_READY when entity cache has no meta", async () => {
    vi.mocked(getServices).mockResolvedValue({
      entityCache: {
        getMeta: vi.fn(async () => null),
        getStore: vi.fn(),
      },
      manifest: { getStatus: vi.fn() },
    } as unknown as Awaited<ReturnType<typeof getServices>>);

    const response = await GET(
      new Request("http://localhost/api/catalog/universal-search?q=melee"),
    );
    const body = await response.json();

    expect(response.status).toBe(503);
    expect(body.code).toBe("MANIFEST_NOT_READY");
    expect(body.error).toBeTruthy();
  });

  it("returns NEED_QUERY for empty q when manifest is ready", async () => {
    vi.mocked(getServices).mockResolvedValue({
      entityCache: {
        getMeta: vi.fn(async () => ({
          manifestVersion: "t",
          builtAt: "t",
          counts: {},
        })),
        getStore: vi.fn(async () => []),
      },
      manifest: {
        getStatus: vi.fn(async () => ({ cachedVersion: "t" })),
      },
    } as unknown as Awaited<ReturnType<typeof getServices>>);

    const response = await GET(
      new Request("http://localhost/api/catalog/universal-search?q=%20%20"),
    );
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(body.code).toBe("NEED_QUERY");
    expect(body.hits).toEqual([]);
    expect(body.manifestReady).toBe(true);
  });

  it("returns mixed hits with kind labels and actions", async () => {
    const getStore = vi.fn(async (name: string) => {
      if (name === "weapon-perks") {
        return [
          {
            hash: 42,
            name: "Frenzy",
            searchName: "frenzy",
            icon: "/p.png",
            description: "Being in combat increases damage and reload.",
            source: "legendary",
            plugTypeName: "Trait",
          },
        ];
      }
      if (name === "origin-traits") {
        return [
          {
            hash: 7,
            name: "Veist Stinger",
            searchName: "veist stinger",
            icon: "/o.png",
            description: "Damaging an enemy may reload from reserves.",
          },
        ];
      }
      return [];
    });

    vi.mocked(getServices).mockResolvedValue({
      entityCache: {
        getMeta: vi.fn(async () => ({
          manifestVersion: "t",
          builtAt: "t",
          counts: {},
        })),
        getStore,
      },
      manifest: {
        getStatus: vi.fn(async () => ({ cachedVersion: "t" })),
      },
    } as unknown as Awaited<ReturnType<typeof getServices>>);

    const response = await GET(
      new Request(
        "http://localhost/api/catalog/universal-search?q=combat&kinds=weapon_perk,origin_trait&limit=10",
      ),
    );
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(body.manifestReady).toBe(true);
    expect(body.query).toBe("combat");
    expect(body.kinds).toEqual(["weapon_perk", "origin_trait"]);
    expect(body.hits.length).toBeGreaterThanOrEqual(1);
    expect(body.hits[0]).toMatchObject({
      kind: "weapon_perk",
      id: "weapon_perk:42",
      name: "Frenzy",
      matchField: "description",
      actions: { set: false, synergy: true },
    });
  });

  it("returns empty hits without NEED_QUERY when no matches", async () => {
    vi.mocked(getServices).mockResolvedValue({
      entityCache: {
        getMeta: vi.fn(async () => ({
          manifestVersion: "t",
          builtAt: "t",
          counts: {},
        })),
        getStore: vi.fn(async () => []),
      },
      manifest: {
        getStatus: vi.fn(async () => ({ cachedVersion: "t" })),
      },
    } as unknown as Awaited<ReturnType<typeof getServices>>);

    const response = await GET(
      new Request(
        "http://localhost/api/catalog/universal-search?q=zzznomatch&kinds=weapon_perk",
      ),
    );
    const body = await response.json();

    expect(response.status).toBe(200);
    expect(body.hits).toEqual([]);
    expect(body.code).toBe("FILTERED_EMPTY");
    expect(body.manifestReady).toBe(true);
  });
});
