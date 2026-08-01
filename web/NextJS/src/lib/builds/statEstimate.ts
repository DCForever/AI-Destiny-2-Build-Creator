import { ARMOR_STAT_NAMES, type ArmorStatName } from "@/data/rules/statBenefits";
import type { SlotClaim } from "@/lib/builds/resolveVariant";
import type { SoftStatTargets } from "@/lib/builds/softStatTargets";
import type { UserInventoryItem } from "@/lib/db/types";
import type { EquipmentSlot } from "@/lib/sets/schemas";

const ARMOR_SLOTS: EquipmentSlot[] = ["helmet", "arms", "chest", "legs", "class_item"];

export type StatEstimate = Partial<Record<ArmorStatName, number>> & { incomplete: boolean };

export function estimateLoadoutStats(
  claims: SlotClaim[],
  inventoryByInstance: Map<string, UserInventoryItem>,
): StatEstimate {
  const totals: Partial<Record<ArmorStatName, number>> = {};
  for (const name of ARMOR_STAT_NAMES) totals[name] = 0;

  let incomplete = false;
  let armorClaims = 0;

  for (const claim of claims) {
    if (!ARMOR_SLOTS.includes(claim.slot)) continue;
    armorClaims += 1;
    if (!claim.instanceId) {
      incomplete = true;
      continue;
    }
    const item = inventoryByInstance.get(claim.instanceId);
    if (!item?.statValues) {
      incomplete = true;
      continue;
    }
    for (const name of ARMOR_STAT_NAMES) {
      const v = item.statValues[name];
      if (typeof v === "number") totals[name] = (totals[name] ?? 0) + v;
    }
  }

  if (armorClaims < ARMOR_SLOTS.length) incomplete = true;

  return { ...totals, incomplete };
}

export type SoftStatWarningRow = {
  stat: ArmorStatName;
  target: number;
  estimate: number;
  hint: string;
};

export function softStatWarnings(
  targets: SoftStatTargets,
  estimate: StatEstimate,
): SoftStatWarningRow[] {
  const rows: SoftStatWarningRow[] = [];
  for (const name of ARMOR_STAT_NAMES) {
    const target = targets[name];
    if (target == null) continue;
    const value = estimate[name] ?? 0;
    if (value < target) {
      rows.push({
        stat: name,
        target,
        estimate: value,
        hint: `${name} estimate ${value} is below target ${target}.`,
      });
    }
  }
  return rows;
}
