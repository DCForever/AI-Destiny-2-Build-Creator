import { describe, expect, it } from "vitest";

import {
  CATALOG_ELEMENTS,
  CATALOG_WEAPON_ARCHETYPES,
  toggleFilterValue,
} from "./filterOptions";

describe("filterOptions", () => {
  it("toggles values in multi-select lists", () => {
    expect(toggleFilterValue([], "Solar")).toEqual(["Solar"]);
    expect(toggleFilterValue(["Solar"], "Solar")).toEqual([]);
    expect(toggleFilterValue(["Solar"], "Void")).toEqual(["Solar", "Void"]);
  });

  it("exports stable chip catalogs for fill-slot and browse", () => {
    expect(CATALOG_ELEMENTS).toContain("Solar");
    expect(CATALOG_WEAPON_ARCHETYPES).toContain("Hand Cannon");
  });
});
