/**
 * Activity and acquisition rules on the 9.7.0 baseline, transcribed from the
 * Update 9.7.0 patch notes (Activities, Rewards, Feats sections). Used for
 * deterministic guidance: where artifact perks apply, and where to farm the
 * gear a build recommends. Sources cached in `src/data/meta/sources/`.
 */

/** Artifacts 2.0 perks are disabled in these activities (9.7.0). */
export const ARTIFACT_DISABLED_ACTIVITIES: readonly string[] = [
  "Trials of Osiris",
  "Competitive Crucible",
];

export function isArtifactAllowed(activity: string): boolean {
  const normalized = activity.trim().toLowerCase();
  return !ARTIFACT_DISABLED_ACTIVITIES.some((blocked) =>
    normalized.includes(blocked.toLowerCase()),
  );
}

/** Ops difficulty -> performance grade -> fixed reward gear tier. */
export const DIFFICULTY_REWARD_TIERS: Record<string, number> = {
  Expert: 3,
  Master: 4,
  Grandmaster: 5,
  Ultimate: 5,
};

export const FEAT_GRADE_REWARDS: Record<number, string> = {
  0: "1x Tier 3",
  1: "1x Tier 3 + 1x Tier 4",
  2: "1x Tier 4 + 1x Tier 5",
  3: "2x Tier 5",
  4: "1x Tier 4 + 2x Tier 5",
  5: "3x Tier 5",
};

export interface AcquisitionRoute {
  source: string;
  rewards: string;
}

/** Preferred farming routes for build recommendations (9.7.0 economy). */
export const ACQUISITION_ROUTES: readonly AcquisitionRoute[] = [
  {
    source: "Featured raid (Standard)",
    rewards: "Deepsight weapons or Tier 5 armor from encounters and challenges; farmable",
  },
  {
    source: "Featured raid (Master)",
    rewards: "Standard rewards plus Adept weapons from challenges; vendor Adepts for 25 Spoils",
  },
  {
    source: "Featured dungeon (any difficulty)",
    rewards: "Tier 5 weapons and armor",
  },
  {
    source: "Non-featured raid/dungeon (Standard)",
    rewards: "Tier 3 armor (raids: chance at Deepsight weapons)",
  },
  {
    source: "Non-featured raid/dungeon (Master)",
    rewards: "Tier 5 weapons and armor (raids: plus Deepsight weapons)",
  },
  {
    source: "Feat farming (encounter completions)",
    rewards: "Guaranteed tiered drops by Feat grade, up to 3x Tier 5 at Grade 5",
  },
  {
    source: "Hawthorne raid focusing",
    rewards: "Armor 2.0 raid sets (the only gear with raid mod slots), high stats, 10 Spoils of Conquest per piece",
  },
  {
    source: "Iron Banner focusing",
    rewards: "Iron Banner gear focusable with IB Ciphers",
  },
  {
    source: "Public events",
    rewards: "Base: Tier 3 (chance at 4-5); Heroic: Tier 4 (chance at 5); +1 tier during Distortions",
  },
  {
    source: "Crafting / raid Adepts",
    rewards: "Crafted weapons and raid Adepts with Reshape reach Gear Tier 5 (9.7.0)",
  },
];

export const ACTIVITY_SYSTEM_NOTES: readonly string[] = [
  "Matchmade Portal difficulties span Expert to Grandmaster (Ultimate is fireteam-only); all require Power 300",
  "Exotic mission rotator removed; those exotics moved to Pinnacle Ops",
  "Legendary primaries deal +30% vs minors, exotic primaries +40% (9.7.0)",
];
