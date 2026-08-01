import type { SavedLoadout } from "@/lib/db/types";

import { classifyLoadoutExotics, type ManifestExoticStores } from "./classifyExotics";
import { filterLoadouts, matchesExoticFilter } from "./filterLoadouts";
import { hasActiveFilter } from "./parseFilterQuery";
import type { ExoticFilterCriteria, LoadoutListRow, LoadoutExoticSummary } from "./types";

function rowToSummary(row: LoadoutListRow): LoadoutExoticSummary {
  return {
    loadoutId: row.id,
    className: row.className ?? "Titan",
    exoticArmor: row.exoticSummary.exoticArmor,
    exoticWeapon: row.exoticSummary.exoticWeapon,
  };
}

export function filterLoadoutRows(
  rows: LoadoutListRow[],
  criteria: ExoticFilterCriteria,
): LoadoutListRow[] {
  if (!hasActiveFilter(criteria)) return rows;
  return rows.filter((row) => matchesExoticFilter(rowToSummary(row), criteria));
}

export function toLoadoutListRow(loadout: SavedLoadout, manifest?: ManifestExoticStores): LoadoutListRow {
  const summary = classifyLoadoutExotics(loadout, manifest);
  const { loadoutId, ...exoticSummary } = summary;
  void loadoutId;
  return {
    id: loadout.id,
    name: loadout.name,
    source: loadout.source,
    className: summary.className,
    createdAt: loadout.createdAt,
    updatedAt: loadout.updatedAt,
    manifestVersion: loadout.manifestVersion,
    exoticSummary,
  };
}

export function buildFilteredLoadoutList(
  loadouts: SavedLoadout[],
  criteria: ExoticFilterCriteria,
  manifest?: ManifestExoticStores,
): { loadouts: LoadoutListRow[]; filter: { applied: boolean; criteria?: ExoticFilterCriteria } } {
  const summaries = new Map(
    loadouts.map((l) => [l.id, classifyLoadoutExotics(l, manifest)]),
  );
  const filtered = hasActiveFilter(criteria)
    ? filterLoadouts(loadouts, criteria, summaries)
    : loadouts;

  return {
    loadouts: filtered.map((l) => toLoadoutListRow(l, manifest)),
    filter: hasActiveFilter(criteria)
      ? { applied: true, criteria }
      : { applied: false },
  };
}

export function buildDiscoveryMatches(
  rows: LoadoutListRow[],
  criteria: ExoticFilterCriteria,
  excludeLoadoutId?: string,
): LoadoutListRow[] {
  const summaries = new Map(
    rows.map((row) => [
      row.id,
      {
        loadoutId: row.id,
        className: row.className ?? "Titan",
        exoticArmor: row.exoticSummary.exoticArmor,
        exoticWeapon: row.exoticSummary.exoticWeapon,
      },
    ]),
  );

  const pseudoLoadouts = rows.map(
    (row) =>
      ({
        id: row.id,
        name: row.name,
        source: row.source as SavedLoadout["source"],
        manifestVersion: row.manifestVersion,
        generatedBuild: {} as SavedLoadout["generatedBuild"],
        resolvedSheet: {} as SavedLoadout["resolvedSheet"],
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      }) satisfies SavedLoadout,
  );

  return filterLoadouts(pseudoLoadouts, criteria, summaries)
    .map((l) => rows.find((r) => r.id === l.id)!)
    .filter((row) => row.id !== excludeLoadoutId);
}
