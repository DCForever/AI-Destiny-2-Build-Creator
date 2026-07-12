import { describe, expect, it } from "vitest";

import {
  filterKnownWeaponTypes,
  isKnownWeaponType,
  KNOWN_WEAPON_TYPES,
  toggleWeaponType,
} from "./weaponTypes";

describe("KNOWN_WEAPON_TYPES", () => {
  it("includes common Destiny weapon types", () => {
    expect(KNOWN_WEAPON_TYPES).toContain("Hand Cannon");
    expect(KNOWN_WEAPON_TYPES).toContain("Pulse Rifle");
    expect(KNOWN_WEAPON_TYPES).toContain("Sword");
  });

  it("rejects unknown free-text types", () => {
    expect(isKnownWeaponType("Hand Cannon")).toBe(true);
    expect(isKnownWeaponType("Laser Gun")).toBe(false);
    expect(isKnownWeaponType("")).toBe(false);
  });

  it("filters lists to vocabulary only", () => {
    expect(filterKnownWeaponTypes(["Hand Cannon", "Laser Gun", "Sword", "Hand Cannon"])).toEqual([
      "Hand Cannon",
      "Sword",
    ]);
  });

  it("toggles membership", () => {
    expect(toggleWeaponType([], "Bow")).toEqual(["Bow"]);
    expect(toggleWeaponType(["Bow"], "Bow")).toEqual([]);
    expect(toggleWeaponType(["Bow"], "Sword")).toEqual(["Bow", "Sword"]);
  });
});
