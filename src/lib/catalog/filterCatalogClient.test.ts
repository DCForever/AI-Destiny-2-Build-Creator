import { describe, expect, it } from "vitest";

import type { CatalogItem } from "@/lib/catalog/types";
import {
  cycleFacetValue,
  emptyFacet,
  facetChipState,
  filterCatalogClient,
  matchesFacet,
} from "./filterCatalogClient";

type ItemWithSynergy = CatalogItem & { linkedSynergyIds?: string[] };

const ITEMS: ItemWithSynergy[] = [
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
    linkedSynergyIds: ["syn-void"],
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
    linkedSynergyIds: ["syn-solar", "syn-dps"],
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
    linkedSynergyIds: ["syn-melee"],
  },
  {
    hash: 4,
    name: "Arc Logic",
    icon: null,
    slot: "Energy",
    element: "Arc",
    ammo: "Primary",
    itemTypeName: "Auto Rifle",
    isExotic: false,
    owned: true,
    ownedCount: 1,
    linkedSynergyIds: [],
  },
];

describe("facet helpers", () => {
  it("cycles off → include → exclude → off", () => {
    let f = emptyFacet();
    f = cycleFacetValue(f, "Solar");
    expect(facetChipState(f, "Solar")).toBe("include");
    f = cycleFacetValue(f, "Solar");
    expect(facetChipState(f, "Solar")).toBe("exclude");
    f = cycleFacetValue(f, "Solar");
    expect(facetChipState(f, "Solar")).toBe("off");
  });

  it("matchesFacet: include OR, exclude drops", () => {
    expect(
      matchesFacet({ include: ["Solar", "Arc"], exclude: [] }, "Solar"),
    ).toBe(true);
    expect(
      matchesFacet({ include: ["Solar"], exclude: ["Special"] }, "Solar"),
    ).toBe(true);
    expect(
      matchesFacet({ include: [], exclude: ["Void"] }, "Void"),
    ).toBe(false);
    expect(matchesFacet({ include: [], exclude: ["Void"] }, "Solar")).toBe(
      true,
    );
  });
});

describe("filterCatalogClient", () => {
  it("legacy string[] still includes (OR within dimension)", () => {
    expect(
      filterCatalogClient(ITEMS, { elements: ["Void", "Solar"] }).map(
        (i) => i.hash,
      ),
    ).toEqual([1, 2]);
  });

  it("filters by exotic flag and element include", () => {
    expect(
      filterCatalogClient(ITEMS, {
        onlyExotic: true,
        elements: { include: ["Solar"], exclude: [] },
      }).map((i) => i.hash),
    ).toEqual([2]);
  });

  it("mix-and-match: include Solar OR Arc AND exclude Special ammo", () => {
    const hashes = filterCatalogClient(ITEMS, {
      elements: { include: ["Solar", "Arc"], exclude: [] },
      ammos: { include: [], exclude: ["Special"] },
    }).map((i) => i.hash);
    // Edge Transit is Void Special → out; Dragon Solar Heavy → in; Arc Logic Arc Primary → in
    expect(hashes).toEqual([2, 4]);
  });

  it("AND across dimensions: include Heavy and exclude Solar", () => {
    expect(
      filterCatalogClient(ITEMS, {
        ammos: { include: ["Heavy"], exclude: [] },
        elements: { include: [], exclude: ["Solar"] },
      }).map((i) => i.hash),
    ).toEqual([]);
  });

  it("exclude exotic keeps legendaries", () => {
    expect(
      filterCatalogClient(ITEMS, { exotic: false }).map((i) => i.hash),
    ).toEqual([1, 4]);
  });

  it("free-text after include/exclude", () => {
    expect(
      filterCatalogClient(ITEMS, {
        elements: { include: ["Void", "Solar", "Arc"], exclude: [] },
        query: "breath",
      }).map((i) => i.hash),
    ).toEqual([2]);
  });

  it("filters by ammo and slot (legacy)", () => {
    expect(
      filterCatalogClient(ITEMS, { ammos: ["Heavy"], slot: "Power" }).map(
        (i) => i.hash,
      ),
    ).toEqual([2]);
  });

  it("filters by weapon archetype include", () => {
    expect(
      filterCatalogClient(ITEMS, {
        archetypes: { include: ["Rocket Launcher"], exclude: [] },
      }).map((i) => i.hash),
    ).toEqual([2]);
  });

  it("excludes weapon archetype", () => {
    expect(
      filterCatalogClient(ITEMS, {
        archetypes: { include: [], exclude: ["Grenade Launcher"] },
      }).map((i) => i.hash),
    ).toEqual([2, 3, 4]);
  });

  it("filters by armor class and frame", () => {
    expect(
      filterCatalogClient(ITEMS, {
        className: "Titan",
        archetypes: ["Brawler"],
      }).map((i) => i.hash),
    ).toEqual([3]);
  });

  it("synergy include/exclude via linkedSynergyIds", () => {
    expect(
      filterCatalogClient(ITEMS, {
        synergies: { include: ["syn-solar"], exclude: [] },
      }).map((i) => i.hash),
    ).toEqual([2]);

    expect(
      filterCatalogClient(ITEMS, {
        synergies: { include: [], exclude: ["syn-void"] },
      }).map((i) => i.hash),
    ).toEqual([2, 3, 4]);

    expect(
      filterCatalogClient(ITEMS, {
        synergies: { include: ["syn-dps", "syn-melee"], exclude: ["syn-solar"] },
      }).map((i) => i.hash),
    ).toEqual([3]);
  });

  it("synergy via item hash include/exclude sets (Catalog pipeline)", () => {
    expect(
      filterCatalogClient(ITEMS, {
        itemHashesInclude: [1, 4],
        itemHashesExclude: [4],
      }).map((i) => i.hash),
    ).toEqual([1]);
  });
});
