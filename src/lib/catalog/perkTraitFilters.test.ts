import { describe, expect, it } from "vitest";

import {
  FIXTURE_ORIGIN_CAST_NO_SHADOWS,
  FIXTURE_PERK_INCANDESCENT,
  FIXTURE_PERK_RAMPAGE,
  FIXTURE_PERK_WEAPON_INDEX,
  FIXTURE_WEAPON_NO_PERKS,
  FIXTURE_WEAPON_WITH_INCANDESCENT,
} from "./__fixtures__/setLookupFixtures";
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
});

describe("resolveOriginTraitFilter", () => {
  const traits = [FIXTURE_ORIGIN_CAST_NO_SHADOWS];
  const weapons = [FIXTURE_WEAPON_WITH_INCANDESCENT, FIXTURE_WEAPON_NO_PERKS];

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

  it("returns unresolved when trait not found", () => {
    const result = resolveOriginTraitFilter("Missing", traits, weapons);
    expect(result.ok).toBe(false);
  });
});
