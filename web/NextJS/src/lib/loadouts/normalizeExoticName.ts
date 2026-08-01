/** Case/diacritic-insensitive exotic name comparison (FR-008 name fallback). */
export function normalizeExoticName(name: string): string {
  return name
    .normalize("NFD")
    .replace(/\p{M}/gu, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, " ")
    .trim()
    .replace(/\s+/g, " ");
}

export function exoticNamesMatch(a: string, b: string): boolean {
  return normalizeExoticName(a) === normalizeExoticName(b);
}
