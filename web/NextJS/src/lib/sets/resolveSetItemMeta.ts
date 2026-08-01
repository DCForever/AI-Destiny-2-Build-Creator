/**
 * Server-side resolution of set item meta from the entity cache.
 * Legendary armor is not in derived stores — returns unknown kind (bucket
 * checks skipped; catalog UI still enforces armor fills).
 */

import { getServices } from "@/lib/services";
import {
  kindFromEntityStore,
  type SetItemMeta,
} from "@/lib/sets/destinySetConstraints";

export async function resolveSetItemMeta(itemHash: number): Promise<SetItemMeta> {
  const { entityCache } = await getServices();

  const exoticWeapons = await entityCache.getStore("exotic-weapons");
  const exoW = exoticWeapons.find((r) => r.hash === itemHash);
  if (exoW) {
    return {
      kind: kindFromEntityStore("exotic-weapons"),
      equipmentSlot: exoW.slot,
      isExotic: true,
    };
  }

  const weapons = await entityCache.getStore("weapons");
  const legW = weapons.find((r) => r.hash === itemHash);
  if (legW) {
    return {
      kind: kindFromEntityStore("weapons"),
      equipmentSlot: legW.slot,
      isExotic: false,
    };
  }

  const exoticArmor = await entityCache.getStore("exotic-armor");
  const exoA = exoticArmor.find((r) => r.hash === itemHash);
  if (exoA) {
    return {
      kind: kindFromEntityStore("exotic-armor"),
      equipmentSlot: exoA.slot,
      isExotic: true,
    };
  }

  const mods = await entityCache.getStore("mods");
  const mod = mods.find((r) => r.hash === itemHash);
  if (mod) {
    return {
      kind: kindFromEntityStore("mods"),
      slotCategory: mod.slotCategory,
      energyCost: mod.energyCost,
      name: mod.name,
    };
  }

  // Legendary armor / fashion / unknown — no hard bucket data
  return { kind: "unknown" };
}
