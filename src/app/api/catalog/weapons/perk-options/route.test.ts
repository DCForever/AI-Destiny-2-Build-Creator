import { describe, expect, it, vi } from "vitest";

import { GET } from "./route";

const WEAPONS = [
  {
    hash: 123,
    name: "Gunburn",
    searchName: "gunburn",
    icon: null,
    perkColumns: [
      { column: 0, curated: [10], randomized: [10, 11] },
      { column: 1, curated: [20], randomized: [20] },
    ],
  },
];

const WEAPON_PERKS = [
  { hash: 10, name: "Arrowhead Brake", searchName: "arrowhead brake", description: "", icon: null },
  { hash: 11, name: "Fluted Barrel", searchName: "fluted barrel", description: "", icon: null },
  { hash: 20, name: "Appended Mag", searchName: "appended mag", description: "", icon: null },
];

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(async () => ({
    entityCache: {
      getStore: vi.fn(async (name: string) => {
        if (name === "weapons") return WEAPONS;
        if (name === "weapon-perks") return WEAPON_PERKS;
        return [];
      }),
    },
  })),
}));

function get(url: string) {
  return GET(new Request(url));
}

describe("GET /api/catalog/weapons/perk-options", () => {
  it("returns per-column options for a known weapon", async () => {
    const res = await get("http://localhost/api/catalog/weapons/perk-options?itemHash=123");
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.itemHash).toBe(123);
    expect(body.columns).toHaveLength(2);
    expect(body.columns[0].options.map((o: { hash: number }) => o.hash)).toEqual([10, 11]);
    expect(body.columns[0].options[0].name).toBe("Arrowhead Brake");
  });

  it("returns 400 when itemHash is missing or invalid", async () => {
    expect((await get("http://localhost/api/catalog/weapons/perk-options")).status).toBe(400);
    expect(
      (await get("http://localhost/api/catalog/weapons/perk-options?itemHash=abc")).status,
    ).toBe(400);
  });

  it("returns 200 with empty columns for an unavailable weapon", async () => {
    const res = await get("http://localhost/api/catalog/weapons/perk-options?itemHash=999");
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.columns).toEqual([]);
  });
});
