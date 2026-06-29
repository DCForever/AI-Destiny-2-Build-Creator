import type { EquipmentSlot } from "@/lib/sets/schemas";

/** Destiny inventory bucket hash → canonical equipment slot (subset used by sets). */
const BUCKET_TO_SLOT: Record<number, EquipmentSlot> = {
  1498876634: "primary",
  2465295065: "special",
  953998645: "heavy",
  3448274439: "helmet",
  3551918588: "arms",
  14239492: "chest",
  20886954: "legs",
  1585787867: "class_item",
};

export function bucketHashToSlot(bucketHash: number): EquipmentSlot | null {
  return BUCKET_TO_SLOT[bucketHash] ?? null;
}

export function slotToBucketHash(slot: EquipmentSlot): number | null {
  for (const [hash, mapped] of Object.entries(BUCKET_TO_SLOT)) {
    if (mapped === slot) return Number(hash);
  }
  return null;
}
