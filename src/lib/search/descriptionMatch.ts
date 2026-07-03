export type DescriptionMatchField = "name" | "description" | "other";

export type DescriptionSearchFields = {
  name?: string;
  searchName?: string;
  description?: string;
  otherTexts?: string[];
};

export type DescriptionMatchResult = {
  matched: boolean;
  matchField: DescriptionMatchField | null;
};

const MATCH_FIELD_RANK: Record<DescriptionMatchField, number> = {
  name: 0,
  description: 1,
  other: 2,
};

export function normalizeSearchQuery(query: string): string {
  return query.trim().toLowerCase();
}

function includesQuery(text: string | undefined, q: string): boolean {
  if (!text || !q) return false;
  return text.toLowerCase().includes(q);
}

export function matchDescriptionQuery(
  query: string,
  fields: DescriptionSearchFields,
): DescriptionMatchResult {
  const q = normalizeSearchQuery(query);
  if (!q) return { matched: true, matchField: null };

  if (
    includesQuery(fields.name, q) ||
    includesQuery(fields.searchName, q)
  ) {
    return { matched: true, matchField: "name" };
  }

  if (includesQuery(fields.description, q)) {
    return { matched: true, matchField: "description" };
  }

  for (const other of fields.otherTexts ?? []) {
    if (includesQuery(other, q)) {
      return { matched: true, matchField: "other" };
    }
  }

  return { matched: false, matchField: null };
}

export function compareMatchRank(
  a: DescriptionMatchField | null,
  b: DescriptionMatchField | null,
): number {
  if (a === b) return 0;
  if (a === null) return 1;
  if (b === null) return -1;
  return MATCH_FIELD_RANK[a] - MATCH_FIELD_RANK[b];
}

export function matchByNameOrDescription<
  T extends { name: string; searchName?: string; description?: string },
>(query: string, records: T[]): T[] {
  return records.filter((record) =>
    matchDescriptionQuery(query, {
      name: record.name,
      searchName: record.searchName,
      description: record.description,
    }).matched,
  );
}

export function sortByMatchRankThenName<T extends { name: string }>(
  items: Array<{ item: T; matchField: DescriptionMatchField | null }>,
): T[] {
  return [...items]
    .sort((a, b) => {
      const rank = compareMatchRank(a.matchField, b.matchField);
      if (rank !== 0) return rank;
      return a.item.name.localeCompare(b.item.name);
    })
    .map((entry) => entry.item);
}
