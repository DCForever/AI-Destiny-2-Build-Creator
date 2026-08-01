import { describe, expect, it } from "vitest";

import type { FinishGapsResult } from "./finishGaps";
import { finishMissingReasons } from "./finishMissingReasons";

const emptyGaps = (over: Partial<FinishGapsResult> = {}): FinishGapsResult => ({
  variantId: "v1",
  isDefaultVariant: true,
  complete: false,
  gaps: [
    {
      category: "armor",
      status: "needs_set",
      coveringSetId: null,
      coveringSetName: null,
      coveringMode: null,
      emptySlots: ["helmet"],
      filledSlotCount: 0,
      requiredSlotCount: 5,
      resolvedClaimCount: 0,
      canCapture: false,
    },
    {
      category: "weapon",
      status: "needs_fill",
      coveringSetId: "s1",
      coveringSetName: "W",
      coveringMode: "live",
      emptySlots: ["primary"],
      filledSlotCount: 2,
      requiredSlotCount: 3,
      resolvedClaimCount: 2,
      canCapture: false,
    },
    {
      category: "mod",
      status: "satisfied",
      coveringSetId: "m1",
      coveringSetName: "M",
      coveringMode: "live",
      emptySlots: [],
      filledSlotCount: 1,
      requiredSlotCount: 1,
      resolvedClaimCount: 0,
      canCapture: false,
    },
  ],
  nextActionable: null,
  ...over,
});

describe("finishMissingReasons", () => {
  it("lists incomplete categories", () => {
    const reasons = finishMissingReasons(emptyGaps());
    expect(reasons.some((r) => /armor/i.test(r))).toBe(true);
    expect(reasons.some((r) => /weapon/i.test(r))).toBe(true);
    expect(reasons.every((r) => !/mod/i.test(r) || /missing|empty|fill|set/i.test(r))).toBe(true);
  });

  it("returns empty when complete", () => {
    const g = emptyGaps({
      complete: true,
      gaps: emptyGaps().gaps.map((x) => ({ ...x, status: "satisfied" as const, emptySlots: [] })),
    });
    expect(finishMissingReasons(g)).toEqual([]);
  });

  it("mentions equip-ready pins when provided", () => {
    const r = finishMissingReasons(emptyGaps({ complete: true, gaps: [] }), {
      equipReady: false,
      wishlistOrStaleCount: 2,
    });
    expect(r.some((x) => /pin|wishlist|owned/i.test(x))).toBe(true);
  });
});
