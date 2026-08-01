import type { FinishCategory, FinishGap, FinishGapStatus } from "@/lib/builds/finishGaps";

export type FinishWalkthroughStep = "overview" | "category" | "fill" | "armor_optimize" | "done";

export type FinishPostMutationTarget = {
  step: FinishWalkthroughStep;
  fillSlot: string | null;
  category: FinishCategory | null;
};

export function finishCategoryToSetType(
  category: FinishCategory,
): "armor" | "weapon" | "mod" {
  return category;
}

export function firstEmptyRequiredSlot(gap: Pick<FinishGap, "emptySlots">): string | null {
  return gap.emptySlots[0] ?? null;
}

/** Live covering armor set should open optimizer workspace (031). */
export function shouldOpenArmorOptimize(gap: FinishGap | null | undefined): boolean {
  return (
    gap != null &&
    gap.category === "armor" &&
    gap.coveringSetId != null &&
    gap.coveringMode === "live" &&
    gap.status !== "satisfied"
  );
}

export type ResolvePostMutationStepInput = {
  gap: FinishGap | null | undefined;
  autoEnterFill?: boolean;
  /** When true (default), armor live covering opens optimizer instead of fill. */
  preferArmorOptimize?: boolean;
};

export function resolvePostMutationStep(
  input: ResolvePostMutationStepInput,
): FinishPostMutationTarget {
  const { gap, autoEnterFill = true, preferArmorOptimize = true } = input;
  if (!gap || gap.status === "satisfied") {
    return { step: "overview", fillSlot: null, category: null };
  }

  if (preferArmorOptimize && shouldOpenArmorOptimize(gap)) {
    return { step: "armor_optimize", fillSlot: null, category: "armor" };
  }

  if (gap.status === "needs_fill") {
    if (gap.coveringMode === "snapshot") {
      return { step: "category", fillSlot: null, category: gap.category };
    }
    if (gap.coveringMode === "live" && gap.coveringSetId) {
      const slot = firstEmptyRequiredSlot(gap);
      if (slot && autoEnterFill) {
        return { step: "fill", fillSlot: slot, category: gap.category };
      }
      return { step: "category", fillSlot: null, category: gap.category };
    }
    return { step: "category", fillSlot: null, category: gap.category };
  }

  return { step: "category", fillSlot: null, category: gap.category };
}

export function showFinishCreateActions(status: FinishGapStatus): boolean {
  return status === "needs_set" || status === "capture_available";
}
