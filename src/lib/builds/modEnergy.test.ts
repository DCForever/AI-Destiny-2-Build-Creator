import { describe, expect, it } from "vitest";

import {
  armorEnergyCapacity,
  isModLegalForArmorSlot,
  sumEnergyCosts,
} from "./modEnergy";

describe("armorEnergyCapacity", () => {
  it("returns 10 for tier ≤4 and unknown", () => {
    expect(armorEnergyCapacity(null)).toBe(10);
    expect(armorEnergyCapacity(undefined)).toBe(10);
    expect(armorEnergyCapacity(4)).toBe(10);
    expect(armorEnergyCapacity(3)).toBe(10);
  });

  it("returns 11 for tier 5+", () => {
    expect(armorEnergyCapacity(5)).toBe(11);
    expect(armorEnergyCapacity(6)).toBe(11);
  });
});

describe("sumEnergyCosts", () => {
  it("sums positive costs and ignores nulls", () => {
    expect(sumEnergyCosts([1, 2, null, 0, 3])).toBe(6);
  });
});

describe("isModLegalForArmorSlot", () => {
  it("allows general on any piece", () => {
    expect(isModLegalForArmorSlot("helmet", "general")).toBe(true);
    expect(isModLegalForArmorSlot("legs", "tuning")).toBe(true);
  });

  it("requires matching category for piece mods", () => {
    expect(isModLegalForArmorSlot("helmet", "helmet")).toBe(true);
    expect(isModLegalForArmorSlot("helmet", "arms")).toBe(false);
    expect(isModLegalForArmorSlot("class_item", "classItem")).toBe(true);
  });
});
