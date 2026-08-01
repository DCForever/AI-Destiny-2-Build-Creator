import { describe, expect, it } from "vitest";

import { exoticNamesMatch, normalizeExoticName } from "./normalizeExoticName";

describe("normalizeExoticName", () => {
  it("lowercases and collapses whitespace", () => {
    expect(normalizeExoticName("  Crown   of Tempests ")).toBe("crown of tempests");
  });

  it("strips diacritics", () => {
    expect(exoticNamesMatch("Café", "Cafe")).toBe(true);
  });
});
