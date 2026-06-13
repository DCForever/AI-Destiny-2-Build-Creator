import { describe, it, expect } from "vitest";

import { buildPerkWeaponIndex, columnIndexToLabel } from "./perkWeaponIndex";
import type { WeaponRecord } from "./types/records";

const baseWeapon = (overrides: Partial<WeaponRecord>): WeaponRecord => ({
  hash: 100,
  name: "Test Rifle",
  searchName: "test rifle",
  icon: null,
  slot: "Kinetic",
  element: "Kinetic",
  ammo: "Primary",
  frame: "Adaptive Frame",
  itemTypeName: "Auto Rifle",
  originTraitHashes: [],
  perkColumns: [{ column: 2, curated: [200], randomized: [201] }],
  ...overrides,
});

describe("columnIndexToLabel", () => {
  it("maps standard columns", () => {
    expect(columnIndexToLabel(0)).toBe("Barrel");
    expect(columnIndexToLabel(2)).toBe("Trait 1");
    expect(columnIndexToLabel(-1)).toBe("Intrinsic");
  });
});

describe("buildPerkWeaponIndex", () => {
  it("indexes perk hash to weapon entries", () => {
    const weapon = baseWeapon({ hash: 1001, name: "Fatebringer" });
    const index = buildPerkWeaponIndex("1.0", {
      weapons: [weapon],
      "exotic-weapons": [],
      "weapon-perks": [
        { hash: 200, name: "Firefly", searchName: "firefly", icon: null, description: "Boom." },
      ],
    });

    expect(index.byPerk["200"]).toHaveLength(1);
    expect(index.byPerk["200"]?.[0]?.weaponName).toBe("Fatebringer");
    expect(index.byPerk["200"]?.[0]?.column).toBe(2);
    expect(index.byPerk["200"]?.[0]?.curated).toBe(true);
  });
});
