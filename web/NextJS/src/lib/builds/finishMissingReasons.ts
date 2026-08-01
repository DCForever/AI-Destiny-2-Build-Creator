import { finishCategoryLabel, type FinishGapsResult } from "./finishGaps";

export type EquipReadyHint = {
  equipReady: boolean;
  wishlistOrStaleCount?: number;
};

/**
 * Human-readable Finish tab reasons from finish-gap evaluation (+ optional pins).
 */
export function finishMissingReasons(
  gaps: FinishGapsResult,
  equip?: EquipReadyHint | null,
): string[] {
  const out: string[] = [];
  for (const g of gaps.gaps) {
    if (g.status === "satisfied") continue;
    const label = finishCategoryLabel(g.category);
    switch (g.status) {
      case "needs_set":
        out.push(`${label}: set missing`);
        break;
      case "needs_fill":
        out.push(
          `${label}: ${g.emptySlots.length} empty slot${g.emptySlots.length === 1 ? "" : "s"}`,
        );
        break;
      case "capture_available":
        out.push(`${label}: capture available (no covering set yet)`);
        break;
      default:
        out.push(`${label}: incomplete`);
    }
  }
  if (equip && !equip.equipReady) {
    const n = equip.wishlistOrStaleCount;
    out.push(
      n != null && n > 0
        ? `Owned pins: ${n} wishlist or stale slot${n === 1 ? "" : "s"}`
        : "Owned pins: not equip-ready",
    );
  }
  return out;
}
