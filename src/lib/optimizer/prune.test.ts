import { describe, expect, it } from "vitest";

import { DEFAULT_PRUNE_K, prunePiecesForSlot } from "./prune";
import type { CandidatePiece } from "./types";

function helmet(id: number, melee: number, extra: Partial<CandidatePiece> = {}): CandidatePiece {
  return {
    slot: "helmet",
    itemHash: id,
    instanceId: `h-${id}`,
    isExotic: false,
    statValues: { Melee: melee },
    energyCapacity: 10,
    usedInSets: [],
    ...extra,
  };
}

describe("prune", () => {
  it("keeps only the top-K by prioritized stats", () => {
    const pieces = Array.from({ length: DEFAULT_PRUNE_K + 5 }, (_, i) => helmet(i, i));
    const kept = prunePiecesForSlot(pieces, { priorities: ["Melee"], k: 4 });
    expect(kept).toHaveLength(4);
    const meleeValues = kept.map((p) => p.statValues.Melee ?? 0).sort((a, b) => b - a);
    expect(meleeValues[0]).toBe(pieces.length - 1);
  });

  it("always retains locked exotic copies even with low stats", () => {
    const pieces = [
      helmet(1, 100),
      helmet(2, 90),
      helmet(555, 1, { isExotic: true }),
    ];
    const kept = prunePiecesForSlot(pieces, { priorities: ["Melee"], k: 1, lockedExoticItemHash: 555 });
    expect(kept.some((p) => p.itemHash === 555)).toBe(true);
  });

  it("retains pieces needed for set-bonus goals", () => {
    const pieces = [
      helmet(1, 100),
      helmet(2, 95),
      helmet(3, 1, { setBonusKey: "TechSec" }),
    ];
    const kept = prunePiecesForSlot(pieces, {
      priorities: ["Melee"],
      k: 1,
      setBonusGoals: [{ setBonusKey: "TechSec", minPieces: 2 }],
    });
    expect(kept.some((p) => p.setBonusKey === "TechSec")).toBe(true);
  });
});
