import { describe, expect, it } from "vitest";

import {
  buildFormPreferenceFields,
  buildWeaponTypePreferences,
} from "./buildFormPreferences";

describe("buildFormPreferences", () => {
  it("drops unknown weapon types from include/exclude", () => {
    const prefs = buildWeaponTypePreferences({
      include: ["Hand Cannon", "Laser Gun"],
      exclude: ["Not Real", "Sword"],
      prioritizeOwned: false,
    });
    expect(prefs?.include).toEqual(["Hand Cannon"]);
    expect(prefs?.exclude).toEqual(["Sword"]);
  });

  it("omits preferences when empty", () => {
    expect(
      buildWeaponTypePreferences({ include: [], exclude: [], prioritizeOwned: false }),
    ).toBeUndefined();
  });

  it("uses picked exotic/weapon names only when set", () => {
    const fields = buildFormPreferenceFields({
      preferredExotic: "Synthoceps",
      preferredWeapon: null,
      weaponTypesInclude: ["Bow"],
      weaponTypesExclude: [],
      prioritizeOwned: true,
      notes: "go loud",
    });
    expect(fields.preferredExotic).toBe("Synthoceps");
    expect(fields.preferredWeapon).toBeUndefined();
    expect(fields.notes).toBe("go loud");
    expect(fields.weaponTypePreferences?.include).toEqual(["Bow"]);
    expect(fields.weaponTypePreferences?.prioritizeOwned).toBe(true);
  });
});
