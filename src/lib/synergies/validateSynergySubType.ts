import { SYNERGY_ELEMENTS } from "@/data/synergyElements";
import { resolveVerbSubType } from "@/data/synergyVerbs";
import type { SynergyType } from "@/lib/synergies/schemas";
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
      (type === "verb" || type === "element" || type === "weapon_archetype") &&
      trimmed === "Base"
    ) {
      return { ok: false, reason: `Base is not valid for ${type} synergies` };
    }
    if (type === "element" && !(SYNERGY_ELEMENTS as readonly string[]).includes(trimmed)) {
      return { ok: false, reason: `Unknown element subType: ${trimmed}` };
    }
    if (type === "verb") {
      const canonical = resolveVerbSubType(trimmed);
      if (!canonical) {
        return { ok: false, reason: `Unknown verb subType: ${trimmed}` };
      }
      return { ok: true, subType: canonical };
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
