/**
 * Armor 3.0 gear tier (1–5) resolution.
 *
 * Primary source is the Bungie API `gearTier` (instance component 300),
 * captured during inventory sync. A curated stat-band heuristic is only a
 * fallback for legacy (pre-v9.0.0) copies whose `gearTier` is null. See
 * specs/010-instance-disambiguation/research.md (R1).
 */

export type ArmorTierNumber = 1 | 2 | 3 | 4 | 5;

export type ArmorTierSource = "api" | "estimated" | "none";

export interface ArmorTier {
  tier: ArmorTierNumber | null;
  label: string;
  source: ArmorTierSource;
  approximate: boolean;
  available: boolean;
}

export interface ResolveArmorTierInput {
  /** Bungie `gearTier` from instance component 300; null for legacy copies. */
  gearTier: number | null | undefined;
  /** Sum of the six Armor 3.0 stats; only used for the legacy fallback. */
  totalStats?: number;
  isExotic: boolean;
  /** True when all six armor stats were synced (see parseArmorStats). */
  statsComplete: boolean;
}

/**
 * Fallback stat-band table (GamesRadar/TheGamer consensus). Inclusive lower
 * bounds. Only consulted for legacy legendary copies with complete stats.
 */
function estimateTierFromTotal(totalStats: number): ArmorTierNumber {
  if (totalStats <= 57) return 1;
  if (totalStats <= 63) return 2;
  if (totalStats <= 69) return 3;
  if (totalStats <= 74) return 4;
  return 5;
}

function isValidGearTier(value: number): value is ArmorTierNumber {
  return Number.isInteger(value) && value >= 1 && value <= 5;
}

export function resolveArmorTier(input: ResolveArmorTierInput): ArmorTier {
  const { gearTier, totalStats, isExotic, statsComplete } = input;

  if (typeof gearTier === "number" && isValidGearTier(gearTier)) {
    return {
      tier: gearTier,
      label: isExotic ? `Exotic · Tier ${gearTier}` : `Tier ${gearTier}`,
      source: "api",
      approximate: false,
      available: true,
    };
  }

  if (isExotic) {
    return { tier: null, label: "Exotic", source: "api", approximate: false, available: true };
  }

  if (statsComplete && typeof totalStats === "number") {
    const tier = estimateTierFromTotal(totalStats);
    return {
      tier,
      label: `~Tier ${tier}`,
      source: "estimated",
      approximate: true,
      available: true,
    };
  }

  return { tier: null, label: "Tier unavailable", source: "none", approximate: false, available: false };
}
