import type { BuildSummary, GuardianClass } from "@/components/build/types";
import { compareDisplayName } from "@/lib/sortByName";

/** Stable filter key for a build's exotic armor identity. */
export type ExoticArmorFilterKey = string;

export const EXOTIC_ARMOR_NONE_KEY = "none" as const;

export type ExoticArmorFilterOption = {
  key: ExoticArmorFilterKey;
  label: string;
  hash: number | null;
};

export type BuildLibraryFilters = {
  className?: GuardianClass | null;
  /** Multi-select; empty/undefined = no exotic constraint. OR within selection. */
  exoticArmorKeys?: ExoticArmorFilterKey[];
};

/**
 * Stable key for exotic-armor filter matching.
 * Prefer hash; fall back to normalized name; builds without armor use "none".
 */
export function exoticArmorFilterKey(
  build: Pick<BuildSummary, "exoticArmorHash" | "exoticArmorName">,
): ExoticArmorFilterKey {
  if (build.exoticArmorHash != null && Number.isFinite(build.exoticArmorHash)) {
    return `h:${build.exoticArmorHash}`;
  }
  const name = build.exoticArmorName?.trim();
  if (name) return `n:${name.toLowerCase()}`;
  return EXOTIC_ARMOR_NONE_KEY;
}

export function exoticArmorFilterLabel(
  build: Pick<BuildSummary, "exoticArmorHash" | "exoticArmorName">,
): string {
  const name = build.exoticArmorName?.trim();
  if (name) return name;
  if (build.exoticArmorHash != null) return `Exotic ${build.exoticArmorHash}`;
  return "No exotic";
}

/** Unique exotic armor options present in the given builds (sorted by label). */
export function collectExoticArmorOptions(
  builds: ReadonlyArray<
    Pick<BuildSummary, "exoticArmorHash" | "exoticArmorName">
  >,
): ExoticArmorFilterOption[] {
  const byKey = new Map<ExoticArmorFilterKey, ExoticArmorFilterOption>();
  for (const b of builds) {
    const key = exoticArmorFilterKey(b);
    if (byKey.has(key)) continue;
    byKey.set(key, {
      key,
      label: exoticArmorFilterLabel(b),
      hash: b.exoticArmorHash ?? null,
    });
  }
  return [...byKey.values()].sort((a, b) => {
    // Keep "No exotic" last when present
    if (a.key === EXOTIC_ARMOR_NONE_KEY) return 1;
    if (b.key === EXOTIC_ARMOR_NONE_KEY) return -1;
    return compareDisplayName(a.label, b.label);
  });
}

/** Client-side library filter: class AND (exotic multi-select OR). */
export function filterBuilds(
  builds: readonly BuildSummary[],
  filters: BuildLibraryFilters,
): BuildSummary[] {
  const className = filters.className ?? null;
  const exoticKeys = filters.exoticArmorKeys ?? [];
  const exoticSet =
    exoticKeys.length > 0 ? new Set(exoticKeys) : null;

  return builds.filter((b) => {
    if (className && b.className !== className) return false;
    if (exoticSet) {
      if (!exoticSet.has(exoticArmorFilterKey(b))) return false;
    }
    return true;
  });
}
