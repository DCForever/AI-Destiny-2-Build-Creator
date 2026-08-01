import { describe, expect, it } from "vitest";

import { toCombinationPiece, toSetBonusSummary } from "./combinationDto";
import type { CandidatePiece } from "./types";

function candidate(extra: Partial<CandidatePiece> = {}): CandidatePiece {
  return {
    slot: "helmet",
    itemHash: 1,
    instanceId: "inst-1",
    isExotic: false,
    statValues: { Melee: 10 },
    energyCapacity: 10,
    usedInSets: [],
    ...extra,
  };
}

describe("toCombinationPiece", () => {
  it("maps usedInSets to usedInOtherSets (id/name refs)", () => {
    const piece = candidate({
      usedInSets: [
        { id: "set-a", name: "Alpha" },
        { id: "set-b", name: "Bravo" },
      ],
    });
    const dto = toCombinationPiece(piece);
    expect(dto.usedInOtherSets).toEqual([
      { id: "set-a", name: "Alpha" },
      { id: "set-b", name: "Bravo" },
    ]);
  });

  it("always exposes an empty usedInOtherSets array when unused", () => {
    expect(toCombinationPiece(candidate()).usedInOtherSets).toEqual([]);
  });

  it("carries slot, hashes, exotic flag, and set-bonus key", () => {
    const dto = toCombinationPiece(
      candidate({ slot: "chest", itemHash: 99, isExotic: true, setBonusKey: "TechSec" }),
    );
    expect(dto).toMatchObject({
      slot: "chest",
      itemHash: 99,
      isExotic: true,
      setBonusKey: "TechSec",
    });
  });
});

describe("toSetBonusSummary", () => {
  it("counts pieces per set-bonus family with 2pc/4pc activation flags", () => {
    const kit = [
      candidate({ slot: "helmet", setBonusKey: "TechSec" }),
      candidate({ slot: "arms", setBonusKey: "TechSec" }),
      candidate({ slot: "chest", setBonusKey: "TechSec" }),
      candidate({ slot: "legs", setBonusKey: "TechSec" }),
      candidate({ slot: "class_item", setBonusKey: "Bushido" }),
    ];
    const summary = toSetBonusSummary(kit);
    const tech = summary.find((s) => s.setBonusKey === "TechSec");
    const bushido = summary.find((s) => s.setBonusKey === "Bushido");
    expect(tech).toMatchObject({ pieceCount: 4, active2pc: true, active4pc: true });
    expect(bushido).toMatchObject({ pieceCount: 1, active2pc: false, active4pc: false });
  });
});
