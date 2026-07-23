import type { CatalogItem } from "@/lib/catalog/types";

/**
 * DIM-informed facet: free-text is separate; multi-value chips support
 * include (OR within) and exclude (any match drops), combined across facets with AND.
 *
 * DIM uses `-filter:` / `not` for negation; we expose the same semantics on chips
 * without adopting the full query language.
 */
export type FacetFilter = {
  include: string[];
  exclude: string[];
};

export type CatalogClientFilters = {
  query?: string;
  /** @deprecated Prefer slots facet; single slot treated as include. */
  slot?: string | null;
  slots?: FacetFilter | string[];
  elements?: FacetFilter | string[];
  ammos?: FacetFilter | string[];
  /** Weapon itemTypeName or armor frame. */
  archetypes?: FacetFilter | string[];
  /** Class as facet (include/exclude) or legacy single include string. */
  classNames?: FacetFilter | string[];
  className?: string | null;
  /**
   * Exotic: true = include only exotic; false = exclude exotic;
   * undefined/null = no exotic constraint. Legacy onlyExotic maps to true.
   */
  exotic?: boolean | null;
  onlyExotic?: boolean;
  /**
   * Synergy ids on the item (optional). When set, include/exclude act on
   * intersection with item.linkedSynergyIds (or empty).
   */
  synergies?: FacetFilter;
  /**
   * Hash-level synergy membership (Catalog pipeline): item hash must be in
   * the include union (if non-empty) and not in the exclude union.
   */
  itemHashesInclude?: number[] | Set<number>;
  itemHashesExclude?: number[] | Set<number>;
};

export function emptyFacet(): FacetFilter {
  return { include: [], exclude: [] };
}

export function isFacetEmpty(f: FacetFilter | undefined): boolean {
  if (!f) return true;
  return f.include.length === 0 && f.exclude.length === 0;
}

export function normalizeFacet(
  value: FacetFilter | string[] | undefined,
): FacetFilter {
  if (!value) return emptyFacet();
  if (Array.isArray(value)) {
    return { include: [...value], exclude: [] };
  }
  return {
    include: [...(value.include ?? [])],
    exclude: [...(value.exclude ?? [])],
  };
}

/** Cycle chip: off → include → exclude → off (DIM-like include vs not). */
export function cycleFacetValue(facet: FacetFilter, value: string): FacetFilter {
  const inInc = facet.include.includes(value);
  const inExc = facet.exclude.includes(value);
  if (!inInc && !inExc) {
    return {
      include: [...facet.include, value],
      exclude: facet.exclude,
    };
  }
  if (inInc) {
    return {
      include: facet.include.filter((v) => v !== value),
      exclude: [...facet.exclude, value],
    };
  }
  return {
    include: facet.include,
    exclude: facet.exclude.filter((v) => v !== value),
  };
}

export type FacetChipState = "off" | "include" | "exclude";

export function facetChipState(
  facet: FacetFilter,
  value: string,
): FacetChipState {
  if (facet.include.includes(value)) return "include";
  if (facet.exclude.includes(value)) return "exclude";
  return "off";
}

/**
 * Pure facet predicate (DIM: within OR for positive terms; NOT drops matches).
 */
export function matchesFacet(
  facet: FacetFilter | undefined,
  value: string | null | undefined,
): boolean {
  const f = normalizeFacet(facet);
  if (isFacetEmpty(f)) return true;
  const v = value?.trim() ?? "";
  if (v && f.exclude.includes(v)) return false;
  if (f.include.length === 0) return true;
  if (!v) return false;
  return f.include.includes(v);
}

function matchesArchetypeFacet(
  facet: FacetFilter | undefined,
  item: CatalogItem,
): boolean {
  const f = normalizeFacet(facet);
  if (isFacetEmpty(f)) return true;

  const candidates = [item.itemTypeName, item.frame]
    .filter((x): x is string => Boolean(x?.trim()))
    .flatMap((raw) => {
      const t = raw.trim();
      const bare = t.replace(/\s*Frame$/i, "").trim();
      return bare && bare !== t ? [t, bare] : [t];
    });

  for (const c of candidates) {
    if (f.exclude.some((ex) => c === ex || c.includes(ex) || ex.includes(c))) {
      return false;
    }
  }
  if (f.include.length === 0) return true;
  return f.include.some((inc) =>
    candidates.some(
      (c) => c === inc || c.includes(inc) || inc.includes(c),
    ),
  );
}

function matchesSynergyIds(
  facet: FacetFilter | undefined,
  linked: string[] | undefined,
): boolean {
  const f = normalizeFacet(facet);
  if (isFacetEmpty(f)) return true;
  const set = new Set(linked ?? []);
  for (const id of f.exclude) {
    if (set.has(id)) return false;
  }
  if (f.include.length === 0) return true;
  return f.include.some((id) => set.has(id));
}

function inHashSet(
  set: number[] | Set<number> | undefined,
  hash: number,
): boolean {
  if (!set) return false;
  if (set instanceof Set) return set.has(hash);
  return set.includes(hash);
}

/**
 * Live client-side narrowing of a base catalog fetch.
 * Across facets: AND. Within include: OR. Any exclude match: drop.
 */
export function filterCatalogClient(
  items: CatalogItem[],
  filters: CatalogClientFilters,
): CatalogItem[] {
  const q = filters.query?.trim().toLowerCase() ?? "";

  const elements = normalizeFacet(filters.elements);
  const ammos = normalizeFacet(filters.ammos);
  const archetypes = normalizeFacet(filters.archetypes);

  const slots = normalizeFacet(
    filters.slots ??
      (filters.slot ? { include: [filters.slot], exclude: [] } : undefined),
  );

  const classNames = normalizeFacet(
    filters.classNames ??
      (filters.className
        ? { include: [filters.className], exclude: [] }
        : undefined),
  );

  const exotic =
    filters.exotic !== undefined
      ? filters.exotic
      : filters.onlyExotic === true
        ? true
        : null;

  const synergies = normalizeFacet(filters.synergies);
  const includeHashes = filters.itemHashesInclude;
  const excludeHashes = filters.itemHashesExclude;
  const hasIncludeHashes =
    includeHashes instanceof Set
      ? includeHashes.size > 0
      : (includeHashes?.length ?? 0) > 0;
  const hasExcludeHashes =
    excludeHashes instanceof Set
      ? excludeHashes.size > 0
      : (excludeHashes?.length ?? 0) > 0;

  return items.filter((item) => {
    if (exotic === true && !item.isExotic) return false;
    if (exotic === false && item.isExotic) return false;

    if (!matchesFacet(slots, item.slot ?? null)) return false;
    if (!matchesFacet(elements, item.element ?? null)) return false;
    if (!matchesFacet(ammos, item.ammo ?? null)) return false;
    if (!matchesFacet(classNames, item.classType ?? null)) return false;
    if (!matchesArchetypeFacet(archetypes, item)) return false;

    const linked = (item as CatalogItem & { linkedSynergyIds?: string[] })
      .linkedSynergyIds;
    if (!matchesSynergyIds(synergies, linked)) return false;

    if (hasIncludeHashes && !inHashSet(includeHashes, item.hash)) return false;
    if (hasExcludeHashes && inHashSet(excludeHashes, item.hash)) return false;

    if (!q) return true;
    const hay = [
      item.name,
      item.slot,
      item.element,
      item.ammo,
      item.itemTypeName,
      item.frame,
      item.classType,
      item.setBonusName,
      item.description,
    ]
      .filter(Boolean)
      .join(" ")
      .toLowerCase();
    return hay.includes(q);
  });
}

export function facetActiveCount(f: FacetFilter): number {
  return f.include.length + f.exclude.length;
}
