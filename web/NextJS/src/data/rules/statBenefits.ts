/**
 * Armor 3.0 stat benefit curves (0-200 scale), transcribed from Bungie's
 * Armor 3.0 documentation and the 9.7.0 patch notes. Every stat scales
 * linearly per point; 101-200 grants an enhanced benefit that also scales
 * linearly, reaching the listed maximum at 200. Sources cached in
 * `src/data/meta/sources/`.
 */

export type ArmorStatName =
  | "Health"
  | "Melee"
  | "Grenade"
  | "Super"
  | "Class"
  | "Weapons";

export const ARMOR_STAT_NAMES: readonly ArmorStatName[] = [
  "Health",
  "Melee",
  "Grenade",
  "Super",
  "Class",
  "Weapons",
];

export const STAT_MAX = 200;
export const ENHANCED_THRESHOLD = 100;

export interface ScalingBenefit {
  /** Template with `{v}` placeholder, e.g. "+{v}% grenade ability damage". */
  template: string;
  /** Value reached at stat 100 (base range) or 200 (enhanced range). */
  max: number;
  /** Decimal places when rendering the interpolated value. */
  precision?: number;
}

export interface StatBenefitDefinition {
  stat: ArmorStatName;
  /** Always-on effects across 0-100, shown as static text. */
  baseEffects: readonly string[];
  /** Benefits that scale across 0-100 (value at stat 100 = max). */
  baseScaling: readonly ScalingBenefit[];
  /** Benefits that scale across 101-200 (value at stat 200 = max). */
  enhancedScaling: readonly ScalingBenefit[];
  /** Non-scaling notes for the enhanced range. */
  enhancedNotes: readonly string[];
}

export const STAT_BENEFITS: Record<ArmorStatName, StatBenefitDefinition> = {
  Health: {
    stat: "Health",
    baseEffects: [],
    baseScaling: [
      { template: "+{v} HP healing when picking up an Orb of Power", max: 70 },
      { template: "+{v}% flinch resistance", max: 10 },
    ],
    enhancedScaling: [
      { template: "+{v} shield capacity vs combatants", max: 20 },
      { template: "shields start recharging {v}% sooner", max: 25 },
      { template: "{v}% less time to fully recharge shields", max: 50 },
    ],
    enhancedNotes: [],
  },
  Melee: {
    stat: "Melee",
    baseEffects: [
      "Improves melee ability base cooldown",
      "Improves melee energy gained from external sources and regen scalars",
    ],
    baseScaling: [],
    enhancedScaling: [
      { template: "+{v}% melee ability damage", max: 30 },
    ],
    enhancedNotes: ["Applies to powered, unpowered, and glaive melees"],
  },
  Grenade: {
    stat: "Grenade",
    baseEffects: [
      "Improves grenade ability base cooldown",
      "Improves grenade energy gained from external sources and regen scalars",
    ],
    baseScaling: [],
    enhancedScaling: [
      { template: "+{v}% grenade ability damage", max: 65 },
    ],
    enhancedNotes: [],
  },
  Super: {
    stat: "Super",
    baseEffects: [
      "Improves Super energy gained from damaging targets (base cooldown unchanged)",
      "Improves Super energy gained from external sources and regen scalars",
    ],
    baseScaling: [],
    enhancedScaling: [
      { template: "+{v}% Super ability damage", max: 45 },
    ],
    enhancedNotes: [],
  },
  Class: {
    stat: "Class",
    baseEffects: [
      "Improves class ability base cooldown",
      "Improves class energy gained from external sources and regen scalars",
    ],
    baseScaling: [],
    enhancedScaling: [
      { template: "{v} HP overshield on casting your class ability (PvE)", max: 40 },
      { template: "{v} HP overshield on cast in PvP", max: 10 },
    ],
    enhancedNotes: [
      "Overshield duration is tied to the ability's cooldown length",
    ],
  },
  Weapons: {
    stat: "Weapons",
    baseEffects: ["Improves weapon reload and handling speeds"],
    baseScaling: [
      { template: "+{v}% damage vs minor and major combatants (primary and special)", max: 15 },
      { template: "+{v}% damage vs minor and major combatants (heavy)", max: 10 },
    ],
    enhancedScaling: [
      { template: "+{v}% damage vs bosses (primary and special, PvE)", max: 15 },
      { template: "+{v}% damage vs bosses (heavy, PvE)", max: 10 },
      { template: "+{v}% weapon damage vs Guardians (PvP)", max: 6 },
    ],
    enhancedNotes: [
      "Ammo bricks have a chance to contain more ammo than normal",
    ],
  },
};

/**
 * 9.7.0 sandbox notes layered on top of the curves (patch notes "Abilities"):
 * several damaging class abilities additionally scale with Class above 100,
 * and ability cooldown scalars were trimmed.
 */
export const CLASS_STAT_SCALING_ABILITIES: readonly string[] = [
  "Shieldburst",
  "Ascension",
  "Threaded Specter",
  "Drengr's Lash",
];

export const ABILITY_ECONOMY_NOTES: readonly string[] = [
  "Max passive ability-cooldown bonus from stats reduced by ~20% (9.7.0)",
  "Max active ability-cooldown bonus reduced from 190% to 125% (9.7.0)",
  "Super energy from boss damage reduced by 60% (9.7.0)",
  "Grenade/Melee stat boss-damage bonuses are additive, not multiplicative (9.7.0)",
];

function interpolate(value: number, rangeStart: number, max: number): number {
  const clamped = Math.min(Math.max(value - rangeStart, 0), 100);
  return (clamped / 100) * max;
}

function renderBenefit(benefit: ScalingBenefit, amount: number): string {
  const rendered = amount.toFixed(benefit.precision ?? 0);
  return benefit.template.replace("{v}", rendered);
}

/**
 * Computes the human-readable benefit lines for a stat at a target value,
 * e.g. computeBenefitsAt("Melee", 200) includes "+30% melee ability damage".
 * Enhanced benefits are omitted at or below 100.
 */
export function computeBenefitsAt(
  stat: ArmorStatName,
  value: number,
): string[] {
  const definition = STAT_BENEFITS[stat];
  const lines: string[] = [...definition.baseEffects];
  for (const benefit of definition.baseScaling) {
    lines.push(renderBenefit(benefit, interpolate(value, 0, benefit.max)));
  }
  if (value <= ENHANCED_THRESHOLD) return lines;
  for (const benefit of definition.enhancedScaling) {
    lines.push(renderBenefit(benefit, interpolate(value, 100, benefit.max)));
  }
  lines.push(...definition.enhancedNotes);
  return lines;
}
