import type { SetBonusRecord } from "@/lib/manifest/types/records";

export type SetBonusFilterResolution =
  | { ok: true; sets: SetBonusRecord[]; armorHashes: Set<number> }
  | { ok: false };

function parseNumericHash(value: string): number | null {
  const trimmed = value.trim();
  if (!/^\d+$/.test(trimmed)) return null;
  const hash = Number(trimmed);
  return Number.isFinite(hash) && hash > 0 ? hash : null;
}

export function resolveSetBonusFilter(
  setBonus: string,
  sets: SetBonusRecord[],
): SetBonusFilterResolution {
  const numeric = parseNumericHash(setBonus);
  const matched =
    numeric !== null
      ? sets.filter((set) => set.hash === numeric)
      : sets.filter((set) => {
          const q = setBonus.trim().toLowerCase();
          return set.searchName.includes(q) || set.name.toLowerCase().includes(q);
        });

  if (matched.length === 0) return { ok: false };

  const armorHashes = new Set<number>();
  for (const set of matched) {
    for (const hash of set.itemHashes) armorHashes.add(hash);
  }

  return { ok: true, sets: matched, armorHashes };
}
