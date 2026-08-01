import { synergyTypeDesignationKey } from "@/lib/synergies/generateSynergyName";

export type BuildWithDesignations = {
  synergyTypes: Array<{ type: string; subType?: string | null }>;
};

export type DesignationRef = {
  type: string;
  subType?: string | null;
};

/** Count builds that include the given designation on synergyTypes. */
export function countBuildsForDesignation(
  builds: BuildWithDesignations[],
  designation: DesignationRef,
): number {
  const key = synergyTypeDesignationKey({
    type: designation.type,
    subType: designation.subType ?? null,
  });
  let n = 0;
  for (const build of builds) {
    if (
      build.synergyTypes.some(
        (d) =>
          synergyTypeDesignationKey({
            type: d.type,
            subType: d.subType ?? null,
          }) === key,
      )
    ) {
      n += 1;
    }
  }
  return n;
}

/** Map designation key → build count for all builds. */
export function buildCountByDesignationKey(
  builds: BuildWithDesignations[],
): Map<string, number> {
  const map = new Map<string, number>();
  for (const build of builds) {
    const seen = new Set<string>();
    for (const d of build.synergyTypes) {
      const key = synergyTypeDesignationKey({
        type: d.type,
        subType: d.subType ?? null,
      });
      if (seen.has(key)) continue;
      seen.add(key);
      map.set(key, (map.get(key) ?? 0) + 1);
    }
  }
  return map;
}

export type BuildUsageRef = {
  id: string;
  name: string;
  className: string;
};

/** Builds that list the designation (stable name order). */
export function listBuildsForDesignation<
  T extends BuildWithDesignations & { id: string; name: string; className?: string },
>(builds: T[], designation: DesignationRef): BuildUsageRef[] {
  const key = synergyTypeDesignationKey({
    type: designation.type,
    subType: designation.subType ?? null,
  });
  const matched = builds.filter((build) =>
    build.synergyTypes.some(
      (d) =>
        synergyTypeDesignationKey({
          type: d.type,
          subType: d.subType ?? null,
        }) === key,
    ),
  );
  matched.sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: "base" }));
  return matched.map((b) => ({
    id: b.id,
    name: b.name,
    className: b.className ?? "",
  }));
}
