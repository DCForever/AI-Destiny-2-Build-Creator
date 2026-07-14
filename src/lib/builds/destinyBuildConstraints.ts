/**
 * Pure hard-block evaluators for Builds / variants (UI + tests).
 * Server may call these after resolving equipment claims to exotic flags.
 */

export type HardBlock = {
  code: string;
  message: string;
};

export type SoftWarning = {
  code: string;
  message: string;
};

export type ConstraintEvaluation = {
  hardBlocks: HardBlock[];
  softWarnings: SoftWarning[];
};

/** Destiny allows two aspects on a subclass kit. */
export const MAX_SUBCLASS_ASPECTS = 2;

/** Unique exotic hashes by kind (already filtered to exotic items). */
export type ExoticComposition = {
  exoticWeaponHashes: number[];
  exoticArmorHashes: number[];
};

/**
 * DBR-CMP-007 / DAC-DST-001: at most one exotic weapon and one exotic armor.
 */
export function evaluateExoticLimits(
  composition: ExoticComposition,
): ConstraintEvaluation {
  const hardBlocks: HardBlock[] = [];
  const weapons = uniquePositive(composition.exoticWeaponHashes);
  const armor = uniquePositive(composition.exoticArmorHashes);

  if (weapons.length > 1) {
    hardBlocks.push({
      code: "TOO_MANY_EXOTICS",
      message: `At most one exotic weapon can be equipped (found ${weapons.length})`,
    });
  }
  if (armor.length > 1) {
    hardBlocks.push({
      code: "TOO_MANY_EXOTICS",
      message: `At most one exotic armor piece can be equipped (found ${armor.length})`,
    });
  }

  return { hardBlocks, softWarnings: [] };
}

/** DBR-SYN-003: ≥1 designated synergy type. */
export function evaluateSynergyRequirement(
  synergyTypes: readonly unknown[],
): ConstraintEvaluation {
  if (synergyTypes.length === 0) {
    return {
      hardBlocks: [
        {
          code: "NO_SYNERGY",
          message: "Build must designate at least one synergy type",
        },
      ],
      softWarnings: [],
    };
  }
  return { hardBlocks: [], softWarnings: [] };
}

/**
 * DBR-SUB-004 / DAC-DST-003: aspect count + fragment capacity.
 * When `capacityResolved` is false (aspects not found in store), fragment
 * capacity is not hard-enforced (server resolves by name when possible).
 */
export function evaluateSubclassKit(input: {
  aspectCount: number;
  fragmentCount: number;
  /** Sum of aspect fragmentCapacity values. */
  fragmentCapacity: number;
  maxAspects?: number;
  /** False when caller could not resolve aspect capacities. */
  capacityResolved?: boolean;
}): ConstraintEvaluation {
  const hardBlocks: HardBlock[] = [];
  const maxAspects = input.maxAspects ?? MAX_SUBCLASS_ASPECTS;

  if (input.aspectCount > maxAspects) {
    hardBlocks.push({
      code: "ILLEGAL_SUBCLASS_KIT",
      message: `At most ${maxAspects} aspects allowed (selected ${input.aspectCount})`,
    });
  }

  const capacityResolved = input.capacityResolved !== false;
  if (
    capacityResolved &&
    input.fragmentCount > input.fragmentCapacity
  ) {
    hardBlocks.push({
      code: "ILLEGAL_SUBCLASS_KIT",
      message: `Too many fragments (${input.fragmentCount}/${input.fragmentCapacity} from aspects)`,
    });
  }

  return { hardBlocks, softWarnings: [] };
}

/** Per-piece armor mod energy usage. */
export type ModEnergyPiece = {
  slot: string;
  energyUsed: number;
  energyCapacity: number;
};

/**
 * DBR-MOD-001–002 / DAC-DST-002: piece energy must not exceed capacity.
 */
export function evaluateModEnergy(pieces: ModEnergyPiece[]): ConstraintEvaluation {
  const hardBlocks: HardBlock[] = [];
  for (const piece of pieces) {
    if (piece.energyUsed > piece.energyCapacity) {
      hardBlocks.push({
        code: "MOD_ENERGY_EXCEEDED",
        message: `${piece.slot}: mods use ${piece.energyUsed} energy (capacity ${piece.energyCapacity})`,
      });
    }
  }
  return { hardBlocks, softWarnings: [] };
}

export type AbilityKitFields = {
  super?: string | null;
  melee?: string | null;
  grenade?: string | null;
  classAbility?: string | null;
};

/**
 * DBR-SUB-005 / DAC-DST-004: exotic-required abilities must match kit
 * (and pinned Super when the requirement is a Super).
 */
export function evaluateExoticAbilityMatch(input: {
  required: AbilityKitFields;
  kit: AbilityKitFields;
  pinnedSuper?: string | null;
}): ConstraintEvaluation {
  const hardBlocks: HardBlock[] = [];
  const softWarnings: SoftWarning[] = [];
  const req = input.required;
  const kit = input.kit;

  const checks: Array<{
    key: keyof AbilityKitFields;
    label: string;
    kitValue: string | null | undefined;
    pinValue?: string | null | undefined;
  }> = [
    {
      key: "super",
      label: "Super",
      kitValue: kit.super,
      pinValue: input.pinnedSuper,
    },
    { key: "melee", label: "melee", kitValue: kit.melee },
    { key: "grenade", label: "grenade", kitValue: kit.grenade },
    { key: "classAbility", label: "class ability", kitValue: kit.classAbility },
  ];

  let hasRequirement = false;
  for (const check of checks) {
    const needed = req[check.key]?.trim();
    if (!needed) continue;
    hasRequirement = true;
    const effective =
      check.key === "super"
        ? (check.pinValue?.trim() || check.kitValue?.trim() || "")
        : (check.kitValue?.trim() || "");
    if (!namesMatch(effective, needed)) {
      hardBlocks.push({
        code: "EXOTIC_ABILITY_MISMATCH",
        message: `Exotic requires ${check.label} "${needed}" (kit has "${effective || "none"}")`,
      });
    }
  }

  if (hasRequirement && hardBlocks.length === 0) {
    // no soft
  } else if (hasRequirement && hardBlocks.length > 0) {
    softWarnings.push({
      code: "EXOTIC_ABILITY_PIN_PROPOSED",
      message: "Confirm ability pins to match this exotic's requirements",
    });
  }

  return { hardBlocks, softWarnings };
}

export function mergeConstraintEvaluations(
  ...parts: ConstraintEvaluation[]
): ConstraintEvaluation {
  return {
    hardBlocks: parts.flatMap((p) => p.hardBlocks),
    softWarnings: parts.flatMap((p) => p.softWarnings),
  };
}

function uniquePositive(hashes: number[]): number[] {
  return [...new Set(hashes.filter((h) => Number.isFinite(h) && h > 0))];
}

function namesMatch(a: string, b: string): boolean {
  return a.trim().toLowerCase() === b.trim().toLowerCase();
}
