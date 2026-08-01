/**
 * Armor Set package bonus constraint (DBR-SETB-003–007, BR-SET-050–056).
 *
 * Zero or one constraint per Armor Set: family (hash) + target tier 2|4.
 * Non-exotic filled pieces must be members; exotics do not count toward tier.
 */

import { z } from "zod";

import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import type { SetBonusRecord } from "@/lib/manifest/types/records";
import type { SetType } from "@/lib/sets/schemas";

export const armorSetBonusConstraintSchema = z.object({
  armorSetHash: z.number().int().positive(),
  armorSetName: z.string().trim().min(1).optional(),
  targetTier: z.union([z.literal(2), z.literal(4)]),
});

export type ArmorSetBonusConstraint = z.infer<typeof armorSetBonusConstraintSchema>;

export type ConstrainedArmorPiece = {
  itemHash: number;
  /** True when piece is exotic armor (does not contribute to tier). */
  isExotic?: boolean;
  slot?: string;
  itemName?: string;
};

export type SoftWarning = { code: string; message: string };

export type ArmorSetBonusConstraintResult =
  | {
      ok: true;
      memberCount: number;
      targetTier: number;
      softWarnings: SoftWarning[];
    }
  | {
      ok: false;
      code:
        | typeof API_ERROR_CODES.ARMOR_SET_BONUS_MISMATCH
        | typeof API_ERROR_CODES.ARMOR_SET_BONUS_INCOMPLETE;
      message: string;
      memberCount: number;
      targetTier: number;
      softWarnings: SoftWarning[];
      mismatchHashes?: number[];
    };

export function parseArmorSetBonusConstraint(
  raw: string | null | undefined,
): ArmorSetBonusConstraint | null {
  if (raw == null || raw === "") return null;
  try {
    const parsed = JSON.parse(raw) as unknown;
    const result = armorSetBonusConstraintSchema.safeParse(parsed);
    return result.success ? result.data : null;
  } catch {
    return null;
  }
}

export function serializeArmorSetBonusConstraint(
  constraint: ArmorSetBonusConstraint,
): string {
  return JSON.stringify(constraint);
}

/** itemHash → set-bonus definition hash for pieces that belong to a family. */
export function buildSetBonusMembershipIndex(
  setBonuses: SetBonusRecord[],
): Map<number, number> {
  const map = new Map<number, number>();
  for (const bonus of setBonuses) {
    for (const itemHash of bonus.itemHashes ?? []) {
      map.set(itemHash, bonus.hash);
    }
  }
  return map;
}

export type EvaluateArmorSetBonusOptions = {
  /**
   * When true (default), contributing member count must meet target tier.
   * When false (fill path), only membership mismatch is hard-failed so users
   * can add pieces one-by-one until attach/save.
   */
  requireTier?: boolean;
};

/**
 * Evaluate hard package constraint against active armor pieces.
 * Empty set (no pieces) is OK — still filling; attach occupancy is separate.
 */
export function evaluateArmorSetBonusConstraint(
  constraint: ArmorSetBonusConstraint | null | undefined,
  pieces: ConstrainedArmorPiece[],
  membership: Map<number, number>,
  opts?: EvaluateArmorSetBonusOptions,
): ArmorSetBonusConstraintResult {
  const requireTier = opts?.requireTier !== false;

  if (!constraint) {
    return {
      ok: true,
      memberCount: 0,
      targetTier: 0,
      softWarnings: [],
    };
  }

  const softWarnings: SoftWarning[] = [];
  const filled = pieces.filter((p) => p.itemHash > 0);
  if (filled.length === 0) {
    return {
      ok: true,
      memberCount: 0,
      targetTier: constraint.targetTier,
      softWarnings: [],
    };
  }

  const mismatchHashes: number[] = [];
  let memberCount = 0;
  let exoticCount = 0;

  for (const piece of filled) {
    if (piece.isExotic) {
      exoticCount += 1;
      continue;
    }
    const family = membership.get(piece.itemHash);
    if (family !== constraint.armorSetHash) {
      mismatchHashes.push(piece.itemHash);
      continue;
    }
    memberCount += 1;
  }

  if (mismatchHashes.length > 0) {
    return {
      ok: false,
      code: API_ERROR_CODES.ARMOR_SET_BONUS_MISMATCH,
      message: `Non-exotic armor must belong to set bonus family ${constraint.armorSetName ?? constraint.armorSetHash}`,
      memberCount,
      targetTier: constraint.targetTier,
      softWarnings,
      mismatchHashes,
    };
  }

  if (memberCount < constraint.targetTier) {
    if (exoticCount > 0) {
      softWarnings.push({
        code: "EXOTIC_BLOCKS_SET_BONUS",
        message: `Exotic armor does not count toward ${constraint.targetTier}pc; currently ${memberCount} contributing members`,
      });
    }
    if (!requireTier) {
      return {
        ok: true,
        memberCount,
        targetTier: constraint.targetTier,
        softWarnings,
      };
    }
    return {
      ok: false,
      code: API_ERROR_CODES.ARMOR_SET_BONUS_INCOMPLETE,
      message: `Armor set needs ${constraint.targetTier} contributing members of ${constraint.armorSetName ?? constraint.armorSetHash} (has ${memberCount})`,
      memberCount,
      targetTier: constraint.targetTier,
      softWarnings,
    };
  }

  return {
    ok: true,
    memberCount,
    targetTier: constraint.targetTier,
    softWarnings,
  };
}

export function assertArmorSetBonusConstraint(
  constraint: ArmorSetBonusConstraint | null | undefined,
  pieces: ConstrainedArmorPiece[],
  membership: Map<number, number>,
  opts?: EvaluateArmorSetBonusOptions & { context?: string; setType?: SetType },
): SoftWarning[] {
  if (opts?.setType && opts.setType !== "armor") {
    if (constraint) {
      throw new ApiError(
        API_ERROR_CODES.INVALID_ITEM,
        "Armor set bonus constraint is only allowed on Armor Sets",
        { setType: opts.setType },
        400,
      );
    }
    return [];
  }

  const result = evaluateArmorSetBonusConstraint(constraint, pieces, membership, {
    requireTier: opts?.requireTier,
  });
  if (result.ok) return result.softWarnings;
  throw new ApiError(
    result.code,
    result.message,
    {
      memberCount: result.memberCount,
      targetTier: result.targetTier,
      mismatchHashes: result.mismatchHashes,
      softWarnings: result.softWarnings,
      context: opts?.context,
    },
    400,
  );
}

