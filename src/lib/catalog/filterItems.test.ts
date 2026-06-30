import { describe, expect, it } from "vitest";

import type { ExoticArmorRecord, ExoticWeaponRecord, WeaponRecord } from "@/lib/manifest/types/records";

import { filterArmorCatalog, filterWeaponCatalog, ownedHashesFromInventory, aggregateOwnedCountsBySearchName } from "./filterItems";

const legendaryAuto: WeaponRecord = {
  hash: 1001,
  name: "Test Auto",
  searchName: "test auto",
  icon: null,
  slot: "Kinetic",
  element: "Kinetic",
  ammo: "Primary",
  frame: "Adaptive Frame",
  itemTypeName: "Auto Rifle",
  originTraitHashes: [],
  perkColumns: [],
};

const exoticHc: ExoticWeaponRecord = {
  hash: 2001,
  name: "Exotic HC",
  searchName: "exotic hc",
  icon: null,
  slot: "Energy",
  element: "Solar",
  ammo: "Primary",
  frame: "Hand Cannon Frame",
  intrinsic: { name: "Intrinsic", description: "" },
  catalyst: null,
  flavorText: "",
};

const exoticHelmet: ExoticArmorRecord = {
  hash: 3001,
  name: "Exotic Helm",
  searchName: "exotic helm",
  icon: null,
  classType: "Titan",
  slot: "Helmet",
  intrinsic: { name: "Intrinsic", description: "" },
  archetype: "Grenadier",
  flavorText: "",
};

describe("filterWeaponCatalog", () => {
  it("sorts results alphabetically by name", () => {
    const results = filterWeaponCatalog(
      { weapons: [legendaryAuto], exoticWeapons: [exoticHc] },
      { scope: "all" },
    );
    expect(results.map((r) => r.name)).toEqual(["Exotic HC", "Test Auto"]);
  });

  it("filters by item type and frame in all scope", () => {
    const results = filterWeaponCatalog(
      { weapons: [legendaryAuto], exoticWeapons: [exoticHc] },
      { scope: "all", itemType: "Auto Rifle", frame: "Adaptive Frame" },
    );
    expect(results).toHaveLength(1);
    expect(results[0]?.hash).toBe(1001);
  });

  it("searches by fuse query", () => {
    const results = filterWeaponCatalog(
      { weapons: [legendaryAuto], exoticWeapons: [exoticHc] },
      { scope: "all", q: "exotic" },
    );
    expect(results.map((r) => r.hash)).toContain(2001);
  });

  it("annotates owned counts in all scope when ownedHashes provided", () => {
    const owned = new Map([[1001, 2]]);
    const results = filterWeaponCatalog(
      { weapons: [legendaryAuto], exoticWeapons: [exoticHc] },
      { scope: "all", ownedHashes: owned },
    );
    expect(results).toHaveLength(2);
    expect(results.find((r) => r.hash === 1001)?.ownedCount).toBe(2);
    expect(results.find((r) => r.hash === 1001)?.owned).toBe(true);
    expect(results.find((r) => r.hash === 2001)?.ownedCount).toBe(0);
  });

  it("aggregates reissue inventory hashes onto catalog row by search name", () => {
    const catalogWeapon: WeaponRecord = {
      ...legendaryAuto,
      hash: 93253474,
      name: "The Ringing Nail",
      searchName: "the ringing nail",
    };
    const owned = new Map([
      [3326135421, 1],
      [4206550094, 1],
    ]);
    const projections = new Map([
      [3326135421, { name: "The Ringing Nail", searchName: "the ringing nail", icon: null }],
      [4206550094, { name: "The Ringing Nail", searchName: "the ringing nail", icon: null }],
    ]);

    const results = filterWeaponCatalog(
      { weapons: [catalogWeapon], exoticWeapons: [] },
      { scope: "owned", ownedHashes: owned, inventoryProjections: projections, q: "Ringing Nail" },
    );

    expect(results).toHaveLength(1);
    expect(results[0]?.hash).toBe(93253474);
    expect(results[0]?.ownedCount).toBe(2);
  });

  it("aggregateOwnedCountsBySearchName rolls reissues onto representative hash", () => {
    const aggregated = aggregateOwnedCountsBySearchName(
      [{ hash: 93253474, searchName: "the ringing nail" }],
      new Map([
        [3326135421, 1],
        [4206550094, 1],
      ]),
      new Map([
        [3326135421, { name: "The Ringing Nail", searchName: "the ringing nail", icon: null }],
        [4206550094, { name: "The Ringing Nail", searchName: "the ringing nail", icon: null }],
      ]),
    );
    expect(aggregated.get(93253474)).toBe(2);
  });

  it("restricts to owned hashes in owned scope", () => {
    const owned = new Map([[1001, 1]]);
    const results = filterWeaponCatalog(
      { weapons: [legendaryAuto], exoticWeapons: [exoticHc] },
      { scope: "owned", ownedHashes: owned },
    );
    expect(results).toHaveLength(1);
    expect(results[0]?.hash).toBe(1001);
    expect(results[0]?.owned).toBe(true);
  });

  it("returns empty owned scope when no owned hashes", () => {
    const results = filterWeaponCatalog(
      { weapons: [legendaryAuto], exoticWeapons: [] },
      { scope: "owned", ownedHashes: new Map() },
    );
    expect(results).toHaveLength(0);
  });
});

describe("filterArmorCatalog", () => {
  it("filters exotic armor by class", () => {
    const results = filterArmorCatalog(
      { exoticArmor: [exoticHelmet] },
      { scope: "all", className: "Titan" },
    );
    expect(results).toHaveLength(1);
    expect(results[0]?.hash).toBe(3001);
  });

  it("owned scope uses inventory hashes with manifest enrichment", () => {
    const owned = new Map([
      [3001, 1],
      [9999, 1],
    ]);
    const results = filterArmorCatalog(
      { exoticArmor: [exoticHelmet] },
      { scope: "owned", ownedHashes: owned },
    );
    expect(results).toHaveLength(2);
    const unknown = results.find((r) => r.hash === 9999);
    expect(unknown?.name).toContain("9999");
    expect(unknown?.owned).toBe(true);
  });
});

describe("ownedHashesFromInventory", () => {
  it("collects unique hashes for weapon buckets", () => {
    const hashes = ownedHashesFromInventory(
      [
        { itemHash: 1001, bucket: "Kinetic" },
        { itemHash: 1001, bucket: "Kinetic" },
        { itemHash: 2001, bucket: "Helmet" },
      ],
      "weapons",
    );
    expect([...hashes.keys()]).toEqual([1001]);
    expect(hashes.get(1001)).toBe(2);
  });

  it("collects armor bucket hashes", () => {
    const hashes = ownedHashesFromInventory([{ itemHash: 3001, bucket: "Helmet" }], "armor");
    expect([...hashes.keys()]).toEqual([3001]);
  });
});
