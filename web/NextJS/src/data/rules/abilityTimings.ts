/**
 * Fallback cooldown/duration hints for subclass abilities when manifest
 * descriptions lack parseable timing patterns. Values are approximate 9.7.0
 * baselines; manifest text takes precedence when regex parsing succeeds.
 */

export interface AbilityTiming {
  cooldownSeconds?: number;
  durationSeconds?: number;
  charges?: number;
}

/** Normalized ability display name → timing fallback. */
export const ABILITY_TIMING_FALLBACKS: Record<string, AbilityTiming> = {
  "Stormtrance": { cooldownSeconds: 300, durationSeconds: 22 },
  "Healing Rift": { cooldownSeconds: 38, durationSeconds: 12 },
  "Burst Glide": { cooldownSeconds: 4 },
  "Ball Lightning": { cooldownSeconds: 32 },
  "Shackle Grenade": { cooldownSeconds: 105 },
  "Hammer of Sol": { cooldownSeconds: 300, durationSeconds: 20 },
  "Sentinel Shield": { cooldownSeconds: 300, durationSeconds: 15 },
  "Glacial Quake": { cooldownSeconds: 300, durationSeconds: 10 },
  "Fist of Havoc": { cooldownSeconds: 300 },
  "Blade Barrage": { cooldownSeconds: 300 },
  "Golden Gun": { cooldownSeconds: 300, charges: 2 },
  "Arc Staff": { cooldownSeconds: 300, durationSeconds: 25 },
  "Silence and Squall": { cooldownSeconds: 300, durationSeconds: 18 },
  "Shadowshot": { cooldownSeconds: 300 },
  "Silkstrike": { cooldownSeconds: 300, durationSeconds: 20 },
  "Daybreak": { cooldownSeconds: 300, durationSeconds: 25 },
  "Chaos Reach": { cooldownSeconds: 300, durationSeconds: 5 },
  "Winter's Wrath": { cooldownSeconds: 300, durationSeconds: 10 },
  "Nova Bomb": { cooldownSeconds: 300 },
  "Needlestorm": { cooldownSeconds: 300, durationSeconds: 18 },
};

const COOLDOWN_PATTERN = /(\d+(?:\.\d+)?)\s*(?:s|sec(?:ond)?s?)\s+cooldown/i;
const DURATION_PATTERN = /(\d+(?:\.\d+)?)\s*(?:s|sec(?:ond)?s?)\s+duration/i;
const CHARGE_PATTERN = /(\d+)\s+charge/i;

export function parseAbilityTiming(description: string, abilityName?: string): AbilityTiming {
  const parsed: AbilityTiming = {};
  const cooldown = description.match(COOLDOWN_PATTERN);
  const duration = description.match(DURATION_PATTERN);
  const charges = description.match(CHARGE_PATTERN);
  if (cooldown) parsed.cooldownSeconds = Number(cooldown[1]);
  if (duration) parsed.durationSeconds = Number(duration[1]);
  if (charges) parsed.charges = Number(charges[1]);

  if (abilityName && Object.keys(parsed).length === 0) {
    return ABILITY_TIMING_FALLBACKS[abilityName] ?? {};
  }
  if (abilityName) {
    const fallback = ABILITY_TIMING_FALLBACKS[abilityName];
    return {
      cooldownSeconds: parsed.cooldownSeconds ?? fallback?.cooldownSeconds,
      durationSeconds: parsed.durationSeconds ?? fallback?.durationSeconds,
      charges: parsed.charges ?? fallback?.charges,
    };
  }
  return parsed;
}

export function formatAbilityTiming(timing: AbilityTiming): string | null {
  const parts: string[] = [];
  if (timing.cooldownSeconds !== undefined) parts.push(`${timing.cooldownSeconds}s cooldown`);
  if (timing.durationSeconds !== undefined) parts.push(`${timing.durationSeconds}s duration`);
  if (timing.charges !== undefined) parts.push(`${timing.charges} charges`);
  return parts.length > 0 ? parts.join(" · ") : null;
}
