import { resolveInventoryHashProjections } from "@/lib/catalog/inventoryHashProjections";
import type { ManifestService } from "@/lib/manifest/types/services";

export async function resolvePlugNamesFromManifest(
  manifest: ManifestService,
  version: string | null | undefined,
  hashes: number[],
): Promise<Map<number, string>> {
  if (!version || hashes.length === 0) return new Map();

  const projections = await resolveInventoryHashProjections(manifest, version, hashes);
  const names = new Map<number, string>();
  for (const [hash, projection] of projections) {
    names.set(hash, projection.name);
  }
  return names;
}
