/**
 * Group exotic armor search results by slot; sort by name within groups.
 */

import { compareDisplayName } from "@/lib/sortByName";

export type ExoticArmorSlotKey =
  | "Helmet"
  | "Gauntlets"
  | "Chest"
  | "Legs"
  | "ClassItem"
  | "Other";

export type ExoticArmorSearchItem = {
  hash: number;
  name: string;
  slot?: string | null;
  icon?: string | null;
  description?: string | null;
  classType?: string | null;
  [key: string]: unknown;
};

export type ExoticArmorSearchGroup = {
  key: ExoticArmorSlotKey;
  label: string;
  items: ExoticArmorSearchItem[];
};

const SLOT_ORDER: ExoticArmorSlotKey[] = [
  "Helmet",
  "Gauntlets",
  "Chest",
  "Legs",
  "ClassItem",
  "Other",
];

const SLOT_LABEL: Record<ExoticArmorSlotKey, string> = {
  Helmet: "Helmet",
  Gauntlets: "Gauntlets",
  Chest: "Chest",
  Legs: "Legs",
  ClassItem: "Class item",
  Other: "Other",
};

/** Normalize API/manifest slot strings to a stable group key. */
export function normalizeExoticArmorSlot(
  slot: string | null | undefined,
): ExoticArmorSlotKey {
  if (!slot) return "Other";
  const s = slot.trim().toLowerCase().replace(/[\s_-]+/g, "");
  switch (s) {
    case "helmet":
      return "Helmet";
    case "gauntlets":
    case "arms":
    case "gloves":
      return "Gauntlets";
    case "chest":
    case "chestarmor":
      return "Chest";
    case "legs":
    case "legarmor":
    case "boots":
      return "Legs";
    case "classitem":
    case "class_item":
      return "ClassItem";
    default:
      // Exact manifest enum passthrough
      if (slot === "Helmet") return "Helmet";
      if (slot === "Gauntlets") return "Gauntlets";
      if (slot === "Chest") return "Chest";
      if (slot === "Legs") return "Legs";
      if (slot === "ClassItem") return "ClassItem";
      return "Other";
  }
}

export function exoticArmorSlotLabel(slot: string | null | undefined): string {
  return SLOT_LABEL[normalizeExoticArmorSlot(slot)];
}

/**
 * Group exotic armor by slot (Helmet → … → ClassItem); sort names within group.
 */
export function groupAndSortExoticArmorSearchResults(
  items: ExoticArmorSearchItem[],
): ExoticArmorSearchGroup[] {
  const buckets = new Map<ExoticArmorSlotKey, ExoticArmorSearchItem[]>();
  for (const key of SLOT_ORDER) buckets.set(key, []);

  for (const item of items) {
    const key = normalizeExoticArmorSlot(item.slot);
    buckets.get(key)!.push(item);
  }

  for (const list of buckets.values()) {
    list.sort((a, b) => compareDisplayName(a.name, b.name));
  }

  const groups: ExoticArmorSearchGroup[] = [];
  for (const key of SLOT_ORDER) {
    const list = buckets.get(key) ?? [];
    if (list.length === 0) continue;
    groups.push({
      key,
      label: SLOT_LABEL[key],
      items: list,
    });
  }
  return groups;
}
