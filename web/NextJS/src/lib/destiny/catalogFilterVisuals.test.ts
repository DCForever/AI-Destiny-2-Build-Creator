import { describe, expect, it } from "vitest";

import { CATALOG_ARMOR_ARCHETYPES } from "@/lib/catalog/filterOptions";
import {
  AMMO_OFFICIAL,
  ARMOR_ARCHETYPE_OFFICIAL,
  ELEMENT_OFFICIAL,
  visualForAmmo,
  visualForArmorArchetype,
  visualForElement,
  visualForWeaponFrame,
  WEAPON_FRAME_OFFICIAL,
} from "@/lib/destiny/catalogFilterVisuals";

describe("catalogFilterVisuals", () => {
  it("covers all armor archetypes", () => {
    for (const name of CATALOG_ARMOR_ARCHETYPES) {
      expect(ARMOR_ARCHETYPE_OFFICIAL[name]?.icon).toMatch(
        /^\/common\/destiny2_content\//,
      );
      expect(visualForArmorArchetype(name)?.icon).toBe(
        ARMOR_ARCHETYPE_OFFICIAL[name].icon,
      );
    }
  });

  it("resolves common weapon frames and suffix variants", () => {
    expect(visualForWeaponFrame("Adaptive Frame")?.icon).toBe(
      WEAPON_FRAME_OFFICIAL["Adaptive Frame"].icon,
    );
    expect(visualForWeaponFrame("Adaptive")?.icon).toBe(
      WEAPON_FRAME_OFFICIAL["Adaptive Frame"].icon,
    );
    expect(visualForWeaponFrame("Rapid-Fire Frame")?.icon).toBeTruthy();
    expect(visualForWeaponFrame("unknown frame xyz")).toBeNull();
  });

  it("resolves element and ammo", () => {
    expect(visualForElement("Solar")?.icon).toBe(ELEMENT_OFFICIAL.Solar.icon);
    expect(visualForAmmo("Heavy")?.icon).toBe(AMMO_OFFICIAL.Heavy.icon);
    expect(visualForElement("Nope")).toBeNull();
  });
});
