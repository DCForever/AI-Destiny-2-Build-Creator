import { describe, expect, it } from "vitest";

import type { UserInventoryItem } from "@/lib/db/types";

import { resolveInstancePerkGrid, selectionFromGrid } from "./resolveInstancePerkGrid";

function weaponItem(overrides: Partial<UserInventoryItem> = {}): UserInventoryItem {
  return {
    instanceId: "w1",
    itemHash: 123,
    bucket: "Kinetic",
    location: "vault",
    power: 1800,
    isMasterwork: false,
    isCrafted: true,
    plugHashes: [101, 201, 301],
    rollTags: [],
    syncedAt: "2026-01-01T00:00:00.000Z",
    socketPlugs: [
      {
        socketIndex: 0,
        equippedPlugHash: 101,
        reusablePlugHashes: [101, 102],
        columnKind: "barrel",
        columnLabel: "Barrel",
      },
      {
        socketIndex: 1,
        equippedPlugHash: 201,
        reusablePlugHashes: [201],
        columnKind: "magazine",
        columnLabel: "Magazine",
      },
      {
        socketIndex: 2,
        equippedPlugHash: 301,
        reusablePlugHashes: [301, 302],
        columnKind: "trait",
        columnLabel: "Trait 1",
      },
    ],
    ...overrides,
  };
}

describe("resolveInstancePerkGrid", () => {
  const plugMap = new Map<number, string>([
    [101, "Arrowhead Brake"],
    [102, "Fluted Barrel"],
    [201, "Appended Mag"],
    [301, "Zen Moment"],
    [302, "Zen Moment"],
  ]);

  const plugCategoryByHash = new Map<number, string>([
    [101, "barrels.rifle"],
    [102, "barrels.rifle"],
    [201, "magazines.ar"],
    [301, "traits.weapon"],
    [302, "enhancements.v2"],
  ]);

  const weaponPerkSocketIndexes = [0, 1, 2];

  const gridInput = (item: UserInventoryItem) => ({
    item,
    plugMap,
    plugCategoryByHash,
    weaponPerkSocketIndexes,
  });

  it("returns complete grid with alternates and equipped flags", () => {
    const grid = resolveInstancePerkGrid(gridInput(weaponItem()));

    expect(grid.captureStatus).toBe("complete");
    expect(grid.columns).toHaveLength(3);
    expect(grid.columns[0]?.options.map((o) => o.hash)).toEqual([101, 102]);
    expect(grid.columns[0]?.options.find((o) => o.hash === 101)?.isEquipped).toBe(true);
    expect(grid.columns[2]?.options.find((o) => o.hash === 302)?.displayName).toBe(
      "Zen Moment (Enhanced)",
    );
  });

  it("produces different options for two copies with different stored plugs", () => {
    const copyA = resolveInstancePerkGrid(gridInput(weaponItem()));
    const copyB = resolveInstancePerkGrid(
      gridInput(
        weaponItem({
          instanceId: "w2",
          socketPlugs: [
            {
              socketIndex: 0,
              equippedPlugHash: 102,
              reusablePlugHashes: [102],
              columnKind: "barrel",
              columnLabel: "Barrel",
            },
          ],
        }),
      ),
    );

    expect(copyA.columns[0]?.options.map((o) => o.hash)).not.toEqual(
      copyB.columns[0]?.options.map((o) => o.hash),
    );
  });

  it("degrades to equipped-only with classified labels when capture is pending", () => {
    const grid = resolveInstancePerkGrid(
      gridInput(
        weaponItem({
          socketPlugs: null,
          plugHashes: [101, 201, 301],
        }),
      ),
    );

    expect(grid.captureStatus).toBe("pending");
    expect(grid.columns.map((col) => col.label)).toEqual(["Barrel", "Magazine", "Trait 1"]);
    expect(grid.columns.every((col) => col.options.length === 1)).toBe(true);
    expect(grid.columns[0]?.options[0]?.isEquipped).toBe(true);
  });

  it("filters cosmetic sockets from pending equipped-only grid", () => {
    const grid = resolveInstancePerkGrid({
      item: weaponItem({
        socketPlugs: null,
        plugHashes: [101, 901, 902],
      }),
      plugMap,
      plugCategoryByHash: new Map([
        ...plugCategoryByHash,
        [901, "shader"],
        [902, "tracker"],
      ]),
      weaponPerkSocketIndexes: [0, 1, 2],
    });
    expect(grid.columns.map((col) => col.label)).toEqual(["Barrel"]);
  });

  it("marks unavailable when socket_plugs is an empty array", () => {
    const grid = resolveInstancePerkGrid(gridInput(weaponItem({ socketPlugs: [] })));
    expect(grid.captureStatus).toBe("unavailable");
  });

  it("maps grid selection to column-order perk hashes", () => {
    const grid = resolveInstancePerkGrid(gridInput(weaponItem()));
    const selected = selectionFromGrid(grid, { 0: 102, 2: 302 });
    expect(selected).toEqual([102, 201, 302]);
  });

  it("disambiguates duplicate column labels using equipped plug names", () => {
    const grid = resolveInstancePerkGrid(
      gridInput(
        weaponItem({
          socketPlugs: [
            {
              socketIndex: 0,
              equippedPlugHash: 101,
              reusablePlugHashes: [101],
              columnKind: "intrinsic",
              columnLabel: "Intrinsic",
            },
            {
              socketIndex: 1,
              equippedPlugHash: 301,
              reusablePlugHashes: [301],
              columnKind: "intrinsic",
              columnLabel: "Intrinsic",
            },
          ],
        }),
      ),
    );
    expect(grid.columns.map((col) => col.label)).toEqual(["Arrowhead Brake", "Zen Moment"]);
  });
});
