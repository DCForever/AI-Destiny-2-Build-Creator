import { describe, expect, it } from "vitest";

import { explainEmpty, type EmptyReasonInput } from "./explainEmpty";

function base(overrides: Partial<EmptyReasonInput> = {}): EmptyReasonInput {
  return {
    hasInventory: true,
    classArmorCount: 5,
    lockedExoticAvailable: true,
    setBonusReachable: true,
    thresholdsFilteredAll: false,
    ...overrides,
  };
}

describe("explainEmpty", () => {
  it("reports NO_INVENTORY first", () => {
    expect(explainEmpty(base({ hasInventory: false })).code).toBe("NO_INVENTORY");
  });

  it("reports NO_CLASS_ARMOR when no class armor exists", () => {
    expect(explainEmpty(base({ classArmorCount: 0 })).code).toBe("NO_CLASS_ARMOR");
  });

  it("reports EXOTIC_UNAVAILABLE when the locked exotic is missing", () => {
    const reason = explainEmpty(
      base({ lockedExoticItemHash: 555, lockedExoticAvailable: false }),
    );
    expect(reason.code).toBe("EXOTIC_UNAVAILABLE");
    expect(reason.details).toMatchObject({ lockedExoticItemHash: 555 });
  });

  it("reports SET_BONUS_UNSATISFIABLE when goals cannot be met", () => {
    expect(
      explainEmpty(
        base({
          setBonusGoals: [{ setBonusKey: "TechSec", minPieces: 4 }],
          setBonusReachable: false,
        }),
      ).code,
    ).toBe("SET_BONUS_UNSATISFIABLE");
  });

  it("reports THRESHOLDS_UNMET only when thresholds are required", () => {
    expect(
      explainEmpty(base({ requireThresholds: true, thresholdsFilteredAll: true })).code,
    ).toBe("THRESHOLDS_UNMET");
  });

  it("falls back to NO_VALID_KITS", () => {
    expect(explainEmpty(base()).code).toBe("NO_VALID_KITS");
  });
});
