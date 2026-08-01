import { describe, expect, it } from "vitest";

import type { SetBonusRecord } from "@/lib/manifest/types/records";

import { buildSetBonusByItemHash, lookupSetBonus } from "./armorSetBonus";

const DEEP_STONE_CRYPT: SetBonusRecord = {
  hash: 12345,
  name: "Deep Stone Crypt",
  searchName: "deep stone crypt",
  icon: null,
  perks: [
    { requiredCount: 2, name: "Scanner", description: "Highlights nearby threats." },
    { requiredCount: 4, name: "Reaper", description: "Defeating targets spawns an orb." },
  ],
  itemHashes: [111, 222, 333],
};

const OTHER_SET: SetBonusRecord = {
  hash: 67890,
  name: "Iron Will",
  searchName: "iron will",
  icon: null,
  perks: [{ requiredCount: 2, name: " Mantle", description: "Bonus stat." }],
  itemHashes: [444],
};

describe("armorSetBonus", () => {
  it("inverts itemHashes so each member maps to its set-bonus record", () => {
    const map = buildSetBonusByItemHash([DEEP_STONE_CRYPT, OTHER_SET]);
    expect(map.get(111)?.hash).toBe(12345);
    expect(map.get(333)?.hash).toBe(12345);
    expect(map.get(444)?.hash).toBe(67890);
    expect(map.size).toBe(4);
  });

  it("looks up a member and returns the 2-piece and 4-piece summary", () => {
    const map = buildSetBonusByItemHash([DEEP_STONE_CRYPT]);
    const summary = lookupSetBonus(map, 222);
    expect(summary).not.toBeNull();
    expect(summary?.hash).toBe(12345);
    expect(summary?.name).toBe("Deep Stone Crypt");
    expect(summary?.tiers).toEqual([
      { requiredCount: 2, name: "Scanner", description: "Highlights nearby threats." },
      { requiredCount: 4, name: "Reaper", description: "Defeating targets spawns an orb." },
    ]);
  });

  it("returns null for an item that is not part of any set", () => {
    const map = buildSetBonusByItemHash([DEEP_STONE_CRYPT]);
    expect(lookupSetBonus(map, 999)).toBeNull();
  });
});
