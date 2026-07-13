import type { UserInventoryItem } from "@/lib/db/types";

import { isEquipmentBucket } from "./projectInstance";

/**
 * Collect plug hashes for UI presentation maps.
 * Prefer passing a pre-filtered item list (e.g. one catalog hash) so callers
 * do not resolve the entire inventory's plugs for a single-item detail view.
 */
export function collectEquipmentPlugHashes(items: UserInventoryItem[]): number[] {
  const hashes = new Set<number>();
  for (const item of items) {
    if (!isEquipmentBucket(item.bucket)) continue;
    for (const hash of item.plugHashes) {
      hashes.add(hash);
    }
    // Include per-copy socket alternates so instance cards resolve icons/descriptions.
    if (item.socketPlugs) {
      for (const socket of item.socketPlugs) {
        hashes.add(socket.equippedPlugHash);
        for (const h of socket.reusablePlugHashes) {
          hashes.add(h);
        }
      }
    }
  }
  return [...hashes];
}
