import type { SetBonusRecord } from "@/lib/manifest/types/records";
import { matchDescriptionQuery } from "@/lib/search/descriptionMatch";

export type SetBonusFilterResolution =
  | { ok: true; sets: SetBonusRecord[]; armorHashes: Set<number> }
  | { ok: false };

function parseNumericHash(value: string): number | null {
  const trimmed = value.trim();
  if (!/^\d+$/.test(trimmed)) return null;
  const hash = Number(trimmed);
  return Number.isFinite(hash) && hash > 0 ? hash : null;
}

function setMatchesQuery(set: SetBonusRecord, query: string): boolean {
  if (
    matchDescriptionQuery(query, {
      name: set.name,
      searchName: set.searchName,
    }).matched
  ) {
    return true;
  }

  for (const perk of set.perks) {
    if (
      matchDescriptionQuery(query, {
        name: perk.name,
        description: perk.description,
      }).matched
    ) {
      return true;
    }
  }

  return false;
}

export function resolveSetBonusFilter(
  setBonus: string,
  sets: SetBonusRecord[],
): SetBonusFilterResolution {
  const numeric = parseNumericHash(setBonus);
  const matched =
    numeric !== null
      ? sets.filter((set) => set.hash === numeric)
      : sets.filter((set) => setMatchesQuery(set, setBonus));

  if (matched.length === 0) return { ok: false };

  const armorHashes = new Set<number>();
  for (const set of matched) {
    for (const hash of set.itemHashes) armorHashes.add(hash);
  }

  return { ok: true, sets: matched, armorHashes };
}
