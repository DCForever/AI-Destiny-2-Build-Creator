import {
  getRaw,
  isUsable,
  projectBase,
  toArmorSlot,
  toClassName,
  toWeaponSlot,
} from "@/lib/manifest/extractors/common";
import {
  asRawEquipmentSlot,
  asRawInventoryItem,
} from "@/lib/manifest/extractors/rawTypes";
import type { ManifestService } from "@/lib/manifest/types/services";

import type { InventoryHashProjection } from "./filterItems";

async function buildEquipmentSlotMap(
  manifest: ManifestService,
  version: string,
): Promise<Map<number, string>> {
  const slotTable = await manifest.loadRawTable(
    version,
    "DestinyEquipmentSlotDefinition",
  );
  const map = new Map<number, string>();
  for (const v of Object.values(slotTable)) {
    const slot = asRawEquipmentSlot(v);
    if (!slot) continue;
    const name = slot.displayProperties?.name ?? "";
    const armor = toArmorSlot(name);
    if (armor) {
      map.set(slot.hash, armor);
      continue;
    }
    const weapon = toWeaponSlot(name);
    if (weapon) map.set(slot.hash, weapon);
  }
  return map;
}

export async function resolveInventoryHashProjections(
  manifest: ManifestService,
  version: string,
  hashes: number[],
): Promise<Map<number, InventoryHashProjection>> {
  if (hashes.length === 0) return new Map();

  const [itemTable, slotMap] = await Promise.all([
    manifest.loadRawTable(version, "DestinyInventoryItemDefinition"),
    buildEquipmentSlotMap(manifest, version),
  ]);
  const result = new Map<number, InventoryHashProjection>();

  for (const hash of hashes) {
    const raw = getRaw(itemTable, hash);
    const item = asRawInventoryItem(raw);
    if (!item || !isUsable(item)) continue;
    const base = projectBase(item);
    const slotHash = item.equippingBlock?.equipmentSlotTypeHash;
    const slot = slotHash != null ? slotMap.get(slotHash) : undefined;
    const classType = toClassName(item.classType) ?? undefined;
    result.set(hash, {
      name: base.name,
      searchName: base.searchName,
      icon: base.icon,
      ...(slot ? { slot } : {}),
      ...(classType ? { classType } : {}),
    });
  }

  return result;
}
