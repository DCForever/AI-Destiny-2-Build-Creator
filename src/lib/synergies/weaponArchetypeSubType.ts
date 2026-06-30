import { findSocketPlug, iterItems } from "@/lib/manifest/extractors/common";
import type { RawInventoryItem } from "@/lib/manifest/extractors/rawTypes";
import type { RawTable } from "@/lib/manifest/types/services";
import type { WeaponRecord } from "@/lib/manifest/types/records";

export const WEAPON_FRAME_SUFFIX = " Frame";

const ITEM_TYPE_WEAPON = 3;
const TIER_LEGENDARY = 5;

/** Legendary weapon frames from the manifest intrinsic socket (e.g. "Micro-Missile Frame"). */
export function isWeaponFrameName(name: string): boolean {
  const trimmed = name.trim();
  if (trimmed.includes(": ")) return false;
  return trimmed.length > WEAPON_FRAME_SUFFIX.length && trimmed.endsWith(WEAPON_FRAME_SUFFIX);
}

/** Weapon type from itemTypeDisplayName (e.g. "Pulse Rifle"). */
export function isWeaponTypeName(name: string): boolean {
  const trimmed = name.trim();
  if (!trimmed || trimmed.includes(": ") || isWeaponFrameName(trimmed)) return false;
  return true;
}

export function isWeaponArchetypeSubTypeName(name: string): boolean {
  return isWeaponFrameName(name) || isWeaponTypeName(name);
}

/** True when a plug item is the weapon's archetype frame, not a trait/perk in a frames socket. */
export function isLegendaryWeaponFramePlug(plug: RawInventoryItem): boolean {
  const name = plug.displayProperties?.name ?? "";
  if (!isWeaponFrameName(name)) return false;
  const cat = plug.plug?.plugCategoryIdentifier ?? "";
  if (cat.includes("intrinsics")) return true;
  return cat === "frames" && plug.itemTypeDisplayName === "Intrinsic";
}

export function legendaryWeaponFrameName(
  item: RawInventoryItem,
  itemTable: RawTable,
): string | null {
  const plug = findSocketPlug(item, itemTable, isLegendaryWeaponFramePlug);
  return plug?.displayProperties?.name ?? null;
}

export function collectLegendaryWeaponFrameNames(itemTable: RawTable): string[] {
  const seen = new Set<string>();
  for (const item of iterItems(itemTable)) {
    if (item.itemType !== ITEM_TYPE_WEAPON || item.inventory?.tierType !== TIER_LEGENDARY) continue;
    const frame = legendaryWeaponFrameName(item, itemTable);
    if (frame) seen.add(frame);
  }
  return [...seen].sort((a, b) => a.localeCompare(b));
}

export function collectLegendaryWeaponTypeNames(itemTable: RawTable): string[] {
  const seen = new Set<string>();
  for (const item of iterItems(itemTable)) {
    if (item.itemType !== ITEM_TYPE_WEAPON || item.inventory?.tierType !== TIER_LEGENDARY) continue;
    const typeName = item.itemTypeDisplayName?.trim();
    if (typeName && isWeaponTypeName(typeName)) seen.add(typeName);
  }
  return [...seen].sort((a, b) => a.localeCompare(b));
}

export function collectLegendaryWeaponArchetypeSubTypeNames(itemTable: RawTable): string[] {
  const seen = new Set<string>();
  for (const name of [
    ...collectLegendaryWeaponTypeNames(itemTable),
    ...collectLegendaryWeaponFrameNames(itemTable),
  ]) {
    seen.add(name);
  }
  return [...seen].sort((a, b) => a.localeCompare(b));
}

export function matchesWeaponArchetype(
  weapon: Pick<WeaponRecord, "frame" | "itemTypeName">,
  subType: string,
): boolean {
  if (isWeaponFrameName(subType)) return weapon.frame === subType;
  if (isWeaponTypeName(subType)) return weapon.itemTypeName === subType;
  return false;
}

export function matchingWeaponArchetypeSubType(
  weapon: Pick<WeaponRecord, "frame" | "itemTypeName">,
  subTypes: string[],
): string | null {
  for (const subType of subTypes) {
    if (matchesWeaponArchetype(weapon, subType)) return subType;
  }
  return null;
}
