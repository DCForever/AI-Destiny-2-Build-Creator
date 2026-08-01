import {
  ARMOR_OPTIMIZER_SLOTS,
  type CandidatePiece,
  type SetBonusCoverageGoal,
} from "./types";

/** Hard constraints applied to every enumerated kit. */
export type KitConstraints = {
  lockedExoticItemHash?: number | null;
  requireExotic?: boolean;
  setBonusGoals?: SetBonusCoverageGoal[];
};

export type SetBonusSummaryEntry = {
  setBonusKey: string;
  pieceCount: number;
  active2pc: boolean;
  active4pc: boolean;
};

export function countExotics(pieces: CandidatePiece[]): number {
  return pieces.reduce((total, piece) => total + (piece.isExotic ? 1 : 0), 0);
}

export function setBonusPieceCounts(pieces: CandidatePiece[]): Map<string, number> {
  const counts = new Map<string, number>();
  for (const piece of pieces) {
    if (!piece.setBonusKey) continue;
    counts.set(piece.setBonusKey, (counts.get(piece.setBonusKey) ?? 0) + 1);
  }
  return counts;
}

export function satisfiesSetBonusGoals(
  pieces: CandidatePiece[],
  goals: SetBonusCoverageGoal[] | undefined,
): boolean {
  if (!goals || goals.length === 0) return true;
  const counts = setBonusPieceCounts(pieces);
  return goals.every((goal) => (counts.get(goal.setBonusKey) ?? 0) >= goal.minPieces);
}

function isCompleteKit(pieces: CandidatePiece[]): boolean {
  if (pieces.length !== ARMOR_OPTIMIZER_SLOTS.length) return false;
  return new Set(pieces.map((piece) => piece.slot)).size === ARMOR_OPTIMIZER_SLOTS.length;
}

export function isKitValid(pieces: CandidatePiece[], constraints: KitConstraints): boolean {
  if (!isCompleteKit(pieces)) return false;

  const exotics = countExotics(pieces);
  if (exotics > 1) return false;
  if (constraints.requireExotic && exotics < 1) return false;

  const locked = constraints.lockedExoticItemHash;
  if (locked != null && !pieces.some((piece) => piece.itemHash === locked)) return false;

  return satisfiesSetBonusGoals(pieces, constraints.setBonusGoals);
}

export function buildSetBonusSummary(pieces: CandidatePiece[]): SetBonusSummaryEntry[] {
  return [...setBonusPieceCounts(pieces).entries()].map(([setBonusKey, pieceCount]) => ({
    setBonusKey,
    pieceCount,
    active2pc: pieceCount >= 2,
    active4pc: pieceCount >= 4,
  }));
}
