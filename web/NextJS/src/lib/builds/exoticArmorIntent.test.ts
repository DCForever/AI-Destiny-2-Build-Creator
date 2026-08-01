import { describe, expect, it } from "vitest";

import {
  isExoticClassItemSlot,
  isIdentityExoticArmorChange,
  modeFromArmorSlot,
} from "@/lib/builds/exoticArmorIntent";

describe("exoticArmorIntent", () => {
  it("detects ClassItem slot", () => {
    expect(isExoticClassItemSlot("ClassItem")).toBe(true);
    expect(isExoticClassItemSlot("Helmet")).toBe(false);
    expect(isExoticClassItemSlot(null)).toBe(false);
  });

  it("derives classic vs class_item_intent modes", () => {
    expect(modeFromArmorSlot("Helmet", 1)).toBe("classic");
    expect(modeFromArmorSlot("ClassItem", 2)).toBe("class_item_intent");
    expect(modeFromArmorSlot(null, null)).toBe("classic");
  });

  it("skips identity confirm for class-item → class-item swaps", () => {
    expect(
      isIdentityExoticArmorChange(10, 20, "class_item_intent", "class_item_intent"),
    ).toBe(false);
  });

  it("requires identity confirm for classic hash swaps and mode flips", () => {
    expect(isIdentityExoticArmorChange(10, 20, "classic", "classic")).toBe(true);
    expect(
      isIdentityExoticArmorChange(10, 20, "classic", "class_item_intent"),
    ).toBe(true);
    expect(isIdentityExoticArmorChange(null, 20, "classic", "class_item_intent")).toBe(true);
    expect(isIdentityExoticArmorChange(20, null, "class_item_intent", "classic")).toBe(true);
  });

  it("is not an identity change when hash unchanged", () => {
    expect(isIdentityExoticArmorChange(10, 10, "classic", "classic")).toBe(false);
  });
});
