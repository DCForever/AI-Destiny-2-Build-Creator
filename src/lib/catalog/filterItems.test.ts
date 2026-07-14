import { describe, expect, it } from "vitest";

import type { ExoticArmorRecord, ExoticWeaponRecord, WeaponRecord } from "@/lib/manifest/types/records";

import { filterArmorCatalog, filterWeaponCatalog, ownedHashesFromInventory, aggregateOwnedCountsBySearchName } from "./filterItems";
import {
  FIXTURE_SET_EUTECHNOLOGY,
  FIXTURE_WEAPON_NO_PERKS,
  FIXTURE_WEAPON_WITH_INCANDESCENT,
} from "./__fixtures__/setLookupFixtures";
import { buildLegendaryArmorRows } from "./legendaryArmor";

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

  it("filters by multi element, ammo, and archetype (OR within each dimension)", () => {
    const sniper: WeaponRecord = {
      ...legendaryAuto,
      hash: 3002,
      name: "Test Sniper",
      searchName: "test sniper",
      slot: "Energy",
      element: "Void",
      ammo: "Special",
      frame: "Aggressive Frame",
      itemTypeName: "Sniper Rifle",
    };
    const multi = filterWeaponCatalog(
      { weapons: [legendaryAuto, sniper], exoticWeapons: [exoticHc] },
      {
        scope: "all",
        elements: ["Kinetic", "Solar"],
        ammos: ["Primary"],
        itemTypes: ["Hand Cannon", "Auto Rifle"],
      },
    );
    // Kinetic auto primary + Solar HC primary — sniper is Special so excluded by ammo
    expect(multi.map((r) => r.hash).sort()).toEqual([1001, 2001]);

    const byAmmo = filterWeaponCatalog(
      { weapons: [legendaryAuto, sniper], exoticWeapons: [exoticHc] },
      { scope: "all", ammos: ["Special"] },
    );
    expect(byAmmo.map((r) => r.hash)).toEqual([3002]);
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

  it("filters by weapon hash allowlist (perk)", () => {
    const results = filterWeaponCatalog(
      { weapons: [legendaryAuto, FIXTURE_WEAPON_WITH_INCANDESCENT], exoticWeapons: [] },
      { scope: "all", weaponHashAllowlist: new Set([7001]) },
    );
    expect(results).toHaveLength(1);
    expect(results[0]?.hash).toBe(7001);
  });

  it("filters by origin trait allowlist", () => {
    const results = filterWeaponCatalog(
      {
        weapons: [FIXTURE_WEAPON_WITH_INCANDESCENT, FIXTURE_WEAPON_NO_PERKS],
        exoticWeapons: [],
      },
      { scope: "all", weaponHashAllowlist: new Set([7001]) },
    );
    expect(results.map((r) => r.hash)).toEqual([7001]);
  });

  it("ANDs perk and origin trait allowlists", () => {
    const results = filterWeaponCatalog(
      {
        weapons: [FIXTURE_WEAPON_WITH_INCANDESCENT, FIXTURE_WEAPON_NO_PERKS],
        exoticWeapons: [],
      },
      { scope: "all", weaponHashAllowlist: new Set() },
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

  it("filters legendary armor by set bonus allowlist and slot", () => {
    const legendary = buildLegendaryArmorRows([FIXTURE_SET_EUTECHNOLOGY], (hash) => {
      if (hash === 9001) {
        return {
          name: "Eutech Helm",
          searchName: "eutech helm",
          icon: null,
          slot: "Helmet",
          classType: "Warlock",
        };
      }
      if (hash === 9002) {
        return {
          name: "Eutech Gloves",
          searchName: "eutech gloves",
          icon: null,
          slot: "Gauntlets",
          classType: "Warlock",
        };
      }
      return null;
    });

    const results = filterArmorCatalog(
      { exoticArmor: [exoticHelmet], legendaryArmor: legendary },
      {
        scope: "all",
        setBonus: "Eutechnology",
        slot: "Helmet",
        armorHashAllowlist: new Set([9001]),
      },
    );

    expect(results).toHaveLength(1);
    expect(results[0]?.hash).toBe(9001);
    expect(results[0]?.setBonusName).toBe("Eutechnology");
  });

  it("includes legendary armor whenever rows are provided (not set-bonus gated)", () => {
    const legendary = buildLegendaryArmorRows([FIXTURE_SET_EUTECHNOLOGY], () => ({
      name: "Eutech Helm",
      searchName: "eutech helm",
      icon: null,
      slot: "Helmet",
    }));

    const results = filterArmorCatalog(
      { exoticArmor: [exoticHelmet], legendaryArmor: legendary },
      { scope: "all" },
    );

    expect(results.map((r) => r.hash).sort()).toEqual(
      [3001, ...legendary.map((l) => l.hash)].sort(),
    );
  });

  it("filters owned unknown rows by projected slot", () => {
    const owned = new Map([[9999, 1]]);
    const projections = new Map([
      [
        9999,
        {
          name: "Owned Helm",
          searchName: "owned helm",
          icon: null as string | null,
          slot: "Helmet",
        },
      ],
    ]);
    const results = filterArmorCatalog(
      { exoticArmor: [exoticHelmet] },
      {
        scope: "owned",
        ownedHashes: owned,
        inventoryProjections: projections,
        slot: "Helmet",
      },
    );
    expect(results.some((r) => r.hash === 9999 && r.slot === "Helmet")).toBe(
      true,
    );
    // Exotic helm not owned — excluded
    expect(results.some((r) => r.hash === 3001)).toBe(false);
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

describe("filterWeaponCatalog description search", () => {
  const exoticPoison: ExoticWeaponRecord = {
    hash: 90001,
    name: "Test Bow",
    searchName: "test bow",
    icon: null,
    slot: "Kinetic",
    element: "Void",
    ammo: "Primary",
    frame: "Combat Bow",
    intrinsic: { name: "Poison Arrows", description: "Poison on full draw." },
    catalyst: null,
    flavorText: "",
  };

  it("matches exotic weapons by intrinsic description in q", () => {
    const results = filterWeaponCatalog(
      { weapons: [], exoticWeapons: [exoticPoison] },
      { scope: "all", q: "poison" },
    );
    expect(results).toHaveLength(1);
    expect(results[0]?.hash).toBe(90001);
    expect(results[0]?.description).toContain("Poison");
  });

  it("does not match legendary weapons by rollable perk description in q", () => {
    const results = filterWeaponCatalog(
      { weapons: [legendaryAuto], exoticWeapons: [] },
      { scope: "all", q: "solar ignition" },
    );
    expect(results).toHaveLength(0);
  });
});

describe("filterWeaponCatalog performance", () => {
  it("filters a large weapon list within 5 seconds", () => {
    const weapons: WeaponRecord[] = Array.from({ length: 5000 }, (_, i) => ({
      ...legendaryAuto,
      hash: 10_000 + i,
      name: `Weapon ${i}`,
      searchName: `weapon ${i}`,
    }));

    const start = performance.now();
    filterWeaponCatalog(
      { weapons, exoticWeapons: [exoticHc] },
      { scope: "all", weaponHashAllowlist: new Set(weapons.slice(0, 50).map((w) => w.hash)) },
    );
    const elapsed = performance.now() - start;

    expect(elapsed).toBeLessThan(5000);
  });
});
