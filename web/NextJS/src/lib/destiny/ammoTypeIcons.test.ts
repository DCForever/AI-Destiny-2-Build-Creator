import { describe, expect, it } from "vitest";

import { CATALOG_AMMO_TYPES } from "@/lib/catalog/filterOptions";
import {
  AMMO_TYPE_ICON_PATH,
  ammoTypeIconPath,
} from "./ammoTypeIcons";

describe("ammoTypeIcons", () => {
  it("maps every catalog ammo type to a public destiny-icons path", () => {
    for (const ammo of CATALOG_AMMO_TYPES) {
      expect(AMMO_TYPE_ICON_PATH[ammo]).toMatch(
        /^\/destiny-icons\/general\/ammo-.+\.svg$/,
      );
      expect(ammoTypeIconPath(ammo)).toBe(AMMO_TYPE_ICON_PATH[ammo]);
    }
  });

  it("returns null for unknown ammo", () => {
    expect(ammoTypeIconPath(null)).toBeNull();
    expect(ammoTypeIconPath("")).toBeNull();
    expect(ammoTypeIconPath("Unknown")).toBeNull();
  });
});
