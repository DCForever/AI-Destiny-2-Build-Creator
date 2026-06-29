import type { UserInventoryItem } from "@/lib/db/types";

import { isEquipmentBucket } from "./projectInstance";

export function collectEquipmentPlugHashes(items: UserInventoryItem[]): number[] {
  const hashes = new Set<number>();
  for (const item of items) {
    if (!isEquipmentBucket(item.bucket)) continue;
    for (const hash of item.plugHashes) {
      hashes.add(hash);
    }
  }
  return [...hashes];
}
