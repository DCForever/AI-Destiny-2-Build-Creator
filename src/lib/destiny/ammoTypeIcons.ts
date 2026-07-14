/**
 * Ammo type → destiny-icons SVG (justrealmilk/destiny-icons general/).
 * Files live under public/destiny-icons/general/.
 */

import { CATALOG_AMMO_TYPES } from "@/lib/catalog/filterOptions";

export type CatalogAmmoType = (typeof CATALOG_AMMO_TYPES)[number];

/** Public URL path for an ammo-type glyph. */
export const AMMO_TYPE_ICON_PATH: Record<CatalogAmmoType, string> = {
  Primary: "/destiny-icons/general/ammo-primary.svg",
  Special: "/destiny-icons/general/ammo-special.svg",
  Heavy: "/destiny-icons/general/ammo-heavy.svg",
};

export function ammoTypeIconPath(
  ammo: string | null | undefined,
): string | null {
  if (!ammo?.trim()) return null;
  const key = ammo.trim() as CatalogAmmoType;
  return AMMO_TYPE_ICON_PATH[key] ?? null;
}
