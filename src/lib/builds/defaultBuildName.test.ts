import { describe, expect, it } from "vitest";

import { deriveDefaultBuildName } from "./defaultBuildName";

describe("deriveDefaultBuildName", () => {
  it("includes present segments and omits missing ones", () => {
    const full = deriveDefaultBuildName({
      className: "Warlock",
      subclass: { name: "Stormcaller", super: "Chaos Reach", element: "Arc" },
      pinnedSuper: null,
      exoticArmorHash: 1,
      exoticArmorName: "Fallen Sunstar",
      exoticWeaponHash: 2,
      exoticWeaponName: "Riskrunner",
      synergyNames: ["Ionic Traces", "Jolt"],
    });
    expect(full).toBe(
      "Warlock · Arc · Chaos Reach · Fallen Sunstar · Riskrunner · Ionic Traces + Jolt",
    );
    expect(full.toLowerCase()).not.toContain("none");

    const minimal = deriveDefaultBuildName({
      className: "Titan",
      subclass: { name: "Sunbreaker", super: "" },
      synergyNames: ["Melee"],
    });
    expect(minimal).toBe("Titan · Melee");
    expect(minimal).not.toContain("None");
  });

  it("uses pinned super over subclass super", () => {
    const name = deriveDefaultBuildName({
      className: "Warlock",
      subclass: { name: "Stormcaller", super: "Stormtrance" },
      pinnedSuper: "Chaos Reach",
    });
    expect(name).toContain("Chaos Reach");
    expect(name).not.toContain("Stormtrance");
  });
});
