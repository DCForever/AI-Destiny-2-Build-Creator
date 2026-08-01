import { getPerkSocketIndexes, getRaw } from "@/lib/manifest/extractors/common";
import { asRawInventoryItem } from "@/lib/manifest/extractors/rawTypes";
import type { ManifestService } from "@/lib/manifest/types/services";

const WEAPON_PERKS_CATEGORY_HASH = 4241085061;

export interface WeaponSocketContext {
  plugCategoryByHash: Map<number, string>;
  /** Destiny itemTypeDisplayName for plugs (e.g. "Enhanced Trait"). */
  plugItemTypeByHash: Map<number, string>;
  weaponPerkSocketIndexes: number[];
}

export async function loadWeaponSocketContext(
  manifest: ManifestService,
  version: string,
  itemHash: number,
  plugHashes: number[],
): Promise<WeaponSocketContext> {
  const itemTable = await manifest.loadRawTable(version, "DestinyInventoryItemDefinition");
  const item = asRawInventoryItem(getRaw(itemTable, itemHash));
  const weaponPerkSocketIndexes = item
    ? getPerkSocketIndexes(item, WEAPON_PERKS_CATEGORY_HASH)
    : [];

  const plugCategoryByHash = new Map<number, string>();
  const plugItemTypeByHash = new Map<number, string>();
  for (const hash of plugHashes) {
    const plug = asRawInventoryItem(getRaw(itemTable, hash));
    const category = plug?.plug?.plugCategoryIdentifier;
    if (category) plugCategoryByHash.set(hash, category);
    const typeName = plug?.itemTypeDisplayName?.trim();
    if (typeName) plugItemTypeByHash.set(hash, typeName);
  }

  return { plugCategoryByHash, plugItemTypeByHash, weaponPerkSocketIndexes };
}
