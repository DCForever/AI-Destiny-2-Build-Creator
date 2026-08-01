import { describe, expect, it } from "vitest";

import type { FinishGap } from "@/lib/builds/finishGaps";
import {
  finishCategoryToSetType,
  firstEmptyRequiredSlot,
  resolvePostMutationStep,
  showFinishCreateActions,
} from "@/lib/builds/finishNextSlot";

function gap(partial: Partial<FinishGap> & Pick<FinishGap, "category" | "status">): FinishGap {
  return {
    coveringSetId: null,
    coveringSetName: null,
    coveringMode: null,
    emptySlots: [],
    filledSlotCount: 0,
    requiredSlotCount: 0,
    resolvedClaimCount: 0,
    canCapture: false,
    ...partial,
  };
}

describe("finishNextSlot", () => {
  it("maps category to set type", () => {
    expect(finishCategoryToSetType("weapon")).toBe("weapon");
    expect(finishCategoryToSetType("armor")).toBe("armor");
    expect(finishCategoryToSetType("mod")).toBe("mod");
  });

  it("returns first empty weapon slot in primary→special→heavy order", () => {
    const g = gap({
      category: "weapon",
      status: "needs_fill",
      coveringSetId: "s1",
      coveringMode: "live",
      emptySlots: ["primary", "special", "heavy"],
      requiredSlotCount: 3,
    });
    expect(firstEmptyRequiredSlot(g)).toBe("primary");
    const step = resolvePostMutationStep({ gap: g });
    expect(step).toEqual({
      step: "fill",
      fillSlot: "primary",
      category: "weapon",
    });
  });

  it("returns first empty armor slot in required order", () => {
    const g = gap({
      category: "armor",
      status: "needs_fill",
      coveringSetId: "a1",
      coveringMode: "live",
      emptySlots: ["helmet", "arms", "chest", "legs", "class"],
      requiredSlotCount: 5,
    });
    expect(firstEmptyRequiredSlot(g)).toBe("helmet");
    expect(resolvePostMutationStep({ gap: g, preferArmorOptimize: false }).fillSlot).toBe("helmet");
  });

  it("opens armor_optimize for live covering armor by default", () => {
    const g = gap({
      category: "armor",
      status: "needs_fill",
      coveringSetId: "a1",
      coveringMode: "live",
      emptySlots: ["helmet"],
      requiredSlotCount: 5,
    });
    expect(resolvePostMutationStep({ gap: g })).toEqual({
      step: "armor_optimize",
      fillSlot: null,
      category: "armor",
    });
  });

  it("after synthetic needs_fill with only special left opens special", () => {
    const g = gap({
      category: "weapon",
      status: "needs_fill",
      coveringSetId: "s1",
      coveringMode: "live",
      emptySlots: ["special", "heavy"],
      filledSlotCount: 1,
      requiredSlotCount: 3,
    });
    expect(resolvePostMutationStep({ gap: g })).toMatchObject({
      step: "fill",
      fillSlot: "special",
    });
  });

  it("successive empties shrink to next slot", () => {
    let empty = ["primary", "special", "heavy"];
    const next = () =>
      resolvePostMutationStep({
        gap: gap({
          category: "weapon",
          status: empty.length ? "needs_fill" : "satisfied",
          coveringSetId: "s1",
          coveringMode: "live",
          emptySlots: [...empty],
          requiredSlotCount: 3,
          filledSlotCount: 3 - empty.length,
        }),
      });
    expect(next().fillSlot).toBe("primary");
    empty = ["special", "heavy"];
    expect(next().fillSlot).toBe("special");
    empty = ["heavy"];
    expect(next().fillSlot).toBe("heavy");
    empty = [];
    expect(next()).toEqual({ step: "overview", fillSlot: null, category: null });
  });

  it("satisfied gap returns overview", () => {
    expect(
      resolvePostMutationStep({
        gap: gap({ category: "weapon", status: "satisfied", emptySlots: [] }),
      }),
    ).toEqual({ step: "overview", fillSlot: null, category: null });
  });

  it("null gap returns overview", () => {
    expect(resolvePostMutationStep({ gap: null })).toEqual({
      step: "overview",
      fillSlot: null,
      category: null,
    });
  });

  it("snapshot needs_fill does not auto-enter fill", () => {
    const g = gap({
      category: "armor",
      status: "needs_fill",
      coveringSetId: "snap",
      coveringMode: "snapshot",
      emptySlots: ["helmet"],
      requiredSlotCount: 5,
    });
    expect(resolvePostMutationStep({ gap: g })).toEqual({
      step: "category",
      fillSlot: null,
      category: "armor",
    });
  });

  it("needs_set stays on category for create", () => {
    expect(
      resolvePostMutationStep({
        gap: gap({ category: "weapon", status: "needs_set" }),
      }),
    ).toEqual({ step: "category", fillSlot: null, category: "weapon" });
  });

  it("showFinishCreateActions for needs_set and capture_available", () => {
    expect(showFinishCreateActions("needs_set")).toBe(true);
    expect(showFinishCreateActions("capture_available")).toBe(true);
    expect(showFinishCreateActions("needs_fill")).toBe(false);
    expect(showFinishCreateActions("satisfied")).toBe(false);
  });
});
