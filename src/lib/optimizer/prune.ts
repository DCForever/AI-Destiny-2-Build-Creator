import type { ArmorStatName } from "@/data/rules/statBenefits";

import { sumPrioritizedStats } from "./score";
import {
  ARMOR_OPTIMIZER_SLOTS,
  type ArmorSlot,
  type CandidatePiece,
  type SetBonusCoverageGoal,
} from "./types";

/**
 * Per-slot retention cap. With five slots this bounds the Cartesian product
 * near the ~250k evaluation budget (R9); enumeration truncates beyond it.
 */
export const DEFAULT_PRUNE_K = 16;

export type PruneOptions = {
  priorities?: ArmorStatName[];
  k?: number;
  lockedExoticItemHash?: number | null;
  setBonusGoals?: SetBonusCoverageGoal[];
};

function pieceScore(piece: CandidatePiece, priorities: ArmorStatName[] | undefined): number {
  return sumPrioritizedStats(piece.statValues, priorities);
}

function topK(
  pieces: CandidatePiece[],
  priorities: ArmorStatName[] | undefined,
  k: number,
): CandidatePiece[] {
  return [...pieces].sort((a, b) => pieceScore(b, priorities) - pieceScore(a, priorities)).slice(0, k);
}

export function prunePiecesForSlot(
  pieces: CandidatePiece[],
  options: PruneOptions,
): CandidatePiece[] {
  const k = options.k ?? DEFAULT_PRUNE_K;
  const kept = new Map<string, CandidatePiece>();
  const retain = (list: CandidatePiece[]) => {
    for (const piece of list) kept.set(piece.instanceId, piece);
  };

  retain(topK(pieces, options.priorities, k));

  if (options.lockedExoticItemHash != null) {
    retain(pieces.filter((piece) => piece.itemHash === options.lockedExoticItemHash));
  }

  for (const goal of options.setBonusGoals ?? []) {
    const family = pieces.filter((piece) => piece.setBonusKey === goal.setBonusKey);
    retain(topK(family, options.priorities, k));
  }

  return [...kept.values()];
}

export function prunePiecesBySlot(
  bySlot: Map<ArmorSlot, CandidatePiece[]>,
  options: PruneOptions,
): Map<ArmorSlot, CandidatePiece[]> {
  const result = new Map<ArmorSlot, CandidatePiece[]>();
  for (const slot of ARMOR_OPTIMIZER_SLOTS) {
    result.set(slot, prunePiecesForSlot(bySlot.get(slot) ?? [], options));
  }
  return result;
}
