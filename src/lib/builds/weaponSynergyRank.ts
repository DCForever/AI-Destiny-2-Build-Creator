export type RankableWeapon = { hash: number; name: string };

export type RankedWeapon<T extends RankableWeapon = RankableWeapon> = T & {
  synergyMatch: boolean;
};

/** FR-015: synergy-linked weapons first; others remain reachable. */
export function rankWeaponsBySynergyMatch<T extends RankableWeapon>(
  items: readonly T[],
  matchingHashes: ReadonlySet<number>,
): RankedWeapon<T>[] {
  const matched: RankedWeapon<T>[] = [];
  const rest: RankedWeapon<T>[] = [];
  for (const item of items) {
    const synergyMatch = matchingHashes.has(item.hash);
    const row = { ...item, synergyMatch };
    if (synergyMatch) matched.push(row);
    else rest.push(row);
  }
  return [...matched, ...rest];
}
