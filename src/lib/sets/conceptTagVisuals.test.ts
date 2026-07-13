import { describe, expect, it } from "vitest";

import {
  allConceptTagDesignationRefs,
  conceptTagDesignationRefs,
  conceptTagVisual,
} from "./conceptTagVisuals";

describe("conceptTagVisual", () => {
  it("maps element tags to element designations with accent color", () => {
    const v = conceptTagVisual("arc");
    expect(v.label).toBe("Arc");
    expect(v.designation).toEqual({ type: "element", subType: "Arc" });
    expect(v.accentColor).toBeTruthy();
    expect(v.hasGlyphFallback).toBe(true);
  });

  it("maps grenade playstyle to ability designation", () => {
    const v = conceptTagVisual("grenade");
    expect(v.label).toBe("Grenade");
    expect(v.designation).toEqual({ type: "grenade", subType: "Grenade" });
    expect(v.hasGlyphFallback).toBe(false);
  });

  it("maps melee and super playstyle tags", () => {
    expect(conceptTagVisual("melee").designation).toEqual({
      type: "melee",
      subType: "Melee",
    });
    expect(conceptTagVisual("super").designation).toEqual({
      type: "super",
      subType: "Super",
    });
  });

  it("uses verb designations for healing/support/dps", () => {
    expect(conceptTagVisual("healing").designation?.type).toBe("verb");
    expect(conceptTagVisual("dps").designation?.subType).toBe("Radiant");
  });

  it("activity tags stay text-only (no designation)", () => {
    const v = conceptTagVisual("raid");
    expect(v.label).toBe("Raid");
    expect(v.designation).toBeNull();
    expect(v.hasGlyphFallback).toBe(false);
  });
});

describe("conceptTagDesignationRefs", () => {
  it("dedupes refs and skips text-only tags", () => {
    const refs = conceptTagDesignationRefs(["arc", "solar", "raid", "arc"]);
    expect(refs).toHaveLength(2);
    expect(refs.map((r) => r.subType)).toEqual(["Arc", "Solar"]);
  });

  it("allConceptTagDesignationRefs includes elements and playstyle", () => {
    const refs = allConceptTagDesignationRefs();
    const keys = new Set(refs.map((r) => `${r.type}::${r.subType}`));
    expect(keys.has("element::Arc")).toBe(true);
    expect(keys.has("grenade::Grenade")).toBe(true);
    expect(keys.has("melee::Melee")).toBe(true);
  });
});
