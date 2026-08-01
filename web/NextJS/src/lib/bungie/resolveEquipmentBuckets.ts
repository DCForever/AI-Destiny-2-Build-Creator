import { getRaw } from "@/lib/manifest/extractors/common";
import { asRawInventoryItem } from "@/lib/manifest/extractors/rawTypes";
import type { ManifestService } from "@/lib/manifest/types/services";

import {
  EQUIPMENT_BUCKET_LABELS,
  TRANSFER_CONTAINER_BUCKETS,
} from "./inventoryBuckets";
import type { RawInventoryItem } from "./types";

export function needsEquipmentBucketResolution(bucketHash: number): boolean {
  return TRANSFER_CONTAINER_BUCKETS.has(bucketHash);
}

export async function buildEquipmentBucketLookup(
  manifest: ManifestService,
  manifestVersion: string,
  itemHashes: number[],
): Promise<Map<number, number>> {
  if (itemHashes.length === 0) return new Map();

  const table = await manifest.loadRawTable(manifestVersion, "DestinyInventoryItemDefinition");
  const lookup = new Map<number, number>();
  for (const hash of new Set(itemHashes)) {
    const item = asRawInventoryItem(getRaw(table, hash));
    const bucketTypeHash = item?.inventory?.bucketTypeHash;
    if (typeof bucketTypeHash === "number" && bucketTypeHash in EQUIPMENT_BUCKET_LABELS) {
      lookup.set(hash, bucketTypeHash);
    }
  }
  return lookup;
}

export function resolveTransferContainerBuckets(
  items: RawInventoryItem[],
  lookup: Map<number, number>,
): {
  items: RawInventoryItem[];
  resolvedFromTransfer: number;
  droppedNonEquipment: number;
} {
  let resolvedFromTransfer = 0;
  let droppedNonEquipment = 0;
  const resolved: RawInventoryItem[] = [];

  for (const item of items) {
    if (!needsEquipmentBucketResolution(item.bucketHash)) {
      resolved.push(item);
      continue;
    }
    const equipmentBucket = lookup.get(item.itemHash);
    if (!equipmentBucket) {
      droppedNonEquipment += 1;
      continue;
    }
    resolvedFromTransfer += 1;
    resolved.push({ ...item, bucketHash: equipmentBucket });
  }

  return { items: resolved, resolvedFromTransfer, droppedNonEquipment };
}
