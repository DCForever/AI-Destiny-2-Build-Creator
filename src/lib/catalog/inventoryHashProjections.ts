import { getRaw, isUsable, projectBase } from "@/lib/manifest/extractors/common";
import { asRawInventoryItem } from "@/lib/manifest/extractors/rawTypes";
import type { ManifestService } from "@/lib/manifest/types/services";

import type { InventoryHashProjection } from "./filterItems";

export async function resolveInventoryHashProjections(
  manifest: ManifestService,
  version: string,
  hashes: number[],
): Promise<Map<number, InventoryHashProjection>> {
  if (hashes.length === 0) return new Map();

  const table = await manifest.loadRawTable(version, "DestinyInventoryItemDefinition");
  const result = new Map<number, InventoryHashProjection>();

  for (const hash of hashes) {
    const raw = getRaw(table, hash);
    const item = asRawInventoryItem(raw);
    if (!item || !isUsable(item)) continue;
    const base = projectBase(item);
    result.set(hash, {
      name: base.name,
      searchName: base.searchName,
      icon: base.icon,
    });
  }

  return result;
}
