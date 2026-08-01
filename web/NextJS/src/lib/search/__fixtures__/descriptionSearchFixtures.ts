import type { OriginTraitRecord, PerkRecord, SetBonusRecord } from "@/lib/manifest/types/records";

/** Perk matched only via description text (name has no "melee"). */
export const FIXTURE_PERK_MELEE_DESCRIPTION: PerkRecord = {
  hash: 5101,
  name: "Adaptive Munitions",
  searchName: "adaptive munitions",
  icon: null,
  description: "Melee final blows grant bonus melee damage.",
};

export const FIXTURE_ORIGIN_MELEE_DESCRIPTION: OriginTraitRecord = {
  hash: 6101,
  name: "Silent Motive",
  searchName: "silent motive",
  icon: null,
  description: "Melee attacks reload this weapon.",
};

export const FIXTURE_SET_TIER_DESCRIPTION: SetBonusRecord = {
  hash: 8101,
  name: "Osmium Council",
  searchName: "osmium council",
  icon: null,
  perks: [
    { requiredCount: 2, name: "Council's Edge", description: "Overshield on arc melee." },
    { requiredCount: 4, name: "Final Verdict", description: "Super energy on defeat." },
  ],
  itemHashes: [9101],
};
