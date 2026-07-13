import type { CatalogItem } from "@/lib/catalog/types";

export type CatalogClientFilters = {
  query?: string;
  slots?: string[];
  elements?: string[];
  onlyExotic?: boolean;
};

/** Extra client-side narrowing on catalog API rows (search already ran server-side). */
export function filterCatalogClient(
  items: CatalogItem[],
  filters: CatalogClientFilters,
): CatalogItem[] {
  const q = filters.query?.trim().toLowerCase() ?? "";
  const slots = filters.slots ?? [];
  const elements = filters.elements ?? [];

  return items.filter((item) => {
    if (filters.onlyExotic && !item.isExotic) return false;
    if (slots.length > 0 && item.slot && !slots.includes(item.slot)) return false;
    if (elements.length > 0 && item.element && !elements.includes(item.element)) {
      return false;
    }
    if (!q) return true;
    const hay = [
      item.name,
      item.slot,
      item.element,
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
