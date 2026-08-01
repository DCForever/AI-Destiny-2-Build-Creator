/** Pure column labels for weapon perk grids (client-safe). */

const COLUMN_LABELS = ["Barrel", "Magazine", "Trait 1", "Trait 2", "Trait 3", "Trait 4"];

export function columnIndexToLabel(column: number): string {
  if (column < 0) return "Intrinsic";
  if (column < COLUMN_LABELS.length) return COLUMN_LABELS[column] ?? `Trait ${column - 1}`;
  return `Trait ${column - 1}`;
}
