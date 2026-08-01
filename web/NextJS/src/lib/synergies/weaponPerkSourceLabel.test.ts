import { describe, expect, it } from "vitest";

import { formatWeaponPerkSourceLabel } from "./weaponPerkSourceLabel";

describe("formatWeaponPerkSourceLabel", () => {
  it("labels exotic intrinsic and trait", () => {
    expect(formatWeaponPerkSourceLabel("exotic", "Intrinsic")).toBe(
      "Exotic intrinsic",
    );
    expect(formatWeaponPerkSourceLabel("exotic", "Trait")).toBe("Exotic trait");
    expect(formatWeaponPerkSourceLabel("exotic", null)).toBe("Exotic trait");
  });

  it("labels legendary perks", () => {
    expect(formatWeaponPerkSourceLabel("legendary", "Trait")).toBe(
      "Legendary perk",
    );
    expect(formatWeaponPerkSourceLabel("legendary", "Intrinsic")).toBe(
      "Legendary intrinsic",
    );
  });

  it("labels plugs hosted on both tiers", () => {
    expect(formatWeaponPerkSourceLabel("both", "Trait")).toBe(
      "Legendary & exotic",
    );
  });

  it("returns undefined without source", () => {
    expect(formatWeaponPerkSourceLabel(undefined, "Trait")).toBeUndefined();
  });
});
