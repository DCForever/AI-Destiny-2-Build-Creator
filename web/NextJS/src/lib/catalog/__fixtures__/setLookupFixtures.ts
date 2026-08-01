import type { OriginTraitRecord, PerkRecord, SetBonusRecord, WeaponRecord } from "@/lib/manifest/types/records";
import type { PerkWeaponIndex } from "@/lib/manifest/perkWeaponIndex";

export const FIXTURE_PERK_INCANDESCENT: PerkRecord = {
  hash: 5001,
  name: "Incandescent",
  searchName: "incandescent",
  icon: null,
  description: "Solar ignition on rapid defeat.",
};

export const FIXTURE_PERK_RAMPAGE: PerkRecord = {
  hash: 5002,
  name: "Rampage",
  searchName: "rampage",
  icon: null,
  description: "Stacking damage buff.",
};

export const FIXTURE_ORIGIN_CAST_NO_SHADOWS: OriginTraitRecord = {
  hash: 6001,
  name: "Cast No Shadows",
  searchName: "cast no shadows",
  icon: null,
  description: "Origin trait fixture.",
};

export const FIXTURE_WEAPON_WITH_INCANDESCENT: WeaponRecord = {
  hash: 7001,
  name: "Fixture Auto",
  searchName: "fixture auto",
  icon: null,
  slot: "Kinetic",
  element: "Solar",
  ammo: "Primary",
  frame: "Adaptive Frame",
  itemTypeName: "Auto Rifle",
  originTraitHashes: [6001],
  perkColumns: [{ column: 2, curated: [5001], randomized: [] }],
};

export const FIXTURE_WEAPON_NO_PERKS: WeaponRecord = {
  hash: 7002,
  name: "Plain Sidearm",
  searchName: "plain sidearm",
  icon: null,
  slot: "Energy",
  element: "Arc",
  ammo: "Primary",
  frame: "Adaptive Frame",
  itemTypeName: "Sidearm",
  originTraitHashes: [],
  perkColumns: [],
};

export const FIXTURE_SET_EUTECHNOLOGY: SetBonusRecord = {
  hash: 8001,
  name: "Eutechnology",
  searchName: "eutechnology",
  icon: null,
  perks: [
    { requiredCount: 2, name: "Gift of the Ley Lines", description: "2pc" },
    { requiredCount: 4, name: "Techeun's Foresight", description: "4pc" },
  ],
  itemHashes: [9001, 9002],
};

export const FIXTURE_PERK_WEAPON_INDEX: PerkWeaponIndex = {
  manifestVersion: "test",
  builtAt: "2026-01-01T00:00:00.000Z",
  byPerk: {
    "5001": [
      {
        weaponHash: 7001,
        weaponName: "Fixture Auto",
        slot: "Kinetic",
        itemTypeName: "Auto Rifle",
        frame: "Adaptive Frame",
        column: 2,
        curated: true,
      },
    ],
  },
};
