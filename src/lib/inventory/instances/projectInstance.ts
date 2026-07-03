import type { UserInventoryItem } from "@/lib/db/types";
import {
  ARMOR_INVENTORY_BUCKETS,
  WEAPON_INVENTORY_BUCKETS,
} from "@/lib/catalog/filterItems";

import { resolveArmorTier } from "@/data/rules/armorTiers";

import { resolvePlugs } from "./resolvePlugs";
import {
  computeTotalArmorStats,
  isCompleteArmorStats,
} from "./parseArmorStats";
import type {
  ArmorInstanceMeta,
  CharacterLabel,
  InstanceKind,
  OwnedInstanceDetail,
} from "./types";

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
  armorMeta?: Map<number, ArmorInstanceMeta>,
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

  const isArmor = kind === "armor";
  const totalStats = isArmor && item.statValues ? computeTotalArmorStats(item.statValues) : undefined;
  const statsComplete = isArmor && isCompleteArmorStats(item.statValues);
  const meta = isArmor ? armorMeta?.get(item.itemHash) : undefined;

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
    statValues: isArmor ? item.statValues : undefined,
    totalStats,
    statsIncomplete: isArmor ? !statsComplete : undefined,
    tier: isArmor
      ? resolveArmorTier({
          gearTier: item.gearTier ?? null,
          totalStats,
          isExotic: meta?.isExotic ?? false,
          statsComplete,
        })
      : undefined,
    setBonus: isArmor ? (meta?.setBonus ?? null) : undefined,
    syncedAt: item.syncedAt,
  };
}
