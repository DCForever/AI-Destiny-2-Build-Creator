/**
 * Server: DBR-SUB-005 exotic ability requirements must match kit.
 */

import {
  hasAbilityRequirements,
  lookupExoticAbilityRequirements,
} from "@/data/exoticAbilityRequirements";
import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import { evaluateExoticAbilityMatch } from "@/lib/builds/destinyBuildConstraints";
import type { SubclassKitInput } from "@/lib/builds/assertSubclassKit";

export function assertExoticAbilityPins(input: {
  exoticArmorHash?: number | null;
  exoticArmorName?: string | null;
  pinnedSuper?: string | null;
  subclass: SubclassKitInput;
}): void {
  const required = lookupExoticAbilityRequirements({
    hash: input.exoticArmorHash,
    name: input.exoticArmorName,
  });
  if (!hasAbilityRequirements(required)) return;

  const { hardBlocks } = evaluateExoticAbilityMatch({
    required: required!,
    kit: {
      super: input.subclass.super,
      melee: input.subclass.melee,
      grenade: input.subclass.grenade,
      classAbility: input.subclass.classAbility,
    },
    pinnedSuper: input.pinnedSuper,
  });

  if (hardBlocks.length === 0) return;
  throw new ApiError(
    API_ERROR_CODES.EXOTIC_ABILITY_MISMATCH,
    hardBlocks.map((b) => b.message).join("; "),
    { hardBlocks, required },
    400,
  );
}

/** Apply required ability names onto a subclass draft (pin propose accept). */
export function applyAbilityRequirementPins<
  T extends {
    super?: string;
    melee?: string;
    grenade?: string;
    classAbility?: string;
  },
>(
  subclass: T,
  required: {
    super?: string;
    melee?: string;
    grenade?: string;
    classAbility?: string;
  },
): T {
  return {
    ...subclass,
    ...(required.super ? { super: required.super } : {}),
    ...(required.melee ? { melee: required.melee } : {}),
    ...(required.grenade ? { grenade: required.grenade } : {}),
    ...(required.classAbility ? { classAbility: required.classAbility } : {}),
  };
}
