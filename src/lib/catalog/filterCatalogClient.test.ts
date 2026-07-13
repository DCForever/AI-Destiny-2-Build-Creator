import { describe, expect, it } from "vitest";

import type { CatalogItem } from "@/lib/catalog/types";
import { filterCatalogClient } from "./filterCatalogClient";

const ITEMS: CatalogItem[] = [
  {
    hash: 1,
    name: "Edge Transit",
    icon: null,
    slot: "Energy",
    element: "Void",
    ammo: "Special",
    itemTypeName: "Grenade Launcher",
    isExotic: false,
    owned: true,
    ownedCount: 2,
  },
  {
    hash: 2,
    name: "Dragon's Breath",
    icon: null,
    slot: "Power",
    element: "Solar",
    ammo: "Heavy",
    itemTypeName: "Rocket Launcher",
    isExotic: true,
    owned: true,
    ownedCount: 1,
  },
  {
    hash: 3,
    name: "Synthoceps",
    icon: null,
    slot: "Gauntlets",
    classType: "Titan",
    frame: "Brawler",
    isExotic: true,
    owned: true,
    ownedCount: 1,
  },
];

describe("filterCatalogClient", () => {
  it("filters by exotic flag and element", () => {
    expect(
      filterCatalogClient(ITEMS, { onlyExotic: true, elements: ["Solar"] }).map(
        (i) => i.hash,
      ),
    ).toEqual([2]);
  });

  it("filters by query across name and type", () => {
    expect(
      filterCatalogClient(ITEMS, { query: "grenade" }).map((i) => i.hash),
    ).toEqual([1]);
  });

  it("filters by ammo and slot", () => {
    expect(
      filterCatalogClient(ITEMS, { ammos: ["Heavy"], slot: "Power" }).map(
        (i) => i.hash,
      ),
    ).toEqual([2]);
  });

  it("filters by weapon archetype (itemTypeName)", () => {
    expect(
      filterCatalogClient(ITEMS, {
        archetypes: ["Rocket Launcher"],
      }).map((i) => i.hash),
    ).toEqual([2]);
  });

  it("filters by armor class and frame", () => {
    expect(
      filterCatalogClient(ITEMS, {
        className: "Titan",
        archetypes: ["Brawler"],
      }).map((i) => i.hash),
    ).toEqual([3]);
  });

  it("OR within multi-select dimensions", () => {
    expect(
      filterCatalogClient(ITEMS, {
        elements: ["Void", "Solar"],
      }).map((i) => i.hash),
    ).toEqual([1, 2]);
  });
});
