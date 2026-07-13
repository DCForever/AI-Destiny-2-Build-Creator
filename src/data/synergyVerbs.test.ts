import { describe, expect, it } from "vitest";

import {
  impliedElementForVerb,
  resolveVerbSubType,
  SYNERGY_VERBS,
} from "./synergyVerbs";

describe("impliedElementForVerb", () => {
  it("maps Ionic Trace and other Arc verbs to Arc", () => {
    expect(impliedElementForVerb("Ionic Trace")).toBe("Arc");
    expect(impliedElementForVerb("Jolt")).toBe("Arc");
    expect(impliedElementForVerb("Bolt Charge")).toBe("Arc");
  });

  it("maps Solar / Void / Stasis / Strand verbs", () => {
    expect(impliedElementForVerb("Scorch")).toBe("Solar");
    expect(impliedElementForVerb("Volatile")).toBe("Void");
    expect(impliedElementForVerb("Freeze")).toBe("Stasis");
    expect(impliedElementForVerb("Sever")).toBe("Strand");
  });

  it("accepts aliases and plurals", () => {
    expect(impliedElementForVerb("Suppress")).toBe("Void");
    expect(impliedElementForVerb("Stasis Shards")).toBe("Stasis");
    expect(impliedElementForVerb("Arc Ionic Traces")).toBe("Arc");
  });

  it("returns null for agnostic keywords", () => {
    expect(impliedElementForVerb("Armor Charge")).toBeNull();
    expect(impliedElementForVerb("Exhaust")).toBeNull();
    expect(impliedElementForVerb("Sliding")).toBeNull();
  });

  it("every curated verb has a defined element field (null or element)", () => {
    for (const v of SYNERGY_VERBS) {
      expect("element" in v).toBe(true);
      if (v.element != null) {
        expect(impliedElementForVerb(v.name)).toBe(v.element);
      } else {
        expect(impliedElementForVerb(v.name)).toBeNull();
      }
      expect(resolveVerbSubType(v.name)).toBe(v.name);
    }
  });
});
