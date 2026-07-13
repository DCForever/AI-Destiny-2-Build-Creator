import type { SetType } from "@/lib/sets/schemas";

export type FilterableSet = {
  id: string;
  name: string;
  type: string;
  tagIds?: string[];
};

export type SetListFilters = {
  query?: string;
  types?: string[];
  tags?: string[];
};

/** Client-side filter for production Sets library rows. */
export function filterSets<T extends FilterableSet>(
  sets: T[],
  filters: SetListFilters,
): T[] {
  const q = filters.query?.trim().toLowerCase() ?? "";
  const types = filters.types ?? [];
  const tags = filters.tags ?? [];

  return sets.filter((set) => {
    if (types.length > 0 && !types.includes(set.type)) return false;
    if (tags.length > 0) {
      const setTags = set.tagIds ?? [];
      if (!tags.every((t) => setTags.includes(t))) return false;
    }
    if (!q) return true;
    const hay = `${set.name} ${set.type} ${(set.tagIds ?? []).join(" ")}`.toLowerCase();
    return hay.includes(q);
  });
}

export function isSetType(value: string): value is SetType {
  return (
    value === "weapon" ||
    value === "armor" ||
    value === "mod" ||
    value === "pair" ||
    value === "fashion"
  );
}
