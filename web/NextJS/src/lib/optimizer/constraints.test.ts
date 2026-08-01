import { describe, expect, it } from "vitest";

import {
  buildSetBonusSummary,
  countExotics,
  isKitValid,
  satisfiesSetBonusGoals,
  setBonusPieceCounts,
} from "./constraints";
import { ARMOR_OPTIMIZER_SLOTS, type CandidatePiece } from "./types";

function piece(overrides: Partial<CandidatePiece> & Pick<CandidatePiece, "slot">): CandidatePiece {
  return {
    itemHash: 1,
    instanceId: `${overrides.slot}-${overrides.itemHash ?? 1}`,
    isExotic: false,
    statValues: {},
    energyCapacity: 10,
    usedInSets: [],
    ...overrides,
  };
}

function fullKit(overrides: Partial<Record<CandidatePiece["slot"], Partial<CandidatePiece>>> = {}): CandidatePiece[] {
  return ARMOR_OPTIMIZER_SLOTS.map((slot, i) =>
    piece({ slot, itemHash: 100 + i, ...overrides[slot] }),
  );
}

describe("constraints", () => {
  it("counts exotics across the kit", () => {
    const kit = fullKit({ helmet: { isExotic: true } });
    expect(countExotics(kit)).toBe(1);
  });

  it("rejects kits with two exotics", () => {
    const kit = fullKit({ helmet: { isExotic: true }, chest: { isExotic: true } });
    expect(isKitValid(kit, {})).toBe(false);
  });

  it("requires exactly five distinct slots", () => {
    const kit = fullKit().slice(0, 4);
    expect(isKitValid(kit, {})).toBe(false);
  });

  it("requires the locked exotic hash to be present", () => {
    const kit = fullKit({ helmet: { isExotic: true, itemHash: 555 } });
    expect(isKitValid(kit, { lockedExoticItemHash: 555 })).toBe(true);
    expect(isKitValid(kit, { lockedExoticItemHash: 999 })).toBe(false);
  });

  it("honors requireExotic", () => {
    const kit = fullKit();
    expect(isKitValid(kit, { requireExotic: true })).toBe(false);
    const exoticKit = fullKit({ helmet: { isExotic: true } });
    expect(isKitValid(exoticKit, { requireExotic: true })).toBe(true);
  });

  it("counts set-bonus pieces by key", () => {
    const kit = fullKit({
      helmet: { setBonusKey: "TechSec" },
      arms: { setBonusKey: "TechSec" },
      chest: { setBonusKey: "Bushido" },
    });
    const counts = setBonusPieceCounts(kit);
    expect(counts.get("TechSec")).toBe(2);
    expect(counts.get("Bushido")).toBe(1);
  });

  it("satisfies set-bonus goals only when piece counts reach minPieces", () => {
    const kit = fullKit({
      helmet: { setBonusKey: "TechSec" },
      arms: { setBonusKey: "TechSec" },
    });
    expect(satisfiesSetBonusGoals(kit, [{ setBonusKey: "TechSec", minPieces: 2 }])).toBe(true);
    expect(satisfiesSetBonusGoals(kit, [{ setBonusKey: "TechSec", minPieces: 4 }])).toBe(false);
    expect(satisfiesSetBonusGoals(kit, [])).toBe(true);
  });

  it("summarizes 2pc/4pc activation", () => {
    const kit = fullKit({
      helmet: { setBonusKey: "TechSec" },
      arms: { setBonusKey: "TechSec" },
      chest: { setBonusKey: "TechSec" },
      legs: { setBonusKey: "TechSec" },
    });
    const summary = buildSetBonusSummary(kit);
    const tech = summary.find((s) => s.setBonusKey === "TechSec");
    expect(tech).toMatchObject({ pieceCount: 4, active2pc: true, active4pc: true });
  });
});
