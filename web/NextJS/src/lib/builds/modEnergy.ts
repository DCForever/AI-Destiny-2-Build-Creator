/**
 * Armor mod energy capacity (DBR-MOD-002) and cost helpers.
 */

import type { ModSlotCategory } from "@/lib/manifest/types/records";

/** Tier ≤4 → 10 energy; tier 5 → 11. Unknown/wishlist defaults to 10. */
export function armorEnergyCapacity(tier: number | null | undefined): number {
  if (tier != null && Number.isFinite(tier) && tier >= 5) return 11;
  return 10;
}

export function sumEnergyCosts(
  costs: ReadonlyArray<number | null | undefined>,
): number {
  let total = 0;
  for (const c of costs) {
    if (typeof c === "number" && Number.isFinite(c) && c > 0) total += c;
  }
  return total;
}

/** Map set equipment slot → mod plug slotCategory. */
export function modCategoryForArmorSlot(
  slot: string,
): ModSlotCategory | null {
  switch (slot) {
    case "helmet":
      return "helmet";
    case "arms":
      return "arms";
    case "chest":
      return "chest";
    case "legs":
      return "legs";
    case "class_item":
      return "classItem";
    default:
      return null;
  }
}

/**
 * Whether a mod may sit on this armor piece.
 * `general` / `tuning` are allowed on any armor slot.
 */
export function isModLegalForArmorSlot(
  slot: string,
  category: ModSlotCategory | string | null | undefined,
): boolean {
  if (!category) return true; // unknown — do not hard-block
  if (category === "general" || category === "tuning") return true;
  const expected = modCategoryForArmorSlot(slot);
  if (!expected) return true;
  return category === expected;
}
