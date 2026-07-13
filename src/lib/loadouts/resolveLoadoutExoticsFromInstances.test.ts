import { describe, expect, it } from "vitest";

import {
  buildExoticCatalogIndex,
  instanceHashMapFromInventory,
  resolveLoadoutExoticsFromInstances,
} from "./resolveLoadoutExoticsFromInstances";

const catalog = buildExoticCatalogIndex(
  [
    { hash: 100, name: "Synthoceps" },
    { hash: 101, name: "Heart of Inmost Light" },
  ],
  [
    { hash: 200, name: "Thunderlord" },
    { hash: 201, name: "Witherhoard" },
  ],
);

describe("resolveLoadoutExoticsFromInstances", () => {
  it("resolves armor and weapon from instance map", () => {
    const map = new Map([
      ["a", 100],
      ["w", 200],
      ["leg", 999],
    ]);
    const r = resolveLoadoutExoticsFromInstances(["a", "leg", "w"], map, catalog);
    expect(r).toEqual({
      exoticArmorHash: 100,
      exoticWeaponHash: 200,
      exoticArmorName: "Synthoceps",
      exoticWeaponName: "Thunderlord",
    });
  });

  it("returns nulls when instances missing from inventory", () => {
    const r = resolveLoadoutExoticsFromInstances(
      ["missing"],
      new Map(),
      catalog,
    );
    expect(r.exoticArmorHash).toBeNull();
    expect(r.exoticWeaponHash).toBeNull();
  });

  it("picks first exotic of each kind", () => {
    const map = new Map([
      ["a1", 100],
      ["a2", 101],
      ["w1", 201],
    ]);
    const r = resolveLoadoutExoticsFromInstances(
      ["a1", "a2", "w1"],
      map,
      catalog,
    );
    expect(r.exoticArmorHash).toBe(100);
    expect(r.exoticWeaponHash).toBe(201);
  });
});

describe("instanceHashMapFromInventory", () => {
  it("maps instance ids", () => {
    const map = instanceHashMapFromInventory([
      { instanceId: "x", itemHash: 1 },
      { instanceId: "y", itemHash: 2 },
    ]);
    expect(map.get("x")).toBe(1);
    expect(map.get("y")).toBe(2);
  });
});
