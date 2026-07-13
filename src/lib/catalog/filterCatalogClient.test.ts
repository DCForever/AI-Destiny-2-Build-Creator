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
    itemTypeName: "Rocket Launcher",
    isExotic: true,
    owned: true,
    ownedCount: 1,
  },
];

describe("filterCatalogClient", () => {
  it("filters by exotic flag and element", () => {
    expect(
      filterCatalogClient(ITEMS, { onlyExotic: true, elements: ["Solar"] }).map((i) => i.hash),
    ).toEqual([2]);
  });

  it("filters by query across name and type", () => {
    expect(filterCatalogClient(ITEMS, { query: "grenade" }).map((i) => i.hash)).toEqual([1]);
  });
});
