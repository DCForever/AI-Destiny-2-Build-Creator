import type { SetBonusRecord } from "@/lib/manifest/types/records";

import type { ArmorSetBonusSummary } from "./types";

/**
 * Invert `SetBonusRecord.itemHashes` into a per-member lookup so an armor
 * instance can find its set bonus by `itemHash`. Built once per request from
 * the `set-bonuses` store and passed through the projection context.
 */
export function buildSetBonusByItemHash(
  records: SetBonusRecord[],
): Map<number, SetBonusRecord> {
  const byItemHash = new Map<number, SetBonusRecord>();
  for (const record of records) {
    for (const itemHash of record.itemHashes) {
      byItemHash.set(itemHash, record);
    }
  }
  return byItemHash;
}

export function lookupSetBonus(
  byItemHash: Map<number, SetBonusRecord>,
  itemHash: number,
): ArmorSetBonusSummary | null {
  const record = byItemHash.get(itemHash);
  if (!record) return null;
  return {
    hash: record.hash,
    name: record.name,
    tiers: record.perks.map((perk) => ({
      requiredCount: perk.requiredCount,
      name: perk.name,
      description: perk.description,
    })),
  };
}
