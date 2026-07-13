export type FilterableSynergy = {
  id: string;
  name: string;
  type: string;
  subType?: string | null;
};

export type SynergyListFilters = {
  query?: string;
  types?: string[];
  subTypes?: string[];
};

/**
 * Client-side library filter for production Synergy list.
 * Type + subtype multi-selects AND together with free-text search.
 */
export function filterSynergies<T extends FilterableSynergy>(
  rows: T[],
  filters: SynergyListFilters,
): T[] {
  const q = filters.query?.trim().toLowerCase() ?? "";
  const types = filters.types ?? [];
  const subTypes = filters.subTypes ?? [];

  return rows.filter((row) => {
    if (types.length > 0 && !types.includes(row.type)) return false;
    if (subTypes.length > 0) {
      const sub = row.subType?.trim() ?? "";
      if (!sub || !subTypes.includes(sub)) return false;
    }
    if (!q) return true;
    const hay = `${row.name} ${row.type} ${row.subType ?? ""}`.toLowerCase();
    return hay.includes(q);
  });
}
