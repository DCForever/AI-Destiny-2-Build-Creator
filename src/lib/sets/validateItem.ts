import { resolveEntityPresentation } from "@/lib/catalog/entityPresentation";
import { getServices } from "@/lib/services";

export type ItemValidationResult = {
  valid: boolean;
  name?: string;
  icon?: string | null;
  description?: string;
  element?: string | null;
  stale?: boolean;
};

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
  return {
    name: fallbackName ?? `Unknown (${itemHash})`,
    icon: null,
    description: "",
    element: null,
    stale: true,
  };
}
