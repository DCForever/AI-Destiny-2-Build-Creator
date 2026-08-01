import { describe, expect, it } from "vitest";

import { enumerateKits, groupBySlot } from "./enumerate";
import { ARMOR_OPTIMIZER_SLOTS, type ArmorSlot, type CandidatePiece } from "./types";

function piece(slot: ArmorSlot, itemHash: number, extra: Partial<CandidatePiece> = {}): CandidatePiece {
  return {
    slot,
    itemHash,
    instanceId: `${slot}-${itemHash}`,
    isExotic: false,
    statValues: {},
    energyCapacity: 10,
    usedInSets: [],
    ...extra,
  };
}

function oneEach(extra: Partial<Record<ArmorSlot, Partial<CandidatePiece>>> = {}): CandidatePiece[] {
  return ARMOR_OPTIMIZER_SLOTS.map((slot, i) => piece(slot, 100 + i, extra[slot]));
}

describe("enumerate", () => {
  it("returns no kits when a slot is empty", () => {
    const bySlot = groupBySlot(oneEach().filter((p) => p.slot !== "legs"));
    const result = enumerateKits(bySlot, { constraints: {} });
    expect(result.kits).toHaveLength(0);
  });

  it("produces the single complete kit from one piece per slot", () => {
    const result = enumerateKits(groupBySlot(oneEach()), { constraints: {} });
    expect(result.kits).toHaveLength(1);
    expect(result.kits[0]).toHaveLength(5);
  });

  it("never emits kits with two exotics", () => {
    const pieces = [
      piece("helmet", 1, { isExotic: true }),
      piece("helmet", 2),
      piece("arms", 3, { isExotic: true }),
      piece("chest", 4),
      piece("legs", 5),
      piece("class_item", 6),
    ];
    const result = enumerateKits(groupBySlot(pieces), { constraints: {} });
    expect(result.kits.length).toBeGreaterThan(0);
    for (const kit of result.kits) {
      expect(kit.filter((p) => p.isExotic).length).toBeLessThanOrEqual(1);
    }
  });

  it("filters by locked exotic and set-bonus goals", () => {
    const pieces = [
      piece("helmet", 555, { isExotic: true, setBonusKey: "A" }),
      piece("helmet", 10, { setBonusKey: "A" }),
      piece("arms", 11, { setBonusKey: "A" }),
      piece("chest", 12, { setBonusKey: "A" }),
      piece("legs", 13),
      piece("class_item", 14),
    ];
    const result = enumerateKits(groupBySlot(pieces), {
      constraints: {
        lockedExoticItemHash: 555,
        setBonusGoals: [{ setBonusKey: "A", minPieces: 2 }],
      },
    });
    expect(result.kits.length).toBeGreaterThan(0);
    for (const kit of result.kits) {
      expect(kit.some((p) => p.itemHash === 555)).toBe(true);
    }
  });

  it("truncates and flags when the evaluation cap is hit", () => {
    const many: CandidatePiece[] = [];
    for (const slot of ARMOR_OPTIMIZER_SLOTS) {
      for (let i = 0; i < 4; i += 1) many.push(piece(slot, i));
    }
    const result = enumerateKits(groupBySlot(many), { constraints: {}, maxCombinations: 10 });
    expect(result.truncated).toBe(true);
    expect(result.evaluatedCount).toBeLessThanOrEqual(11);
  });
});
