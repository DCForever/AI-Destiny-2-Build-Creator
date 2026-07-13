/**
 * Derive which builds use a set from attachment edges.
 * Pure: callers supply build/variant/attachment DTOs (no DB).
 */

export type BuildSetUsageInput = {
  id: string;
  name: string;
  variants: Array<{
    id: string;
    name: string;
    attachments: Array<{ setId: string }>;
  }>;
};

export type BuildSetUsage = {
  buildId: string;
  buildName: string;
  /** Variant names that attach this set */
  variantNames: string[];
};

export function buildsUsingSet(
  setId: string,
  builds: BuildSetUsageInput[],
): BuildSetUsage[] {
  const id = setId.trim();
  if (!id) return [];
  const out: BuildSetUsage[] = [];
  for (const build of builds) {
    const variantNames: string[] = [];
    for (const v of build.variants) {
      if (v.attachments.some((a) => a.setId === id)) {
        variantNames.push(v.name);
      }
    }
    if (variantNames.length > 0) {
      out.push({
        buildId: build.id,
        buildName: build.name,
        variantNames,
      });
    }
  }
  return out.sort((a, b) =>
    a.buildName.localeCompare(b.buildName, undefined, { sensitivity: "base" }),
  );
}
