/**
 * Energy accounting for mod-set pieces (multi-mod per armor slot).
 */

import {
  armorEnergyCapacity,
  sumEnergyCosts,
} from "@/lib/builds/modEnergy";
import type { SetItemMeta } from "@/lib/sets/destinySetConstraints";
import {
  isLegacyModSetSlot,
  modSetArmorSlotOf,
  type ArmorSetSlot,
} from "@/lib/sets/schemas";

export type ModSetPieceEnergy = {
  armorSlot: ArmorSetSlot;
  energyUsed: number;
  energyCapacity: number;
  modCount: number;
};

/** Items that belong to an armor piece group in a mod set. */
export function itemsForModArmorSlot(
  items: Array<{ slot: string; removedAt?: string | null }>,
  armorSlot: ArmorSetSlot,
): Array<{ slot: string }> {
  return items.filter((i) => {
    if (i.removedAt) return false;
    return modSetArmorSlotOf(i.slot) === armorSlot;
  });
}

export function isLegacyModItem(slot: string): boolean {
  return isLegacyModSetSlot(slot);
}

/**
 * Sum energy for mods already on a piece (by meta energyCost).
 * Missing costs count as 0.
 */
export function evaluateModSetPieceEnergy(input: {
  armorSlot: ArmorSetSlot;
  existingCosts: Array<number | null | undefined>;
  candidateCost?: number | null;
  tier?: number | null;
}): { ok: true; used: number; capacity: number } | { ok: false; used: number; capacity: number; reason: string } {
  const capacity = armorEnergyCapacity(input.tier);
  const used =
    sumEnergyCosts(input.existingCosts) +
    (typeof input.candidateCost === "number" && input.candidateCost > 0
      ? input.candidateCost
      : 0);
  if (used > capacity) {
    return {
      ok: false,
      used,
      capacity,
      reason: `${input.armorSlot}: mods would use ${used} energy (capacity ${capacity})`,
    };
  }
  return { ok: true, used, capacity };
}

export function costsFromOccupants(
  occupants: Array<{ meta: SetItemMeta }>,
): Array<number | null | undefined> {
  return occupants.map((o) => o.meta.energyCost);
}
