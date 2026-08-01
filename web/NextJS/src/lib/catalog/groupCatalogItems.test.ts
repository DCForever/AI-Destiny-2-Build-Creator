import { describe, expect, it } from "vitest";

import { dimensionValue, groupCatalogItems } from "./groupCatalogItems";
import type { CatalogItem } from "./types";

function item(partial: Partial<CatalogItem> & Pick<CatalogItem, "hash" | "name">): CatalogItem {
  return {
    icon: null,
    isExotic: false,
    owned: false,
    ownedCount: 0,
    ...partial,
  };
}

describe("groupCatalogItems", () => {
  const rows = [
    item({
      hash: 1,
      name: "Fatebringer",
      element: "Kinetic",
      ammo: "Primary",
      itemTypeName: "Hand Cannon",
      frame: "Adaptive Frame",
      slot: "Kinetic",
    }),
    item({
      hash: 2,
      name: "Sunshot",
      element: "Solar",
      ammo: "Primary",
      itemTypeName: "Hand Cannon",
      frame: "Lightweight Frame",
      slot: "Energy",
      isExotic: true,
    }),
    item({
      hash: 3,
      name: "Gnawing Hunger",
      element: "Void",
      ammo: "Primary",
      itemTypeName: "Auto Rifle",
      frame: "Adaptive Frame",
      slot: "Energy",
    }),
  ];

  it("returns single group when no dimensions", () => {
    const groups = groupCatalogItems(rows, []);
    expect(groups).toHaveLength(1);
    expect(groups[0]?.key).toBe("__all__");
    expect(groups[0]?.items).toHaveLength(3);
  });

  it("groups by element", () => {
    const groups = groupCatalogItems(rows, ["element"]);
    expect(groups.map((g) => g.label).sort()).toEqual([
      "Kinetic",
      "Solar",
      "Void",
    ]);
    expect(groups.find((g) => g.label === "Solar")?.items[0]?.name).toBe(
      "Sunshot",
    );
  });

  it("combines multi dimensions into composite keys", () => {
    const groups = groupCatalogItems(rows, ["ammo", "archetype"]);
    expect(groups.map((g) => g.label).sort()).toEqual([
      "Primary · Auto Rifle",
      "Primary · Hand Cannon",
    ]);
    expect(
      groups.find((g) => g.label === "Primary · Hand Cannon")?.items,
    ).toHaveLength(2);
  });

  it("uses unknown fallbacks for missing fields", () => {
    expect(dimensionValue(item({ hash: 9, name: "X" }), "ammo")).toBe(
      "Unknown ammo",
    );
    const groups = groupCatalogItems(
      [item({ hash: 9, name: "X" })],
      ["element", "ammo"],
    );
    expect(groups[0]?.label).toBe("Unknown element · Unknown ammo");
  });
});
