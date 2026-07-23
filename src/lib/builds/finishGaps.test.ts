import { describe, expect, it } from "vitest";

import {
  evaluateFinishGaps,
  type FinishAttachmentInput,
} from "@/lib/builds/finishGaps";
import { ARMOR_SLOTS, WEAPON_SLOTS } from "@/lib/sets/schemas";

function eq(
  slots: string[],
): Record<string, { slot: string; itemHash: number; itemName: string }> {
  const out: Record<string, { slot: string; itemHash: number; itemName: string }> =
    {};
  let i = 1;
  for (const slot of slots) {
    out[slot] = { slot, itemHash: i++, itemName: slot };
  }
  return out;
}

describe("evaluateFinishGaps", () => {
  it("orders categories armor → weapon → mod", () => {
    const r = evaluateFinishGaps({
      variantId: "v1",
      isDefaultVariant: true,
      attachments: [],
      equipment: {},
    });
    expect(r.gaps.map((g) => g.category)).toEqual(["armor", "weapon", "mod"]);
  });

  it("needs_set when no covering set and no claims", () => {
    const r = evaluateFinishGaps({
      variantId: "v1",
      isDefaultVariant: true,
      attachments: [],
      equipment: {},
    });
    expect(r.gaps[0]?.status).toBe("needs_set");
    expect(r.gaps[0]?.canCapture).toBe(false);
    expect(r.complete).toBe(false);
  });

  it("capture_available when claims exist without covering set", () => {
    const r = evaluateFinishGaps({
      variantId: "v1",
      isDefaultVariant: true,
      attachments: [],
      equipment: eq(["helmet", "arms"]),
    });
    expect(r.gaps[0]?.status).toBe("capture_available");
    expect(r.gaps[0]?.canCapture).toBe(true);
    expect(r.gaps[0]?.resolvedClaimCount).toBe(2);
  });

  it("needs_fill when covering set attached but slots empty", () => {
    const attachments: FinishAttachmentInput[] = [
      { setId: "a1", mode: "live", setType: "armor", setName: "A" },
    ];
    const r = evaluateFinishGaps({
      variantId: "v1",
      isDefaultVariant: true,
      attachments,
      equipment: {},
    });
    expect(r.gaps[0]?.status).toBe("needs_fill");
    expect(r.gaps[0]?.coveringSetId).toBe("a1");
    expect(r.gaps[0]?.emptySlots).toEqual([...ARMOR_SLOTS]);
  });

  it("satisfied only when covering set and all required slots filled", () => {
    const attachments: FinishAttachmentInput[] = [
      { setId: "a1", mode: "live", setType: "armor", setName: "A" },
      { setId: "w1", mode: "live", setType: "weapon", setName: "W" },
      { setId: "m1", mode: "live", setType: "mod", setName: "M" },
    ];
    const r = evaluateFinishGaps({
      variantId: "v1",
      isDefaultVariant: true,
      attachments,
      equipment: eq([...ARMOR_SLOTS, ...WEAPON_SLOTS]),
    });
    expect(r.gaps.every((g) => g.status === "satisfied")).toBe(true);
    expect(r.complete).toBe(true);
    expect(r.nextActionable).toBeNull();
  });

  it("prefers live covering set over snapshot of same type", () => {
    const r = evaluateFinishGaps({
      variantId: "v1",
      isDefaultVariant: true,
      attachments: [
        { setId: "snap", mode: "snapshot", setType: "armor", setName: "S" },
        { setId: "live", mode: "live", setType: "armor", setName: "L" },
      ],
      equipment: eq([...ARMOR_SLOTS]),
    });
    expect(r.gaps[0]?.coveringSetId).toBe("live");
    expect(r.gaps[0]?.coveringMode).toBe("live");
  });

  it("mod satisfied via hasModCoverage without mod set", () => {
    const r = evaluateFinishGaps({
      variantId: "v1",
      isDefaultVariant: true,
      attachments: [
        { setId: "a1", mode: "live", setType: "armor" },
        { setId: "w1", mode: "live", setType: "weapon" },
      ],
      equipment: eq([...ARMOR_SLOTS, ...WEAPON_SLOTS]),
      hasModCoverage: true,
    });
    expect(r.gaps.find((g) => g.category === "mod")?.status).toBe("satisfied");
    expect(r.complete).toBe(true);
  });

  it("nextActionable skips session-skipped categories then falls back", () => {
    const r = evaluateFinishGaps({
      variantId: "v1",
      isDefaultVariant: true,
      attachments: [],
      equipment: {},
      skippedKeys: ["armor"],
    });
    expect(r.nextActionable?.category).toBe("weapon");
  });
});
