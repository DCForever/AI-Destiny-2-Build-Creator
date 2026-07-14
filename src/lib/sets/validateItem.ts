import { resolveEntityPresentation } from "@/lib/catalog/entityPresentation";
import { resolveInventoryHashProjections } from "@/lib/catalog/inventoryHashProjections";
import { getServices } from "@/lib/services";

export type ItemValidationResult = {
  valid: boolean;
  name?: string;
  icon?: string | null;
  description?: string;
  element?: string | null;
  stale?: boolean;
};

/**
 * Resolve legendary armor (and other non-entity-store items) from the raw
 * inventory manifest. Entity cache only has exotic armor / weapons / mods.
 */
async function resolveFromManifestInventory(
  itemHash: number,
): Promise<ItemValidationResult | null> {
  try {
    const { manifest } = await getServices();
    const status = await manifest.getStatus();
    const version = status.cachedVersion;
    if (!version) return null;

    const projections = await resolveInventoryHashProjections(
      manifest,
      version,
      [itemHash],
    );
    const proj = projections.get(itemHash);
    if (!proj) return null;

    return {
      valid: true,
      name: proj.name,
      icon: proj.icon ?? null,
      description: "",
      element: null,
      stale: false,
    };
  } catch {
    return null;
  }
}

export async function validateItemHash(itemHash: number): Promise<ItemValidationResult> {
  const presented = await resolveEntityPresentation({
    by: "hash",
    hash: itemHash,
    stores: ["weapons", "exotic-weapons", "exotic-armor", "mods"],
  });
  if (presented.hash != null) {
    return {
      valid: true,
      name: presented.name,
      icon: presented.icon,
      description: presented.description,
      element: presented.element,
      stale: false,
    };
  }

  // Fallback scan if presentation miss (defensive)
  const { entityCache } = await getServices();
  const stores = ["weapons", "exotic-weapons", "exotic-armor", "mods"] as const;
  for (const store of stores) {
    const records = await entityCache.getStore(store);
    const match = records.find((r) => r.hash === itemHash);
    if (match) {
      return {
        valid: true,
        name: match.name,
        icon: "icon" in match ? (match.icon ?? null) : null,
        description: "",
        element: "element" in match ? ((match as { element?: string }).element ?? null) : null,
        stale: false,
      };
    }
  }

  // Legendary armor (and fashion/cosmetics not in derived stores)
  const fromManifest = await resolveFromManifestInventory(itemHash);
  if (fromManifest) return fromManifest;

  return { valid: false, stale: true };
}

export async function resolveItemDisplayName(
  itemHash: number,
  fallbackName?: string,
): Promise<{
  name: string;
  icon: string | null;
  description: string;
  element: string | null;
  stale: boolean;
}> {
  const result = await validateItemHash(itemHash);
  if (result.valid && result.name) {
    return {
      name: result.name,
      icon: result.icon ?? null,
      description: result.description ?? "",
      element: result.element ?? null,
      stale: false,
    };
  }
  // Last chance: manifest may still have an icon even if name failed earlier
  const fromManifest = await resolveFromManifestInventory(itemHash);
  if (fromManifest?.valid) {
    return {
      name: fromManifest.name ?? fallbackName ?? `Unknown (${itemHash})`,
      icon: fromManifest.icon ?? null,
      description: fromManifest.description ?? "",
      element: fromManifest.element ?? null,
      stale: false,
    };
  }
  return {
    name: fallbackName ?? `Unknown (${itemHash})`,
    icon: null,
    description: "",
    element: null,
    stale: true,
  };
}
