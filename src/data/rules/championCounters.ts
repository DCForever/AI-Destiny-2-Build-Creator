/**
 * Anti-Champion 2.0 rule tables, transcribed from the official Update 9.7.0
 * patch notes ("Weapons > Anti-Champion 2.0") and the Abilities & Armor Dev
 * Insight. Sources cached in `src/data/meta/sources/`.
 *
 * Champion mods no longer exist; every weapon stuns champions intrinsically
 * based on its frame, activated by simply hitting the target.
 */

export type ChampionType = "Barrier" | "Overload" | "Unstoppable";

/** Base mapping by weapon-type family (patch notes table 1). */
export const BASE_FRAME_COUNTERS: Record<string, ChampionType> = {
  aggressive: "Unstoppable",
  "high-impact": "Unstoppable",
  precision: "Barrier",
  adaptive: "Barrier",
  lightweight: "Overload",
  "rapid-fire": "Overload",
};

export interface FrameOverrideRule {
  /** Normalized frame-name prefix as it appears in the manifest intrinsic. */
  frame: string;
  /** Manifest weapon type display name; null = applies to any weapon type. */
  weaponType: string | null;
  counters: ChampionType;
}

/** Frame-specific overrides (patch notes table 2), checked before the base map. */
export const FRAME_OVERRIDES: readonly FrameOverrideRule[] = [
  { frame: "support", weaponType: "Auto Rifle", counters: "Overload" },
  { frame: "adaptive burst", weaponType: "Linear Fusion Rifle", counters: "Barrier" },
  { frame: "area denial", weaponType: "Grenade Launcher", counters: "Overload" },
  { frame: "double fire", weaponType: "Grenade Launcher", counters: "Unstoppable" },
  { frame: "micro-missile", weaponType: "Grenade Launcher", counters: "Unstoppable" },
  { frame: "wave", weaponType: "Grenade Launcher", counters: "Unstoppable" },
  { frame: "compressed wave", weaponType: "Grenade Launcher", counters: "Unstoppable" },
  { frame: "heavy burst", weaponType: "Hand Cannon", counters: "Unstoppable" },
  { frame: "spread shot", weaponType: "Hand Cannon", counters: "Overload" },
  { frame: "aggressive burst", weaponType: "Submachine Gun", counters: "Unstoppable" },
  { frame: "aggressive burst", weaponType: "Pulse Rifle", counters: "Unstoppable" },
  { frame: "heavy burst", weaponType: "Pulse Rifle", counters: "Unstoppable" },
  { frame: "legacy pr-55", weaponType: "Pulse Rifle", counters: "Barrier" },
  { frame: "rocket-assisted", weaponType: "Pulse Rifle", counters: "Unstoppable" },
  { frame: "rocket-assisted", weaponType: "Sidearm", counters: "Unstoppable" },
  { frame: "disruption", weaponType: "Sniper Rifle", counters: "Barrier" },
  { frame: "caster", weaponType: "Sword", counters: "Barrier" },
  { frame: "vortex", weaponType: "Sword", counters: "Overload" },
  { frame: "wave", weaponType: "Sword", counters: "Unstoppable" },
  { frame: "dynamic heat", weaponType: null, counters: "Overload" },
  { frame: "balanced heat", weaponType: null, counters: "Overload" },
];

/**
 * Subclass-verb champion counters on the 9.7.0 baseline. Notable corrections:
 * Stasis shatter damage stuns Unstoppable again (reverted; includes the new
 * Shatter Grenade), and Radiant / Volatile Rounds NO LONGER pierce Barriers
 * (see CHAMPION_DAMAGE_BUFFS).
 */
export const SUBCLASS_VERB_COUNTERS: Record<string, ChampionType> = {
  blind: "Unstoppable",
  suspend: "Unstoppable",
  ignition: "Unstoppable",
  shatter: "Unstoppable",
  jolt: "Overload",
  suppression: "Overload",
  slow: "Overload",
};

/**
 * Status effects that buff champion damage instead of stunning (9.7.0 change:
 * "weapon archetypes now govern weapon-based Champion stuns").
 */
export const CHAMPION_DAMAGE_BUFFS: Record<string, { bonusPercent: number }> = {
  radiant: { bonusPercent: 10 },
  "volatile rounds": { bonusPercent: 10 },
};

function normalizeFrameName(frame: string): string {
  return frame
    .toLowerCase()
    .replace(/\s+frame\s*$/, "")
    .trim();
}

function matchOverride(
  normalizedFrame: string,
  weaponType: string,
): ChampionType | null {
  for (const rule of FRAME_OVERRIDES) {
    const frameMatches = normalizedFrame.startsWith(rule.frame);
    const typeMatches = rule.weaponType === null || rule.weaponType === weaponType;
    if (frameMatches && typeMatches) return rule.counters;
  }
  return null;
}

/**
 * Resolves a weapon's intrinsic champion counter from its frame name (manifest
 * intrinsic display name, e.g. "Adaptive Frame") and weapon type display name
 * (e.g. "Pulse Rifle"). Returns null when the frame has no counter (e.g.
 * exotic-specific intrinsics not in either table).
 */
export function getChampionCounterForFrame(
  frameName: string,
  weaponTypeName: string,
): ChampionType | null {
  if (!frameName) return null;
  const normalized = normalizeFrameName(frameName);
  const override = matchOverride(normalized, weaponTypeName);
  if (override) return override;
  const baseFamily = Object.keys(BASE_FRAME_COUNTERS).find((family) =>
    normalized.startsWith(family),
  );
  return baseFamily ? BASE_FRAME_COUNTERS[baseFamily] : null;
}
