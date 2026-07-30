import { SYNERGY_ELEMENTS } from "@/data/synergyElements";
import { resolveVerbSubType } from "@/data/synergyVerbs";
import {
  AMMO_SUBTYPES,
  WEAPON_SLOT_SUBTYPES,
  type SynergyType,
} from "@/lib/synergies/schemas";
import { isKeywordLikeSubType } from "@/lib/synergies/keywordScan";
import { allowsBaseSubType, requiresSubType } from "@/lib/synergies/synergyTypeRules";

export type SubTypeValidationResult =
  | { ok: true; subType: string | null }
  | { ok: false; reason: string };

export function validateSynergySubType(
  type: SynergyType,
  subType: string | null | undefined,
): SubTypeValidationResult {
  const trimmed = subType?.trim() ?? null;

  if (requiresSubType(type)) {
    if (!trimmed) {
      return { ok: false, reason: `subType required for ${type} synergies` };
    }
    if (
      (type === "verb" ||
        type === "element" ||
        type === "weapon_archetype" ||
        type === "ammo" ||
        type === "weapon_slot") &&
      trimmed === "Base"
    ) {
      return { ok: false, reason: `Base is not valid for ${type} synergies` };
    }
    if (type === "element" && !(SYNERGY_ELEMENTS as readonly string[]).includes(trimmed)) {
      return { ok: false, reason: `Unknown element subType: ${trimmed}` };
    }
    if (type === "ammo" && !(AMMO_SUBTYPES as readonly string[]).includes(trimmed)) {
      return {
        ok: false,
        reason: `Unknown ammo subType: ${trimmed} (use Primary, Special, or Heavy)`,
      };
    }
    if (
      type === "weapon_slot" &&
      !(WEAPON_SLOT_SUBTYPES as readonly string[]).includes(trimmed)
    ) {
      return {
        ok: false,
        reason: `Unknown weapon_slot subType: ${trimmed} (use Kinetic, Energy, or Power)`,
      };
    }
    if (type === "verb") {
      const canonical = resolveVerbSubType(trimmed);
      if (canonical) {
        return { ok: true, subType: canonical };
      }
      // Object-discovered keywords (e.g. Sliding before curated list) may still be curated.
      if (isKeywordLikeSubType(trimmed)) {
        return { ok: true, subType: trimmed };
      }
      return { ok: false, reason: `Unknown verb subType: ${trimmed}` };
    }
    if (allowsBaseSubType(type) && trimmed === "Base") {
      return { ok: true, subType: "Base" };
    }
    return { ok: true, subType: trimmed };
  }

  if (trimmed) {
    return { ok: false, reason: `subType must be empty for ${type} synergies` };
  }
  return { ok: true, subType: null };
}
