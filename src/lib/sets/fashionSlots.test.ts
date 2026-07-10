import { describe, expect, it } from "vitest";

import {
  FASHION_SLOTS,
  isFashionSlot,
  isSlotValidForSetType,
} from "@/lib/sets/schemas";

describe("fashion slots", () => {
  it("allows FASHION_SLOTS for fashion sets", () => {
    for (const slot of FASHION_SLOTS) {
      expect(isSlotValidForSetType("fashion", slot)).toBe(true);
      expect(isFashionSlot(slot)).toBe(true);
    }
  });

  it("rejects combat and unknown slots on fashion sets", () => {
    expect(isSlotValidForSetType("fashion", "primary")).toBe(false);
    expect(isSlotValidForSetType("fashion", "emote")).toBe(false);
    expect(isFashionSlot("emote")).toBe(false);
  });
});
