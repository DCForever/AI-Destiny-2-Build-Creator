/** Server-only loaders for armor set bonus constraints (uses entity cache / services). */

import type { ConstrainedArmorPiece } from "@/lib/sets/armorSetBonusConstraint";
import { buildSetBonusMembershipIndex } from "@/lib/sets/armorSetBonusConstraint";

/** Resolve membership index from entity cache set-bonuses store. */
export async function loadSetBonusMembershipIndex(): Promise<Map<number, number>> {
  const { getServices } = await import("@/lib/services");
  const { entityCache } = await getServices();
  const setBonuses = await entityCache.getStore("set-bonuses");
  return buildSetBonusMembershipIndex(setBonuses ?? []);
}

/** Map set items to constraint pieces (exotic armor does not count). */
export async function toConstrainedArmorPieces(
  items: Array<{ itemHash: number; slot?: string; itemName?: string }>,
): Promise<ConstrainedArmorPiece[]> {
  const { resolveSetItemMeta } = await import("@/lib/sets/resolveSetItemMeta");
  return Promise.all(
    items.map(async (item) => {
      const meta = await resolveSetItemMeta(item.itemHash);
      return {
        itemHash: item.itemHash,
        isExotic: meta.isExotic === true,
        slot: item.slot,
        itemName: item.itemName,
      };
    }),
  );
}
