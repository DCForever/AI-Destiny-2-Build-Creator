import type { CatalogGroupDimension, CatalogItem } from "./types";
import { compareDisplayName } from "@/lib/sortByName";

export type CatalogGroup = {
  key: string;
  label: string;
  items: CatalogItem[];
};

const DIM_UNKNOWN: Record<CatalogGroupDimension, string> = {
  element: "Unknown element",
  ammo: "Unknown ammo",
  archetype: "Unknown type",
  frame: "Unknown frame",
  slot: "Unknown slot",
  class: "Unknown class",
};

export function dimensionValue(
  item: CatalogItem,
  dim: CatalogGroupDimension,
): string {
  switch (dim) {
    case "element":
      return item.element?.trim() || DIM_UNKNOWN.element;
    case "ammo":
      return item.ammo?.trim() || DIM_UNKNOWN.ammo;
    case "archetype":
      return item.itemTypeName?.trim() || DIM_UNKNOWN.archetype;
    case "frame":
      return item.frame?.trim() || DIM_UNKNOWN.frame;
    case "slot":
      return item.slot?.trim() || DIM_UNKNOWN.slot;
    case "class":
      return item.classType?.trim() || DIM_UNKNOWN.class;
    default:
      return "Other";
  }
}

/**
 * Build a composite group key from active dimensions (order preserved).
 * Empty dimensions → single "All results" group.
 */
export function groupCatalogItems(
  items: CatalogItem[],
  dimensions: CatalogGroupDimension[],
): CatalogGroup[] {
  if (dimensions.length === 0) {
    return [
      {
        key: "__all__",
        label: "All results",
        items: [...items].sort((a, b) => compareDisplayName(a.name, b.name)),
      },
    ];
  }

  const buckets = new Map<string, CatalogItem[]>();
  for (const item of items) {
    const parts = dimensions.map((d) => dimensionValue(item, d));
    const key = parts.join(" · ");
    const list = buckets.get(key) ?? [];
    list.push(item);
    buckets.set(key, list);
  }

  return [...buckets.entries()]
    .map(([key, groupItems]) => ({
      key,
      label: key,
      items: groupItems.sort((a, b) => compareDisplayName(a.name, b.name)),
    }))
    .sort((a, b) => compareDisplayName(a.label, b.label));
}

export const WEAPON_GROUP_DIMENSIONS: {
  id: CatalogGroupDimension;
  label: string;
}[] = [
  { id: "element", label: "Element" },
  { id: "ammo", label: "Ammo" },
  { id: "archetype", label: "Archetype" },
  { id: "frame", label: "Frame" },
  { id: "slot", label: "Slot" },
];

export const ARMOR_GROUP_DIMENSIONS: {
  id: CatalogGroupDimension;
  label: string;
}[] = [
  { id: "class", label: "Class" },
  { id: "slot", label: "Slot" },
  { id: "frame", label: "Archetype" },
];
