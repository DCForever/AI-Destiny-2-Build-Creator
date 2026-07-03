import { describe, expect, it } from "vitest";

import {
  FIXTURE_ORIGIN_MELEE_DESCRIPTION,
  FIXTURE_PERK_MELEE_DESCRIPTION,
} from "@/lib/search/__fixtures__/descriptionSearchFixtures";
import {
  FIXTURE_ORIGIN_CAST_NO_SHADOWS,
  FIXTURE_PERK_INCANDESCENT,
  FIXTURE_PERK_RAMPAGE,
  FIXTURE_PERK_WEAPON_INDEX,
  FIXTURE_WEAPON_NO_PERKS,
  FIXTURE_WEAPON_WITH_INCANDESCENT,
} from "./__fixtures__/setLookupFixtures";
import type { PerkWeaponIndex } from "@/lib/manifest/perkWeaponIndex";
import {
  resolveOriginTraitFilter,
  resolvePerkFilter,
} from "./perkTraitFilters";

describe("resolvePerkFilter", () => {
  const perks = [FIXTURE_PERK_INCANDESCENT, FIXTURE_PERK_RAMPAGE];

  it("resolves perk by name substring", () => {
    const result = resolvePerkFilter("incan", perks, FIXTURE_PERK_WEAPON_INDEX);
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect([...result.weaponHashes]).toEqual([7001]);
    }
  });

  it("resolves perk by numeric hash", () => {
    const result = resolvePerkFilter("5001", perks, FIXTURE_PERK_WEAPON_INDEX);
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect([...result.weaponHashes]).toEqual([7001]);
    }
  });

  it("returns unresolved when perk name does not match", () => {
    const result = resolvePerkFilter("Nonexistent", perks, FIXTURE_PERK_WEAPON_INDEX);
    expect(result.ok).toBe(false);
  });

  it("resolves perk by description substring when name does not match", () => {
    const meleePerks = [...perks, FIXTURE_PERK_MELEE_DESCRIPTION];
    const index: PerkWeaponIndex = {
      ...FIXTURE_PERK_WEAPON_INDEX,
      byPerk: {
        ...FIXTURE_PERK_WEAPON_INDEX.byPerk,
        "5101": [
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
    const result = resolvePerkFilter("melee", meleePerks, index);
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect([...result.weaponHashes]).toEqual([7001]);
    }
  });
});

describe("resolveOriginTraitFilter", () => {
  const traits = [FIXTURE_ORIGIN_CAST_NO_SHADOWS, FIXTURE_ORIGIN_MELEE_DESCRIPTION];
  const weapons = [
    { ...FIXTURE_WEAPON_WITH_INCANDESCENT, originTraitHashes: [6001, 6101] },
    FIXTURE_WEAPON_NO_PERKS,
  ];

  it("resolves origin trait by name", () => {
    const result = resolveOriginTraitFilter("cast no", traits, weapons);
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect([...result.weaponHashes]).toEqual([7001]);
    }
  });

  it("resolves origin trait by hash", () => {
    const result = resolveOriginTraitFilter("6001", traits, weapons);
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect([...result.weaponHashes]).toEqual([7001]);
    }
  });

  it("resolves origin trait by description substring", () => {
    const result = resolveOriginTraitFilter("reload", traits, weapons);
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect([...result.weaponHashes]).toEqual([7001]);
    }
  });

  it("returns unresolved when trait not found", () => {
    const result = resolveOriginTraitFilter("Missing", traits, weapons);
    expect(result.ok).toBe(false);
  });
});
