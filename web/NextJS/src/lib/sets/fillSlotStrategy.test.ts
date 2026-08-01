import { describe, expect, it } from "vitest";

import { fillStrategyForSet } from "./fillSlotStrategy";
import { isModSetSlot, isSlotValidForSetType, modSlotForHash } from "./schemas";

describe("fillStrategyForSet", () => {
  it("uses weapon catalog for weapon slots", () => {
    expect(fillStrategyForSet("weapon", "primary")).toEqual({
      kind: "catalog",
      catalogKind: "weapons",
    });
  });

  it("uses armor catalog for armor slots", () => {
    expect(fillStrategyForSet("armor", "helmet")).toEqual({
      kind: "catalog",
      catalogKind: "armor",
    });
  });

  it("uses mods manifest search for mod sets — never weapons", () => {
    const strategy = fillStrategyForSet("mod", "helmet");
    expect(strategy.kind).toBe("manifest");
    if (strategy.kind === "manifest") {
      expect(strategy.category).toBe("mods");
      expect(strategy.label.toLowerCase()).toMatch(/helmet/);
    }
  });

  it("uses exotic manifest categories for pair slots", () => {
    expect(fillStrategyForSet("pair", "exotic_weapon")).toMatchObject({
      kind: "manifest",
      category: "exotic-weapons",
    });
    expect(fillStrategyForSet("pair", "exotic_armor")).toMatchObject({
      kind: "manifest",
      category: "exotic-armor",
    });
  });

  it("uses manual hash+name for fashion slots — never weapons catalog", () => {
    for (const slot of [
      "shader_ornament",
      "ghost",
      "sparrow",
      "ship",
      "emblem",
      "finisher",
    ]) {
      const strategy = fillStrategyForSet("fashion", slot);
      expect(strategy.kind).toBe("manual_hash_name");
      if (strategy.kind === "manual_hash_name") {
        expect(strategy.label.toLowerCase()).toMatch(/fashion|cosmetic/);
      }
    }
  });
});

describe("mod set slots", () => {
  it("accepts legacy mod keys and per-piece keys", () => {
    expect(isModSetSlot("mod")).toBe(true);
    expect(isModSetSlot(modSlotForHash(123))).toBe(true);
    expect(isSlotValidForSetType("mod", "mod")).toBe(true);
    expect(isSlotValidForSetType("mod", "mod:999")).toBe(true);
    expect(isSlotValidForSetType("mod", "helmet")).toBe(true);
    expect(isSlotValidForSetType("mod", "helmet:42")).toBe(true);
    expect(isSlotValidForSetType("mod", "primary")).toBe(false);
  });
});
