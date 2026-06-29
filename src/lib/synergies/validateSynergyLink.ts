import type { SynergyLinkInput } from "./schemas";

/** Stub resolver — full manifest validation in US4 (T010b/T054). */
export function validateSynergyLink(link: SynergyLinkInput): { valid: boolean; reason?: string } {
  switch (link.kind) {
    case "weapon":
      if (!link.itemHash) return { valid: false, reason: "itemHash required" };
      return { valid: true };
    case "weapon_perk":
      if (!link.perkHash) return { valid: false, reason: "perkHash required" };
      return { valid: true };
    case "origin_trait":
      if (!link.originTraitName && !link.originTraitHash) {
        return { valid: false, reason: "originTraitName or originTraitHash required" };
      }
      return { valid: true };
    case "armor_set_bonus":
      if (!link.armorSetName || !link.bonusPieces || !link.bonusName) {
        return { valid: false, reason: "armorSetName, bonusPieces, bonusName required" };
      }
      return { valid: true };
    default:
      return { valid: false, reason: "unknown kind" };
  }
}
