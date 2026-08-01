/**
 * Build a create-form subclass kit from catalog search results for the
 * selected subclass — never reuse a hardcoded Sunbreaker placeholder.
 */

import type { BuildSubclass } from "@/components/build/types";
import { resolveSubclassScope } from "@/lib/debug/subclassScope";
import { buildSubclassSearchParams } from "@/lib/debug/subclassSearchParams";

export type CatalogNameHit = {
  name: string;
  kind?: string;
  classType?: string | null;
};

const ABILITY_KINDS = ["super", "classAbility", "movement", "melee", "grenade"] as const;

export function pickFirstName(results: CatalogNameHit[]): string {
  return results[0]?.name?.trim() || "";
}

export function pickNames(
  results: CatalogNameHit[],
  limit: number,
  preferredClassType?: string | null,
): string[] {
  const ranked = preferredClassType
    ? [
        ...results.filter((item) => item.classType === preferredClassType),
        ...results.filter(
          (item) => item.classType == null || item.classType !== preferredClassType,
        ),
      ]
    : results;

  const names: string[] = [];
  for (const item of ranked) {
    const name = item.name?.trim();
    if (!name || name.startsWith("Empty ") || names.includes(name)) continue;
    // When we know the class, skip explicitly other-class rows.
    if (
      preferredClassType &&
      item.classType != null &&
      item.classType !== preferredClassType
    ) {
      continue;
    }
    names.push(name);
    if (names.length >= limit) break;
  }
  return names;
}

export function subclassKitFromCatalogHits(input: {
  subclassName: string;
  abilitiesByKind: Record<(typeof ABILITY_KINDS)[number], CatalogNameHit[]>;
  aspects: CatalogNameHit[];
  fragments: CatalogNameHit[];
  pinnedSuper?: string | null;
}): BuildSubclass {
  const scope = resolveSubclassScope(input.subclassName);
  const superName = input.pinnedSuper?.trim() || pickFirstName(input.abilitiesByKind.super);
  return {
    name: input.subclassName,
    super: superName,
    classAbility: pickFirstName(input.abilitiesByKind.classAbility),
    movement: pickFirstName(input.abilitiesByKind.movement),
    melee: pickFirstName(input.abilitiesByKind.melee),
    grenade: pickFirstName(input.abilitiesByKind.grenade),
    aspects: pickNames(input.aspects, 2, scope?.classType),
    fragments: pickNames(input.fragments, 2),
    rationale: "Curated build",
  };
}

async function fetchCatalog(params: URLSearchParams): Promise<CatalogNameHit[]> {
  const res = await fetch(`/api/manifest/search?${params}`);
  const body = await res.json();
  if (!res.ok) throw new Error(body.error ?? "Catalog search failed");
  return (body.results ?? []) as CatalogNameHit[];
}

/** Load a subclass-scoped starter kit for production create. */
export async function fetchSubclassKitForCreate(
  subclassName: string,
  pinnedSuper: string | null,
): Promise<BuildSubclass> {
  const abilityEntries = await Promise.all(
    ABILITY_KINDS.map(async (kind) => {
      const params = buildSubclassSearchParams({
        category: "abilities",
        q: "",
        subclassName,
        kind,
      });
      const results = await fetchCatalog(params);
      return [kind, results] as const;
    }),
  );

  const [aspects, fragments] = await Promise.all([
    fetchCatalog(
      buildSubclassSearchParams({ category: "aspects", q: "", subclassName }),
    ),
    fetchCatalog(
      buildSubclassSearchParams({ category: "fragments", q: "", subclassName }),
    ),
  ]);

  const abilitiesByKind = Object.fromEntries(abilityEntries) as Record<
    (typeof ABILITY_KINDS)[number],
    CatalogNameHit[]
  >;

  const kit = subclassKitFromCatalogHits({
    subclassName,
    abilitiesByKind,
    aspects,
    fragments,
    pinnedSuper,
  });

  if (
    !kit.super ||
    !kit.classAbility ||
    !kit.movement ||
    !kit.melee ||
    !kit.grenade ||
    kit.aspects.length === 0 ||
    kit.fragments.length === 0
  ) {
    throw new Error(
      `Could not source a complete subclass kit for ${subclassName} from the catalog.`,
    );
  }

  return kit;
}
