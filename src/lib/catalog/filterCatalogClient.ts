import type { CatalogItem } from "@/lib/catalog/types";

export type CatalogClientFilters = {
  query?: string;
  /** Single slot or multi (OR). */
  slot?: string | null;
  slots?: string[];
  elements?: string[];
  ammos?: string[];
  /** Weapon itemTypeName or armor frame (OR). */
  archetypes?: string[];
  className?: string | null;
  onlyExotic?: boolean;
};

function multiIncludes(
  selected: string[] | undefined,
  value: string | null | undefined,
): boolean {
  if (!selected?.length) return true;
  if (!value) return false;
  return selected.includes(value);
}

function matchesArchetype(
  archetypes: string[] | undefined,
  item: CatalogItem,
): boolean {
  if (!archetypes?.length) return true;
  if (item.itemTypeName && archetypes.includes(item.itemTypeName)) return true;
  if (item.frame) {
    return archetypes.some(
      (t) =>
        item.frame === t ||
        item.frame!.includes(t) ||
        t.includes(item.frame!.replace(/\s*Frame$/i, "").trim()),
    );
  }
  return false;
}

/**
 * Live client-side narrowing of a base catalog fetch.
 * Server still handles kind/scope/synergy allowlists.
 */
export function filterCatalogClient(
  items: CatalogItem[],
  filters: CatalogClientFilters,
): CatalogItem[] {
  const q = filters.query?.trim().toLowerCase() ?? "";
  const slots =
    filters.slots?.length
      ? filters.slots
      : filters.slot
        ? [filters.slot]
        : [];
  const elements = filters.elements ?? [];
  const ammos = filters.ammos ?? [];
  const archetypes = filters.archetypes ?? [];
  const className = filters.className?.trim() || null;

  return items.filter((item) => {
    if (filters.onlyExotic && !item.isExotic) return false;
    if (slots.length > 0) {
      if (!item.slot || !slots.includes(item.slot)) return false;
    }
    if (!multiIncludes(elements, item.element)) return false;
    if (!multiIncludes(ammos, item.ammo)) return false;
    if (className && item.classType !== className) return false;
    if (!matchesArchetype(archetypes, item)) return false;
    if (!q) return true;
    const hay = [
      item.name,
      item.slot,
      item.element,
      item.ammo,
      item.itemTypeName,
      item.frame,
      item.classType,
      item.setBonusName,
      item.description,
    ]
      .filter(Boolean)
      .join(" ")
      .toLowerCase();
    return hay.includes(q);
  });
}
