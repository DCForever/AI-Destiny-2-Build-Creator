/**
 * Canonical name normalization shared by extractors (when writing
 * `searchName`) and the resolver (when matching user/LLM-provided names).
 * Must stay in sync on both sides, hence a single implementation.
 */
export function normalizeName(name: string): string {
  return name
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/['’\u2018\u2019]/g, "")
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
}
