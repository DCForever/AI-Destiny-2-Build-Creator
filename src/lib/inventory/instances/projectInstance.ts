import type { UserInventoryItem } from "@/lib/db/types";
import {
  ARMOR_INVENTORY_BUCKETS,
  WEAPON_INVENTORY_BUCKETS,
} from "@/lib/catalog/filterItems";

import { resolvePlugs } from "./resolvePlugs";
import {
  computeTotalArmorStats,
  isCompleteArmorStats,
} from "./parseArmorStats";
import type { CharacterLabel, InstanceKind, OwnedInstanceDetail } from "./types";

export function bucketKind(bucket: string): InstanceKind | null {
  if (WEAPON_INVENTORY_BUCKETS.has(bucket)) return "weapon";
  if (ARMOR_INVENTORY_BUCKETS.has(bucket)) return "armor";
  return null;
}

export function isEquipmentBucket(bucket: string): boolean {
  return bucketKind(bucket) !== null;
}

export function projectInstance(
  item: UserInventoryItem,
  plugMap: Map<number, string>,
  characterLabels?: Map<string, CharacterLabel>,
  membershipDisplayName?: string,
): OwnedInstanceDetail {
  const kind = bucketKind(item.bucket) ?? "weapon";
  let className: OwnedInstanceDetail["className"] = null;
  let characterDisplayName: string | null = null;

  if (item.location !== "vault" && item.characterId) {
    const label = characterLabels?.get(item.characterId);
    if (label) {
      className = label.className;
      characterDisplayName = label.characterDisplayName;
    } else if (membershipDisplayName) {
      characterDisplayName = membershipDisplayName;
    }
  }

  return {
    instanceId: item.instanceId,
    itemHash: item.itemHash,
    kind,
    bucket: item.bucket,
    location: item.location,
    characterId: item.characterId ?? null,
    className,
    characterDisplayName,
    power: item.power,
    isMasterwork: item.isMasterwork,
    isCrafted: item.isCrafted,
    rollTags: item.rollTags,
    plugs: resolvePlugs(item.plugHashes, plugMap),
    statValues: kind === "armor" ? item.statValues : undefined,
    totalStats:
      kind === "armor" && item.statValues ? computeTotalArmorStats(item.statValues) : undefined,
    statsIncomplete:
      kind === "armor"
        ? !item.statValues || !isCompleteArmorStats(item.statValues)
        : undefined,
    syncedAt: item.syncedAt,
  };
}
