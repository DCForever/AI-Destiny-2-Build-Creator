import type { CatalogItem } from "@/lib/catalog/types";

import { buildInstancesHref } from "./instancesHref";

export function attachInstancePointers(
  items: CatalogItem[],
  enabled: boolean,
): CatalogItem[] {
  if (!enabled) return items;
  return items.map((item) => {
    if (!item.owned || item.ownedCount <= 0) return item;
    return { ...item, instancesHref: buildInstancesHref(item.hash) };
  });
}
