import { describe, expect, it } from "vitest";

import {
  intersectAllowlists,
  resolveSynergyCatalogAllowlists,
} from "@/lib/catalog/synergyCatalogFilter";
import type { PerkWeaponIndex } from "@/lib/manifest/perkWeaponIndex";
import type { SetBonusRecord, WeaponRecord } from "@/lib/manifest/types/records";

const perkIndex: PerkWeaponIndex = {
  manifestVersion: "test",
  builtAt: "now",
  byPerk: {
    "100": [
      {
        weaponHash: 10,
        weaponName: "Gun A",
        slot: "Kinetic",
        itemTypeName: "Auto Rifle",
        frame: "Adaptive Frame",
        column: 2,
        curated: true,
      },
      {
        weaponHash: 11,
        weaponName: "Gun B",
        slot: "Energy",
        itemTypeName: "Pulse Rifle",
        frame: "Rapid-Fire Frame",
        column: 2,
        curated: false,
      },
    ],
  },
};

const weapons = [
  {
    hash: 20,
    name: "Trait Gun",
    originTraitHashes: [900],
  },
  {
    hash: 21,
    name: "Other",
    originTraitHashes: [901],
  },
] as unknown as WeaponRecord[];

const setBonuses: SetBonusRecord[] = [
  {
    hash: 800,
    name: "Eutechnology",
    searchName: "eutechnology",
    icon: null,
    perks: [],
    itemHashes: [50, 51],
  },
];

describe("resolveSynergyCatalogAllowlists", () => {
  it("maps weapon_perk links via perk index", () => {
    const result = resolveSynergyCatalogAllowlists(
      [
        {
          links: [{ kind: "weapon_perk", perkHash: 100 }],
        },
      ],
      { perkIndex, weapons, setBonuses },
    );
    expect(result.empty).toBe(false);
    expect([...result.weaponHashes].sort()).toEqual([10, 11]);
    expect(result.armorHashes.size).toBe(0);
  });

  it("maps direct weapon and exotic_armor hashes", () => {
    const result = resolveSynergyCatalogAllowlists(
      [
        {
          links: [
            { kind: "weapon", itemHash: 42 },
            { kind: "exotic_armor", itemHash: 99 },
          ],
        },
      ],
      { perkIndex, weapons, setBonuses },
    );
    expect(result.weaponHashes.has(42)).toBe(true);
    expect(result.armorHashes.has(99)).toBe(true);
    expect(result.empty).toBe(false);
  });

  it("maps origin_trait to weapons with that trait hash", () => {
    const result = resolveSynergyCatalogAllowlists(
      [
        {
          links: [{ kind: "origin_trait", originTraitHash: 900 }],
        },
      ],
      { perkIndex, weapons, setBonuses },
    );
    expect([...result.weaponHashes]).toEqual([20]);
  });

  it("maps armor_set_bonus to set item hashes", () => {
    const result = resolveSynergyCatalogAllowlists(
      [
        {
          links: [
            {
              kind: "armor_set_bonus",
              armorSetName: "Eutechnology",
              armorSetHash: 800,
              bonusPieces: 2,
              bonusName: "Gift",
            },
          ],
        },
      ],
      { perkIndex, weapons, setBonuses },
    );
    expect([...result.armorHashes].sort()).toEqual([50, 51]);
  });

  it("ignores artifact_perk for catalog allowlists", () => {
    const result = resolveSynergyCatalogAllowlists(
      [
        {
          links: [{ kind: "artifact_perk", perkHash: 1 }],
        },
      ],
      { perkIndex, weapons, setBonuses },
    );
    expect(result.empty).toBe(true);
    expect(result.weaponHashes.size).toBe(0);
    expect(result.armorHashes.size).toBe(0);
  });

  it("unions links across multiple synergies", () => {
    const result = resolveSynergyCatalogAllowlists(
      [
        { links: [{ kind: "weapon", itemHash: 1 }] },
        { links: [{ kind: "exotic_armor", itemHash: 2 }] },
      ],
      { perkIndex, weapons, setBonuses },
    );
    expect(result.weaponHashes.has(1)).toBe(true);
    expect(result.armorHashes.has(2)).toBe(true);
  });
});

describe("intersectAllowlists", () => {
  it("ANDs two sets", () => {
    const out = intersectAllowlists(new Set([1, 2, 3]), new Set([2, 3, 4]));
    expect([...out!].sort()).toEqual([2, 3]);
  });

  it("treats undefined as no constraint", () => {
    expect(intersectAllowlists(undefined, new Set([1]))).toEqual(new Set([1]));
    expect(intersectAllowlists(new Set([1]), undefined)).toEqual(new Set([1]));
    expect(intersectAllowlists(undefined, undefined)).toBeUndefined();
  });
});
