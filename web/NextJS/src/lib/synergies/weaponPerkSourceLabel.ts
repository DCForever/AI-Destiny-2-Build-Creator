import type { WeaponPerkSource } from "@/lib/manifest/types/records";

/**
 * Human label for weapon_perk picker rows (exotic intrinsic/trait vs legendary).
 */
export function formatWeaponPerkSourceLabel(
  source?: WeaponPerkSource | null,
  plugTypeName?: string | null,
): string | undefined {
  if (!source) return undefined;
  const role = (plugTypeName ?? "").trim().toLowerCase();
  const isIntrinsic = role === "intrinsic";

  if (source === "both") return "Legendary & exotic";
  if (source === "exotic") {
    return isIntrinsic ? "Exotic intrinsic" : "Exotic trait";
  }
  // legendary
  return isIntrinsic ? "Legendary intrinsic" : "Legendary perk";
}
