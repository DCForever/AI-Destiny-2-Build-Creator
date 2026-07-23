import type { FinishCategory, FinishGap, FinishGapStatus } from "@/lib/builds/finishGaps";

export type FinishWalkthroughStep = "overview" | "category" | "fill" | "done";

export type FinishPostMutationTarget = {
  step: FinishWalkthroughStep;
  fillSlot: string | null;
  /** Prefer focusing this category after mutation when returning to overview. */
  category: FinishCategory | null;
};

/** Map finish gap category to create-set-attach type. */
export function finishCategoryToSetType(
  category: FinishCategory,
): "armor" | "weapon" | "mod" {
  return category;
}

/**
 * First empty required slot in gap order (already filtered/ordered by evaluateFinishGaps).
 */
export function firstEmptyRequiredSlot(gap: Pick<FinishGap, "emptySlots">): string | null {
  return gap.emptySlots[0] ?? null;
}

export type ResolvePostMutationStepInput = {
  gap: FinishGap | null | undefined;
  /**
   * When true (default), needs_fill + live covering auto-opens fill for first empty slot.
   * Snapshot covering never auto-fills.
   */
  autoEnterFill?: boolean;
};

/**
 * After create/capture/fill refresh, decide next Finish walkthrough step for the active category gap.
 */
export function resolvePostMutationStep(
  input: ResolvePostMutationStepInput,
): FinishPostMutationTarget {
  const { gap, autoEnterFill = true } = input;
  if (!gap || gap.status === "satisfied") {
    return { step: "overview", fillSlot: null, category: null };
  }

  if (gap.status === "needs_fill") {
    if (gap.coveringMode === "snapshot") {
      return {
        step: "category",
        fillSlot: null,
        category: gap.category,
      };
    }
    if (gap.coveringMode === "live" && gap.coveringSetId) {
      const slot = firstEmptyRequiredSlot(gap);
      if (slot && autoEnterFill) {
        return {
          step: "fill",
          fillSlot: slot,
          category: gap.category,
        };
      }
      return {
        step: "category",
        fillSlot: null,
        category: gap.category,
      };
    }
    // needs_fill without covering — treat as category
    return { step: "category", fillSlot: null, category: gap.category };
  }

  // needs_set | capture_available
  return {
    step: "category",
    fillSlot: null,
    category: gap.category,
  };
}

/** Statuses that show one-tap create (and optional capture). */
export function showFinishCreateActions(status: FinishGapStatus): boolean {
  return status === "needs_set" || status === "capture_available";
}
