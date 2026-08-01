import { describe, expect, it } from "vitest";

import {
  evaluateModSetPieceEnergy,
  itemsForModArmorSlot,
  isLegacyModItem,
} from "./modSetEnergy";

describe("modSetEnergy", () => {
  it("groups items by armor piece key", () => {
    const items = [
      { slot: "helmet:1" },
      { slot: "helmet:2" },
      { slot: "arms:3" },
      { slot: "mod:9" },
      { slot: "helmet:4", removedAt: "x" },
    ];
    expect(itemsForModArmorSlot(items, "helmet")).toHaveLength(2);
    expect(itemsForModArmorSlot(items, "arms")).toHaveLength(1);
  });

  it("blocks over-capacity adds", () => {
    const r = evaluateModSetPieceEnergy({
      armorSlot: "helmet",
      existingCosts: [4, 4],
      candidateCost: 3,
    });
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.capacity).toBe(10);
  });

  it("allows fills within capacity", () => {
    expect(
      evaluateModSetPieceEnergy({
        armorSlot: "chest",
        existingCosts: [3, 2],
        candidateCost: 5,
      }).ok,
    ).toBe(true);
  });

  it("detects legacy slots", () => {
    expect(isLegacyModItem("mod")).toBe(true);
    expect(isLegacyModItem("mod:1")).toBe(true);
    expect(isLegacyModItem("helmet:1")).toBe(false);
  });
});
