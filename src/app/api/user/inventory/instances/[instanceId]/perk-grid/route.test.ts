import { describe, expect, it, vi } from "vitest";

import { GET } from "./route";

const WEAPON_ITEM = {
  instanceId: "w1",
  itemHash: 123,
  bucket: "Kinetic",
  location: "vault" as const,
  power: 1800,
  isMasterwork: false,
  isCrafted: true,
  plugHashes: [101, 201],
  rollTags: [],
  syncedAt: "2026-01-01T00:00:00.000Z",
  socketPlugs: [
    {
      socketIndex: 0,
      equippedPlugHash: 101,
      reusablePlugHashes: [101, 102],
      columnKind: "barrel" as const,
      columnLabel: "Barrel",
    },
    {
      socketIndex: 1,
      equippedPlugHash: 201,
      reusablePlugHashes: [201],
      columnKind: "magazine" as const,
      columnLabel: "Magazine",
    },
  ],
};

const ARMOR_ITEM = { ...WEAPON_ITEM, instanceId: "a1", bucket: "Helmet" };

vi.mock("@/lib/auth/requireUser", () => ({
  requireAuthenticatedUser: vi.fn(async () => ({ user: { id: 1 } })),
}));

vi.mock("@/lib/db/client", () => ({
  getDb: vi.fn(() => ({})),
}));

vi.mock("@/lib/db/repositories/inventoryRepository", () => ({
  listInventoryItems: vi.fn((_db: unknown, userId: number) => {
    if (userId !== 1) return [];
    return [WEAPON_ITEM, ARMOR_ITEM];
  }),
}));

vi.mock("@/lib/inventory/instances/loadInstanceContext", () => ({
  buildPlugMapForInventory: vi.fn(async (_ec, _m, _v, plugHashes: number[]) => {
    const map = new Map<number, string>([
      [101, "Arrowhead Brake"],
      [102, "Fluted Barrel"],
      [201, "Appended Mag"],
      [5001, "Precision Frame"],
    ]);
    for (const hash of plugHashes) {
      if (!map.has(hash) && hash === 5001) map.set(hash, "Precision Frame");
    }
    return map;
  }),
}));

vi.mock("@/lib/inventory/instances/weaponSocketContext", () => ({
  loadWeaponSocketContext: vi.fn(async () => ({
    plugCategoryByHash: new Map<number, string>([
      [101, "barrels.rifle"],
      [102, "barrels.rifle"],
      [201, "magazines.ar"],
    ]),
    weaponPerkSocketIndexes: [0, 1],
  })),
}));

vi.mock("@/lib/services", () => ({
  getServices: vi.fn(async () => ({
    entityCache: { getStore: vi.fn(async () => []) },
    manifest: {
      getStatus: vi.fn(async () => ({ cachedVersion: "1" })),
    },
  })),
}));

function get(instanceId: string) {
  return GET(new Request("http://localhost/perk-grid"), {
    params: Promise.resolve({ instanceId }),
  });
}

describe("GET /api/user/inventory/instances/:instanceId/perk-grid", () => {
  it("returns 200 with grid shape for a weapon copy", async () => {
    const res = await get("w1");
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.instanceId).toBe("w1");
    expect(body.itemHash).toBe(123);
    expect(body.captureStatus).toBe("complete");
    expect(body.columns).toHaveLength(2);
    expect(body.columns[0].label).toBe("Barrel");
    expect(body.columns[0].options.map((o: { hash: number }) => o.hash)).toEqual([101, 102]);
  });

  it("returns 401 when unsigned", async () => {
    const { requireAuthenticatedUser } = await import("@/lib/auth/requireUser");
    vi.mocked(requireAuthenticatedUser).mockResolvedValueOnce(null);
    const res = await get("w1");
    expect(res.status).toBe(401);
  });

  it("returns 404 for a missing instance", async () => {
    const res = await get("missing");
    expect(res.status).toBe(404);
  });

  it("returns 400 for armor instances", async () => {
    const res = await get("a1");
    expect(res.status).toBe(400);
  });

  it("returns pending status with equipped-only options when socket_plugs is null", async () => {
    const { listInventoryItems } = await import("@/lib/db/repositories/inventoryRepository");
    vi.mocked(listInventoryItems).mockReturnValueOnce([
      { ...WEAPON_ITEM, instanceId: "stale", socketPlugs: null },
    ]);
    const res = await get("stale");
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.captureStatus).toBe("pending");
    expect(body.columns.every((col: { options: unknown[] }) => col.options.length === 1)).toBe(
      true,
    );
  });
});
