import { ARMOR_STAT_NAMES, type ArmorStatName } from "@/data/rules/statBenefits";

import type { ArmorSlot, AssumedMod, CandidatePiece } from "./types";

type StatTotals = Partial<Record<ArmorStatName, number>>;

/** A synthetic general-armor stat mod in the curated auto-assign pool. */
type StatMod = {
  itemHash: number;
  name: string;
  stat: ArmorStatName;
  statDelta: number;
  energyCost: number;
};

/**
 * Curated synthetic general-armor stat-mod pool (research R4). Per Armor 3.0
 * stat we expose one "major" (+10 / 3 energy) and one "minor" (+5 / 1 energy)
 * plug. It is intentionally tiny: enough to exercise per-piece energy legality
 * (DBR-MOD-002) without loading the full manifest mod catalog. Swapping in real
 * general armor mods from the entity cache is a future enhancement.
 */
const MAJOR_ENERGY = 3;
const MINOR_ENERGY = 1;
const MAJOR_DELTA = 10;
const MINOR_DELTA = 5;

function modFor(stat: ArmorStatName, tier: "major" | "minor"): StatMod {
  const index = ARMOR_STAT_NAMES.indexOf(stat);
  const major = tier === "major";
  return {
    itemHash: (major ? 900_000_000 : 910_000_000) + index,
    name: `${major ? "Major" : "Minor"} ${stat} Mod`,
    stat,
    statDelta: major ? MAJOR_DELTA : MINOR_DELTA,
    energyCost: major ? MAJOR_ENERGY : MINOR_ENERGY,
  };
}

type PieceBudget = { slot: ArmorSlot; remaining: number };

/** Stats with a numeric threshold, ordered by caller priority (unlisted last). */
function orderedTargetStats(thresholds: StatTotals, priorities: ArmorStatName[]): ArmorStatName[] {
  const rank = (stat: ArmorStatName): number => {
    const i = priorities.indexOf(stat);
    return i === -1 ? Number.MAX_SAFE_INTEGER : i;
  };
  return ARMOR_STAT_NAMES.filter((stat) => typeof thresholds[stat] === "number").sort(
    (a, b) => rank(a) - rank(b),
  );
}

/** Piece with the most free energy that still fits the mod, or null. */
function pickPiece(budgets: PieceBudget[], energyCost: number): PieceBudget | null {
  let best: PieceBudget | null = null;
  for (const budget of budgets) {
    if (budget.remaining < energyCost) continue;
    if (!best || budget.remaining > best.remaining) best = budget;
  }
  return best;
}

function toAssumedMod(mod: StatMod, slot: ArmorSlot): AssumedMod {
  return {
    armorSlot: slot,
    itemHash: mod.itemHash,
    name: mod.name,
    energyCost: mod.energyCost,
    statDeltas: { [mod.stat]: mod.statDelta },
  };
}

function fillStat(stat: ArmorStatName, deficit: number, budgets: PieceBudget[]): AssumedMod[] {
  const mods: AssumedMod[] = [];
  let remainingDeficit = deficit;
  while (remainingDeficit > 0) {
    const mod = modFor(stat, remainingDeficit >= MAJOR_DELTA ? "major" : "minor");
    const piece = pickPiece(budgets, mod.energyCost);
    if (!piece) break;
    piece.remaining -= mod.energyCost;
    remainingDeficit -= mod.statDelta;
    mods.push(toAssumedMod(mod, piece.slot));
  }
  return mods;
}

/**
 * Greedy auto stat-mod assigner: spends per-piece armor energy on curated
 * general stat mods to close soft-threshold deficits, highest-priority stat
 * first. Returns an auditable list of assumed mods (empty when no thresholds).
 */
export function assignAutoStatMods(params: {
  pieces: CandidatePiece[];
  baseStats: StatTotals;
  thresholds?: StatTotals;
  priorities?: ArmorStatName[];
}): AssumedMod[] {
  if (!params.thresholds) return [];
  const budgets: PieceBudget[] = params.pieces.map((piece) => ({
    slot: piece.slot,
    remaining: piece.energyCapacity,
  }));

  const mods: AssumedMod[] = [];
  for (const stat of orderedTargetStats(params.thresholds, params.priorities ?? [])) {
    const deficit = (params.thresholds[stat] ?? 0) - (params.baseStats[stat] ?? 0);
    if (deficit > 0) mods.push(...fillStat(stat, deficit, budgets));
  }
  return mods;
}
