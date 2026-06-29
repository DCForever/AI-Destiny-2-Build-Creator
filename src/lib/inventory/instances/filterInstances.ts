import type { UserInventoryItem } from "@/lib/db/types";

import { bucketKind, isEquipmentBucket } from "./projectInstance";
import type { InstanceFilterCriteria, InstanceKind, OwnedInstanceDetail } from "./types";

function normalizeQuery(q: string): string {
  return q.trim().toLowerCase();
}

export function filterInventoryItems(
  items: UserInventoryItem[],
  criteria: InstanceFilterCriteria,
): UserInventoryItem[] {
  return items.filter((item) => {
    if (!isEquipmentBucket(item.bucket)) return false;
    if (criteria.itemHash !== undefined && item.itemHash !== criteria.itemHash) return false;
    if (criteria.bucket !== undefined && item.bucket !== criteria.bucket) return false;
    if (criteria.kind !== undefined) {
      const kind = bucketKind(item.bucket);
      if (kind !== criteria.kind) return false;
    }
    return true;
  });
}

export function filterProjectedByPerkQuery(
  instances: OwnedInstanceDetail[],
  q: string,
): OwnedInstanceDetail[] {
  const needle = normalizeQuery(q);
  if (!needle) return instances;
  return instances.filter((instance) =>
    instance.plugs.some((plug) => plug.displayName.toLowerCase().includes(needle)),
  );
}

export function kindFromQuery(kind?: "weapons" | "armor"): InstanceKind | undefined {
  if (!kind) return undefined;
  return kind === "weapons" ? "weapon" : "armor";
}

export function hasActiveFilter(criteria: InstanceFilterCriteria): boolean {
  return (
    criteria.itemHash !== undefined ||
    criteria.bucket !== undefined ||
    criteria.kind !== undefined ||
    Boolean(criteria.q?.trim())
  );
}
