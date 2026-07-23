import { isKitValid, type KitConstraints } from "./constraints";
import { ARMOR_OPTIMIZER_SLOTS, type ArmorSlot, type CandidatePiece } from "./types";

/** Upper bound on evaluated kits before returning best-so-far (R9). */
export const DEFAULT_MAX_COMBINATIONS = 250_000;

export type EnumerateOptions = {
  constraints: KitConstraints;
  maxCombinations?: number;
};

export type EnumerateResult = {
  kits: CandidatePiece[][];
  evaluatedCount: number;
  truncated: boolean;
};

export function groupBySlot(pieces: CandidatePiece[]): Map<ArmorSlot, CandidatePiece[]> {
  const bySlot = new Map<ArmorSlot, CandidatePiece[]>();
  for (const slot of ARMOR_OPTIMIZER_SLOTS) bySlot.set(slot, []);
  for (const piece of pieces) bySlot.get(piece.slot)?.push(piece);
  return bySlot;
}

type SearchContext = {
  slots: CandidatePiece[][];
  constraints: KitConstraints;
  max: number;
  kits: CandidatePiece[][];
  evaluated: number;
  truncated: boolean;
};

function evaluateKit(context: SearchContext, current: CandidatePiece[]): void {
  if (context.evaluated >= context.max) {
    context.truncated = true;
    return;
  }
  context.evaluated += 1;
  if (isKitValid(current, context.constraints)) context.kits.push([...current]);
}

function search(context: SearchContext, index: number, current: CandidatePiece[], exotics: number): void {
  if (context.truncated) return;
  if (index === context.slots.length) {
    evaluateKit(context, current);
    return;
  }

  for (const piece of context.slots[index]) {
    const nextExotics = exotics + (piece.isExotic ? 1 : 0);
    if (nextExotics > 1) continue;
    current.push(piece);
    search(context, index + 1, current, nextExotics);
    current.pop();
    if (context.truncated) return;
  }
}

export function enumerateKits(
  bySlot: Map<ArmorSlot, CandidatePiece[]>,
  options: EnumerateOptions,
): EnumerateResult {
  const slots = ARMOR_OPTIMIZER_SLOTS.map((slot) => bySlot.get(slot) ?? []);
  if (slots.some((list) => list.length === 0)) {
    return { kits: [], evaluatedCount: 0, truncated: false };
  }

  const context: SearchContext = {
    slots,
    constraints: options.constraints,
    max: options.maxCombinations ?? DEFAULT_MAX_COMBINATIONS,
    kits: [],
    evaluated: 0,
    truncated: false,
  };
  search(context, 0, [], 0);

  return { kits: context.kits, evaluatedCount: context.evaluated, truncated: context.truncated };
}
