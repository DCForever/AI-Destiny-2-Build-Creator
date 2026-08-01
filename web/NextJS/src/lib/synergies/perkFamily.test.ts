import { describe, expect, it } from "vitest";

import {
  buildPerkFamilyIndex,
  familyHashesFor,
  perkFamilyKey,
  selectedPerksIncludeFamily,
} from "@/lib/synergies/perkFamily";

describe("perkFamilyKey", () => {
  it("strips enhanced suffixes and prefixes", () => {
    expect(perkFamilyKey("Zen Moment")).toBe("zen moment");
    expect(perkFamilyKey("Zen Moment Enhanced")).toBe("zen moment");
    expect(perkFamilyKey("Enhanced Zen Moment")).toBe("zen moment");
    expect(perkFamilyKey("Zen Moment (Enhanced)")).toBe("zen moment");
  });
});

describe("buildPerkFamilyIndex / selectedPerksIncludeFamily", () => {
  const index = buildPerkFamilyIndex([
    { hash: 100, name: "Zen Moment" },
    { hash: 101, name: "Zen Moment Enhanced" },
    { hash: 200, name: "Adagio" },
  ]);

  it("groups base and enhanced under one family", () => {
    expect(familyHashesFor(100, index)).toEqual(new Set([100, 101]));
    expect(familyHashesFor(101, index)).toEqual(new Set([100, 101]));
    expect(familyHashesFor(200, index)).toEqual(new Set([200]));
  });

  it("matches exact hash without index", () => {
    expect(selectedPerksIncludeFamily([100], 100)).toBe(true);
    expect(selectedPerksIncludeFamily([101], 100)).toBe(false);
  });

  it("matches enhanced when link is base (DBR-SYN-014a)", () => {
    expect(selectedPerksIncludeFamily([101], 100, index)).toBe(true);
  });

  it("matches base when link is enhanced", () => {
    expect(selectedPerksIncludeFamily([100], 101, index)).toBe(true);
  });

  it("does not cross families", () => {
    expect(selectedPerksIncludeFamily([200], 100, index)).toBe(false);
  });

  it("unknown hash is singleton family", () => {
    expect(familyHashesFor(999, index)).toEqual(new Set([999]));
    expect(selectedPerksIncludeFamily([999], 999, index)).toBe(true);
  });
});
