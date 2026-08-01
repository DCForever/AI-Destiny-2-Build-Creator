import type { SetType } from "./schemas";

const SET_SLOT_TO_CATALOG_BUCKET: Record<string, string> = {
  primary: "Kinetic",
  special: "Energy",
  heavy: "Power",
  helmet: "Helmet",
  arms: "Gauntlets",
  chest: "Chest",
  legs: "Legs",
  class_item: "ClassItem",
};

export function setSlotToCatalogBucket(slot: string): string | null {
  return SET_SLOT_TO_CATALOG_BUCKET[slot] ?? null;
}

export function catalogBucketForSetType(type: SetType): "weapons" | "armor" | null {
  if (type === "weapon") return "weapons";
  if (type === "armor") return "armor";
  return null;
}
