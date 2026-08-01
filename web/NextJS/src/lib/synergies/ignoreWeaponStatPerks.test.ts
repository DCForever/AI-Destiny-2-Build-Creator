import { describe, expect, it } from "vitest";

import {
  barrelMagazineHashesFromWeapons,
  isBarrelOrMagazinePerkText,
  shouldIgnoreWeaponPerkForKeywords,
} from "./ignoreWeaponStatPerks";

describe("barrelMagazineHashesFromWeapons", () => {
  it("collects hashes from columns 0 and 1 only", () => {
    const hashes = barrelMagazineHashesFromWeapons([
      {
        perkColumns: [
          { column: 0, curated: [1], randomized: [2] },
          { column: 1, curated: [3], randomized: [] },
          { column: 2, curated: [4], randomized: [5] },
        ],
      },
    ]);
    expect([...hashes].sort()).toEqual([1, 2, 3]);
    expect(hashes.has(4)).toBe(false);
  });
});

describe("isBarrelOrMagazinePerkText", () => {
  it("flags barrel and magazine style perks", () => {
    expect(
      isBarrelOrMagazinePerkText({
        name: "Fluted Barrel",
        description: "Ultra-light barrel. Increases handling.",
      }),
    ).toBe(true);
    expect(
      isBarrelOrMagazinePerkText({
        name: "Tactical Mag",
        description: "This weapon has a larger magazine.",
      }),
    ).toBe(true);
    expect(
      isBarrelOrMagazinePerkText({
        name: "High-Caliber Rounds",
        description: "Rounds cause flinch.",
      }),
    ).toBe(true);
  });

  it("does not flag trait perks like Kill Clip or Sliding", () => {
    expect(
      isBarrelOrMagazinePerkText({
        name: "Kill Clip",
        description: "Reloading after a kill grants increased damage.",
      }),
    ).toBe(false);
    expect(
      isBarrelOrMagazinePerkText({
        name: "Slideways",
        description: "Sliding partially reloads this weapon.",
      }),
    ).toBe(false);
  });
});

describe("shouldIgnoreWeaponPerkForKeywords", () => {
  it("ignores by hash or by text", () => {
    const hashes = new Set([99]);
    expect(
      shouldIgnoreWeaponPerkForKeywords(
        { hash: 99, name: "Some Trait", description: "Cool trait." },
        hashes,
      ),
    ).toBe(true);
    expect(
      shouldIgnoreWeaponPerkForKeywords(
        {
          hash: 1,
          name: "Corkscrew Rifling",
          description: "Balanced barrel.",
        },
        new Set(),
      ),
    ).toBe(true);
  });
});
