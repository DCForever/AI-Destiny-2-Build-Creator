import type { SetBonusCoverageGoal } from "@/lib/optimizer/types";

export type SetBonusCatalogEntry = {
  /** Optimizer / goal key (preferred stable id). */
  setBonusKey: string;
  label: string;
  armorSetHash?: number;
  armorSetName?: string;
};

export type RankedSetBonusOption = {
  setBonusKey: string;
  label: string;
  minPieces?: 2 | 4;
  linked: boolean;
  synergyNames: string[];
  armorSetHash?: number;
  armorSetName?: string;
};

export type RankSetBonusesResult = {
  linked: RankedSetBonusOption[];
  /** Full catalog (or remainder) excluding pure duplicates of linked keys when preferUniqueAll. */
  all: RankedSetBonusOption[];
};

function linkKey(link: {
  armorSetHash?: number | null;
  armorSetName?: string | null;
  bonusName?: string | null;
}): string | null {
  if (link.armorSetHash != null && Number.isFinite(link.armorSetHash)) {
    return `hash:${link.armorSetHash}`;
  }
  const name = (link.armorSetName ?? link.bonusName ?? "").trim();
  if (name) return `name:${name.toLowerCase()}`;
  return null;
}

function catalogKey(entry: SetBonusCatalogEntry): string {
  if (entry.armorSetHash != null && Number.isFinite(entry.armorSetHash)) {
    return `hash:${entry.armorSetHash}`;
  }
  return `name:${(entry.armorSetName ?? entry.label ?? entry.setBonusKey).toLowerCase()}`;
}

/** Minimal link shape for ranking (avoids full SynergyLinkRecord). */
export type RankSetBonusLink = {
  kind: string;
  displayName?: string;
  armorSetHash?: number | null;
  armorSetName?: string | null;
  bonusName?: string | null;
  bonusPieces?: 2 | 4 | null;
  itemHash?: number | null;
};

export type RankSetBonusSynergy = {
  name: string;
  links: RankSetBonusLink[];
};

/**
 * Rank set-bonus options for Finish goals: bonuses linked from designated/bridged
 * synergies (armor_set_bonus) first, then the rest of the catalog.
 */
export function rankSetBonusesForBuild(input: {
  matchedSynergies: RankSetBonusSynergy[];
  catalog: SetBonusCatalogEntry[];
}): RankSetBonusesResult {
  type Meta = {
    synergyNames: Set<string>;
    minPieces?: 2 | 4;
    label: string;
    hash?: number;
    name?: string;
  };
  const synergyByIdentity = new Map<string, Meta>();

  for (const synergy of input.matchedSynergies) {
    for (const link of synergy.links as RankSetBonusLink[]) {
      if (link.kind !== "armor_set_bonus") continue;
      const id = linkKey(link);
      if (!id) continue;
      const existing = synergyByIdentity.get(id);
      const row: Meta = existing ?? {
        synergyNames: new Set<string>(),
        label: (link.bonusName ?? link.armorSetName ?? id).trim(),
        ...(link.armorSetHash != null ? { hash: link.armorSetHash } : {}),
        ...(link.armorSetName ? { name: link.armorSetName } : {}),
      };
      if (!existing) synergyByIdentity.set(id, row);
      row.synergyNames.add(synergy.name);
      if (link.bonusPieces === 2 || link.bonusPieces === 4) {
        if (row.minPieces == null || link.bonusPieces > row.minPieces) {
          row.minPieces = link.bonusPieces;
        }
      }
      if (row.hash == null && link.armorSetHash != null) row.hash = link.armorSetHash;
      if (row.name == null && link.armorSetName) row.name = link.armorSetName;
    }
  }

  const linked: RankedSetBonusOption[] = [];
  const linkedKeys = new Set<string>();

  // Match catalog entries to link identities when possible for stable setBonusKey.
  const catalogByIdentity = new Map<string, SetBonusCatalogEntry>();
  for (const entry of input.catalog) {
    catalogByIdentity.set(catalogKey(entry), entry);
    catalogByIdentity.set(`key:${entry.setBonusKey}`, entry);
  }

  for (const [id, meta] of synergyByIdentity) {
    const cat =
      catalogByIdentity.get(id) ??
      (meta.hash != null ? catalogByIdentity.get(`hash:${meta.hash}`) : undefined) ??
      (meta.name ? catalogByIdentity.get(`name:${meta.name.toLowerCase()}`) : undefined);
    const setBonusKey = cat?.setBonusKey ?? (meta.hash != null ? String(meta.hash) : meta.name ?? id);
    linkedKeys.add(setBonusKey);
    linked.push({
      setBonusKey,
      label: cat?.label ?? meta.label,
      linked: true,
      synergyNames: [...meta.synergyNames].sort(),
      ...(meta.minPieces != null ? { minPieces: meta.minPieces } : { minPieces: 2 as const }),
      ...(meta.hash != null ? { armorSetHash: meta.hash } : {}),
      ...(meta.name ? { armorSetName: meta.name } : {}),
    });
  }

  linked.sort((a, b) => a.label.localeCompare(b.label));

  const all: RankedSetBonusOption[] = input.catalog.map((entry) => ({
    setBonusKey: entry.setBonusKey,
    label: entry.label,
    linked: linkedKeys.has(entry.setBonusKey),
    synergyNames: linked.find((l) => l.setBonusKey === entry.setBonusKey)?.synergyNames ?? [],
    ...(entry.armorSetHash != null ? { armorSetHash: entry.armorSetHash } : {}),
    ...(entry.armorSetName ? { armorSetName: entry.armorSetName } : {}),
  }));

  all.sort((a, b) => {
    if (a.linked !== b.linked) return a.linked ? -1 : 1;
    return a.label.localeCompare(b.label);
  });

  return { linked, all };
}

/** Map ranked options to optimizer setBonusGoals (dedupe last-wins by key). */
export function goalsFromRankedOptions(
  options: Array<Pick<RankedSetBonusOption, "setBonusKey" | "minPieces">>,
): SetBonusCoverageGoal[] {
  const map = new Map<string, SetBonusCoverageGoal>();
  for (const opt of options) {
    map.set(opt.setBonusKey, {
      setBonusKey: opt.setBonusKey,
      minPieces: opt.minPieces === 4 ? 4 : 2,
    });
  }
  return [...map.values()];
}
