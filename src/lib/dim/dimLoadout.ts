import type { ResolvedBuildSheet, ResolvedStatTarget } from "@/lib/build/types";

export interface DimLoadoutItem {
  id?: string;
  hash: number;
  amount?: number;
  socketOverrides?: { [socketIndex: number]: number };
}

export interface DimStatConstraint {
  statHash: number;
  minStat?: number;
  maxStat?: number;
}

export interface DimLoadoutParameters {
  statConstraints?: DimStatConstraint[];
  mods?: number[];
  exoticArmorHash?: number;
  autoStatMods?: boolean;
  includeRuntimeStatBenefits?: boolean;
}

export interface DimLoadout {
  id: string;
  name: string;
  notes?: string;
  classType: number;
  equipped: DimLoadoutItem[];
  unequipped: DimLoadoutItem[];
  parameters?: DimLoadoutParameters;
}

const CLASS_TYPE: Record<"Titan" | "Hunter" | "Warlock", number> = {
  Titan: 0,
  Hunter: 1,
  Warlock: 2,
};

const STAT_HASHES: Record<string, number> = {
  Weapons: 2996146975,
  Health: 392767087,
  Class: 1943323491,
  Grenade: 1735777505,
  Super: 144602215,
  Melee: 4244567218,
};

function buildEquipped(sheet: ResolvedBuildSheet): DimLoadoutItem[] {
  const items: DimLoadoutItem[] = [];

  for (const weapon of sheet.weapons) {
    const hash = weapon.reference.resolved?.hash;
    if (hash !== undefined) {
      items.push({ hash });
    }
  }

  const exoticHash = sheet.exoticArmor.resolved?.hash;
  if (exoticHash !== undefined) {
    items.push({ hash: exoticHash });
  }

  return items;
}

function buildModHashes(sheet: ResolvedBuildSheet): number[] {
  const hashes: number[] = [];
  for (const modSlot of sheet.mods) {
    for (const pick of modSlot.picks) {
      const hash = pick.resolved?.hash;
      if (hash !== undefined) {
        hashes.push(hash);
      }
    }
  }
  return hashes;
}

function buildStatConstraints(targets: ResolvedStatTarget[]): DimStatConstraint[] {
  return [...targets]
    .filter((t) => STAT_HASHES[t.stat] !== undefined)
    .sort((a, b) => b.target - a.target)
    .map((t) => ({ statHash: STAT_HASHES[t.stat], minStat: t.target }));
}

function buildParameters(sheet: ResolvedBuildSheet): DimLoadoutParameters {
  const params: DimLoadoutParameters = {
    autoStatMods: true,
    includeRuntimeStatBenefits: true,
  };

  const exoticHash = sheet.exoticArmor.resolved?.hash;
  if (exoticHash !== undefined) {
    params.exoticArmorHash = exoticHash;
  }

  const mods = buildModHashes(sheet);
  if (mods.length > 0) {
    params.mods = mods;
  }

  const statConstraints = buildStatConstraints(sheet.statTargets);
  if (statConstraints.length > 0) {
    params.statConstraints = statConstraints;
  }

  return params;
}

export function buildDimLoadout(
  sheet: ResolvedBuildSheet,
  className: "Titan" | "Hunter" | "Warlock",
): DimLoadout {
  return {
    id: crypto.randomUUID(),
    name: sheet.build.name.slice(0, 120),
    notes: sheet.build.summary?.slice(0, 1024),
    classType: CLASS_TYPE[className],
    equipped: buildEquipped(sheet),
    unequipped: [],
    parameters: buildParameters(sheet),
  };
}
