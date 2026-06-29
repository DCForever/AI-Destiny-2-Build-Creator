import type { SavedLoadout } from "@/lib/db/types";

import { classifyLoadoutExotics, type ManifestExoticStores } from "./classifyExotics";
import type { LoadoutExoticSummary } from "./types";

export function summarizeLoadouts(
  loadouts: SavedLoadout[],
  manifest?: ManifestExoticStores,
): Map<string, LoadoutExoticSummary> {
  const map = new Map<string, LoadoutExoticSummary>();
  for (const loadout of loadouts) {
    const summary = classifyLoadoutExotics(loadout, manifest);
    map.set(loadout.id, summary);
  }
  return map;
}
