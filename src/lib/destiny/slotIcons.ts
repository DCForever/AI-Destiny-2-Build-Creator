/**
 * Destiny equipment slot → destiny-icons path (armor + weapon buckets).
 * Armor SVGs: justrealmilk/destiny-icons armor_types (same family as DIM).
 */

const ARMOR_SLOT_ICON: Record<string, string> = {
  Helmet: "/destiny-icons/armor_types/helmet.svg",
  Gauntlets: "/destiny-icons/armor_types/gloves.svg",
  Chest: "/destiny-icons/armor_types/chest.svg",
  Legs: "/destiny-icons/armor_types/boots.svg",
  ClassItem: "/destiny-icons/armor_types/class.svg",
};

/** Public URL for a catalog slot label, or null if no glyph. */
export function slotIconPath(slot: string | null | undefined): string | null {
  if (!slot?.trim()) return null;
  return ARMOR_SLOT_ICON[slot.trim()] ?? null;
}
