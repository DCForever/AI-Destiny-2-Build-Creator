import { getServices } from "@/lib/services";

export type ItemValidationResult = {
  valid: boolean;
  name?: string;
  icon?: string | null;
  stale?: boolean;
};

export async function validateItemHash(itemHash: number): Promise<ItemValidationResult> {
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
        stale: false,
      };
    }
  }

  return { valid: false, stale: true };
}

export async function resolveItemDisplayName(
  itemHash: number,
  fallbackName?: string,
): Promise<{ name: string; icon: string | null; stale: boolean }> {
  const result = await validateItemHash(itemHash);
  if (result.valid && result.name) {
    return { name: result.name, icon: result.icon ?? null, stale: false };
  }
  return {
    name: fallbackName ?? `Unknown (${itemHash})`,
    icon: null,
    stale: true,
  };
}
