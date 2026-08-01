/**
 * Match an in-game loadout to curated builds by class + exotic identity.
 * Pure helper for Loadouts UI labeling and Build library badges.
 */

export type LoadoutMatchInput = {
  className?: string | null;
  exoticArmorHash?: number | null;
  exoticWeaponHash?: number | null;
};

export type BuildMatchInput = {
  id: string;
  name: string;
  className: string;
  exoticArmorHash?: number | null;
  exoticWeaponHash?: number | null;
};

/** Loadout row shape needed for reverse match (build → loadouts). */
export type InGameLoadoutMatchRow = LoadoutMatchInput & {
  id: string;
  name: string;
  iconUrl?: string | null;
  colorUrl?: string | null;
  className?: string | null;
};

export type LoadoutBuildMatchKind = "exact" | "partial" | "none";

export type LoadoutBuildMatch = {
  kind: LoadoutBuildMatchKind;
  builds: Array<{ id: string; name: string }>;
};

export type BuildLoadoutMatch = {
  kind: LoadoutBuildMatchKind;
  loadouts: InGameLoadoutMatchRow[];
};

function hashEq(
  a: number | null | undefined,
  b: number | null | undefined,
): boolean {
  if (a == null || b == null) return false;
  return a === b;
}

/**
 * Exact: same class and every exotic present on both sides matches.
 * Partial: same class and at least one exotic hash matches.
 * None: no class match or no exotic overlap.
 */
export function matchLoadoutToBuilds(
  loadout: LoadoutMatchInput,
  builds: BuildMatchInput[],
): LoadoutBuildMatch {
  const className = loadout.className?.trim();
  if (!className) {
    return { kind: "none", builds: [] };
  }

  const sameClass = builds.filter(
    (b) => b.className.trim().toLowerCase() === className.toLowerCase(),
  );

  const exact: Array<{ id: string; name: string }> = [];
  const partial: Array<{ id: string; name: string }> = [];

  for (const b of sameClass) {
    const loadoutHasArmor = loadout.exoticArmorHash != null;
    const loadoutHasWeapon = loadout.exoticWeaponHash != null;
    const buildHasArmor = b.exoticArmorHash != null;
    const buildHasWeapon = b.exoticWeaponHash != null;

    const armorMatch = hashEq(loadout.exoticArmorHash, b.exoticArmorHash);
    const weaponMatch = hashEq(loadout.exoticWeaponHash, b.exoticWeaponHash);

    const anyExoticMatch = armorMatch || weaponMatch;
    if (!anyExoticMatch) continue;

    // Exact when every exotic that exists on either side is consistent:
    // both sides' armor hashes equal when either declares armor; same for weapon.
    const armorOk =
      !loadoutHasArmor && !buildHasArmor
        ? true
        : loadoutHasArmor && buildHasArmor
          ? armorMatch
          : false;
    const weaponOk =
      !loadoutHasWeapon && !buildHasWeapon
        ? true
        : loadoutHasWeapon && buildHasWeapon
          ? weaponMatch
          : false;

    if (armorOk && weaponOk && (loadoutHasArmor || loadoutHasWeapon)) {
      exact.push({ id: b.id, name: b.name });
    } else if (anyExoticMatch) {
      partial.push({ id: b.id, name: b.name });
    }
  }

  if (exact.length > 0) {
    return {
      kind: "exact",
      builds: exact.sort((a, b) =>
        a.name.localeCompare(b.name, undefined, { sensitivity: "base" }),
      ),
    };
  }
  if (partial.length > 0) {
    return {
      kind: "partial",
      builds: partial.sort((a, b) =>
        a.name.localeCompare(b.name, undefined, { sensitivity: "base" }),
      ),
    };
  }
  return { kind: "none", builds: [] };
}

export function loadoutMatchLabel(match: LoadoutBuildMatch): string {
  if (match.kind === "none" || match.builds.length === 0) {
    return "No linked build";
  }
  const names = match.builds.map((b) => b.name).join(", ");
  if (match.kind === "exact") {
    return match.builds.length === 1
      ? `Linked build: ${names}`
      : `Linked builds: ${names}`;
  }
  return match.builds.length === 1
    ? `Partial match: ${names}`
    : `Partial matches: ${names}`;
}

/**
 * Reverse of matchLoadoutToBuilds: which in-game loadouts match this build.
 * Prefers exact matches; includes partial only when no exact hits.
 */
export function matchBuildToLoadouts(
  build: BuildMatchInput,
  loadouts: InGameLoadoutMatchRow[],
): BuildLoadoutMatch {
  const exact: InGameLoadoutMatchRow[] = [];
  const partial: InGameLoadoutMatchRow[] = [];

  for (const lo of loadouts) {
    const m = matchLoadoutToBuilds(lo, [build]);
    if (m.kind === "none" || m.builds.length === 0) continue;
    if (m.kind === "exact") exact.push(lo);
    else partial.push(lo);
  }

  const sortByName = (a: InGameLoadoutMatchRow, b: InGameLoadoutMatchRow) =>
    a.name.localeCompare(b.name, undefined, { sensitivity: "base" });

  if (exact.length > 0) {
    return { kind: "exact", loadouts: exact.sort(sortByName) };
  }
  if (partial.length > 0) {
    return { kind: "partial", loadouts: partial.sort(sortByName) };
  }
  return { kind: "none", loadouts: [] };
}

/** Badge label for matched loadouts on a build card. */
export function buildLoadoutMatchLabel(match: BuildLoadoutMatch): string {
  if (match.kind === "none" || match.loadouts.length === 0) {
    return "";
  }
  const names = match.loadouts.map((l) => l.name).join(", ");
  if (match.kind === "exact") {
    return match.loadouts.length === 1
      ? `In-game: ${names}`
      : `In-game (${match.loadouts.length}): ${names}`;
  }
  return match.loadouts.length === 1
    ? `Partial loadout: ${names}`
    : `Partial loadouts (${match.loadouts.length}): ${names}`;
}

/**
 * Index every build id → its loadout match (for library list rendering).
 */
export function indexBuildLoadoutMatches(
  builds: BuildMatchInput[],
  loadouts: InGameLoadoutMatchRow[],
): Map<string, BuildLoadoutMatch> {
  const map = new Map<string, BuildLoadoutMatch>();
  for (const b of builds) {
    map.set(b.id, matchBuildToLoadouts(b, loadouts));
  }
  return map;
}
