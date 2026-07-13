import {
  getRaw,
  isUsable,
  perkDescription,
  projectBase,
} from "@/lib/manifest/extractors/common";
import { asRawInventoryItem } from "@/lib/manifest/extractors/rawTypes";
import type { ManifestService } from "@/lib/manifest/types/services";

import type { PlugPresentation } from "./resolvePlugs";

/**
 * Resolve plug name / icon / description from raw inventory definitions.
 * Used when entity stores do not cover a plug (barrels, mags, frames, etc.).
 */
export async function resolvePlugPresentationsFromManifest(
  manifest: ManifestService,
  version: string | null | undefined,
  hashes: number[],
): Promise<Map<number, PlugPresentation>> {
  if (!version || hashes.length === 0) return new Map();

  const unique = [...new Set(hashes)];
  const [itemTable, sandboxPerks] = await Promise.all([
    manifest.loadRawTable(version, "DestinyInventoryItemDefinition"),
    manifest.loadRawTable(version, "DestinySandboxPerkDefinition"),
  ]);

  const result = new Map<number, PlugPresentation>();
  for (const hash of unique) {
    const raw = getRaw(itemTable, hash);
    const item = asRawInventoryItem(raw);
    if (!item || !isUsable(item)) continue;
    const base = projectBase(item);
    result.set(hash, {
      name: base.name,
      icon: base.icon,
      description: perkDescription(item, sandboxPerks),
    });
  }
  return result;
}

/** @deprecated Prefer resolvePlugPresentationsFromManifest for icon/description. */
export async function resolvePlugNamesFromManifest(
  manifest: ManifestService,
  version: string | null | undefined,
  hashes: number[],
): Promise<Map<number, string>> {
  const presentations = await resolvePlugPresentationsFromManifest(
    manifest,
    version,
    hashes,
  );
  const names = new Map<number, string>();
  for (const [hash, p] of presentations) {
    names.set(hash, p.name);
  }
  return names;
}
