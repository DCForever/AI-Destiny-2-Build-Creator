import { describe, expect, it } from "vitest";

import { CATALOG_WEAPON_ARCHETYPES } from "@/lib/catalog/filterOptions";
import {
  weaponTypeIconPath,
  WEAPON_TYPE_ICON_PATH,
} from "@/lib/destiny/weaponTypeIcons";

describe("weaponTypeIcons", () => {
  it("maps every catalog weapon type to a public destiny-icons path", () => {
    for (const t of CATALOG_WEAPON_ARCHETYPES) {
      expect(WEAPON_TYPE_ICON_PATH[t]).toMatch(
        /^\/destiny-icons\/weapons\/.+\.svg$/,
      );
      expect(weaponTypeIconPath(t)).toBe(WEAPON_TYPE_ICON_PATH[t]);
    }
  });

  it("resolves aliases used by DIM-style labels", () => {
    expect(weaponTypeIconPath("Submachine Guns")).toBe(
      WEAPON_TYPE_ICON_PATH["Submachine Gun"],
    );
    expect(weaponTypeIconPath("Trace Rifles")).toBe(
      WEAPON_TYPE_ICON_PATH["Trace Rifle"],
    );
    expect(weaponTypeIconPath("unknown")).toBeNull();
  });
});
