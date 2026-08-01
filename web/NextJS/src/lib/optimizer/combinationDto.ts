import { buildSetBonusSummary, type SetBonusSummaryEntry } from "./constraints";
import type { ArmorOptimizePiece, CandidatePiece } from "./types";

/**
 * Shape an internal {@link CandidatePiece} into the API {@link ArmorOptimizePiece}
 * DTO. Reuse annotations are exposed as `usedInOtherSets` (armor-optimize
 * contract): other Armor Sets — excluding the Set under search — that already
 * hold this active instance.
 */
export function toCombinationPiece(piece: CandidatePiece): ArmorOptimizePiece {
  return {
    slot: piece.slot,
    itemHash: piece.itemHash,
    instanceId: piece.instanceId,
    ...(piece.itemName ? { itemName: piece.itemName } : {}),
    isExotic: piece.isExotic,
    ...(piece.setBonusKey ? { setBonusKey: piece.setBonusKey } : {}),
    statValues: piece.statValues,
    usedInOtherSets: piece.usedInSets.map((set) => ({ id: set.id, name: set.name })),
  };
}

/** Per-family set-bonus coverage summary with 2pc/4pc activation flags. */
export function toSetBonusSummary(kit: CandidatePiece[]): SetBonusSummaryEntry[] {
  return buildSetBonusSummary(kit);
}
