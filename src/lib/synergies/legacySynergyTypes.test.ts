import { describe, expect, it } from "vitest";

import { normalizeLegacySynergyType } from "@/lib/synergies/legacySynergyTypes";

describe("normalizeLegacySynergyType", () => {
  it("maps kinetic_weapon to element + Kinetic", () => {
    expect(normalizeLegacySynergyType("kinetic_weapon")).toEqual({
      type: "element",
      subType: "Kinetic",
    });
  });

  it("maps damage to dps", () => {
    expect(normalizeLegacySynergyType("damage")).toEqual({
      type: "dps",
      subType: null,
    });
  });

  it("passes through creatable types", () => {
    expect(normalizeLegacySynergyType("verb")).toEqual({
      type: "verb",
      subType: null,
    });
  });
});
