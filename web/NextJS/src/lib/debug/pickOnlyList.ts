/** Pure helpers for pick-only multi-value lists (aspects/fragments). */

export function addPickedName(current: readonly string[], name: string): string[] {
  const trimmed = name.trim();
  if (!trimmed) return [...current];
  if (current.includes(trimmed)) return [...current];
  return [...current, trimmed];
}

export function removePickedName(current: readonly string[], name: string): string[] {
  return current.filter((item) => item !== name);
}

/** Free-typed text must never become the list — only explicit picks. */
export function ignoreFreeTextList(_typed: string, current: readonly string[]): string[] {
  return [...current];
}
