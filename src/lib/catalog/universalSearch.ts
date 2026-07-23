import {
  compareMatchRank,
  matchDescriptionQuery,
  type DescriptionMatchField,
} from "@/lib/search/descriptionMatch";
import type { EntityStores, StoreName } from "@/lib/manifest/types/stores";
import { formatWeaponPerkSourceLabel } from "@/lib/synergies/weaponPerkSourceLabel";

import {
  COMPOSITION_KINDS,
  hitActions,
  type CompositionKind,
} from "./compositionKinds";

/** Equippable item kinds that can show inventory ownership. */
const OWNABLE_COMPOSITION_KINDS: ReadonlySet<CompositionKind> = new Set([
  "weapon",
  "exotic_weapon",
  "armor",
  "exotic_armor",
]);

export type CompositionSearchHit = {
  kind: CompositionKind;
  id: string;
  name: string;
  description: string;
  icon: string | null;
  hash?: number;
  meta?: Record<string, unknown>;
  matchField: DescriptionMatchField | null;
  owned: { count: number } | null;
  actions: { set: boolean; synergy: boolean };
};

export type LegendaryArmorSearchRow = {
  hash: number;
  name: string;
  searchName: string;
  icon: string | null;
  slot: string;
  classType?: string;
  setBonusName?: string;
  description?: string;
};

export type SearchCompositionCatalogInput = {
  q: string;
  kinds?: CompositionKind[];
  limit?: number;
  /** Combined owned hash → count (weapons + armor buckets). */
  ownedHashes?: Map<number, number>;
  /** Legendary set armor projections (not a standalone entity store). */
  legendaryArmor?: LegendaryArmorSearchRow[];
};

export type SearchCompositionCatalogResult = {
  query: string;
  kinds: CompositionKind[];
  hits: CompositionSearchHit[];
  truncated: boolean;
  code?: "NEED_QUERY" | "FILTERED_EMPTY";
};

export type EntityStoreGetter = <TName extends StoreName>(
  name: TName,
) => Promise<EntityStores[TName]>;

type RankedHit = CompositionSearchHit & { _rank: DescriptionMatchField | null };

function hitId(kind: CompositionKind, key: string | number): string {
  return `${kind}:${key}`;
}

function ownedSummary(
  kind: CompositionKind,
  hash: number | undefined,
  ownedHashes: Map<number, number> | undefined,
): { count: number } | null {
  if (!OWNABLE_COMPOSITION_KINDS.has(kind) || hash == null || !ownedHashes) {
    return null;
  }
  const count = ownedHashes.get(hash) ?? 0;
  return count > 0 ? { count } : null;
}

function toHit(
  kind: CompositionKind,
  fields: {
    idKey: string | number;
    name: string;
    description: string;
    icon: string | null;
    hash?: number;
    meta?: Record<string, unknown>;
    matchField: DescriptionMatchField | null;
  },
  ownedHashes?: Map<number, number>,
): RankedHit {
  return {
    kind,
    id: hitId(kind, fields.idKey),
    name: fields.name,
    description: fields.description,
    icon: fields.icon,
    ...(fields.hash != null ? { hash: fields.hash } : {}),
    ...(fields.meta ? { meta: fields.meta } : {}),
    matchField: fields.matchField,
    owned: ownedSummary(kind, fields.hash, ownedHashes),
    actions: hitActions(kind),
    _rank: fields.matchField,
  };
}

function softCapForKind(limit: number, kindCount: number): number {
  return Math.max(6, Math.ceil((limit * 1.5) / Math.max(1, kindCount)));
}

function sortRanked(a: RankedHit, b: RankedHit): number {
  const rank = compareMatchRank(a._rank, b._rank);
  if (rank !== 0) return rank;
  return a.name.localeCompare(b.name);
}

function stripRank(hit: RankedHit): CompositionSearchHit {
  const { _rank: _, ...rest } = hit;
  return rest;
}

async function collectKindHits(
  kind: CompositionKind,
  q: string,
  getStore: EntityStoreGetter,
  ownedHashes: Map<number, number> | undefined,
  legendaryArmor: LegendaryArmorSearchRow[] | undefined,
): Promise<RankedHit[]> {
  const hits: RankedHit[] = [];

  if (kind === "weapon") {
    const weapons = await getStore("weapons");
    for (const w of weapons) {
      const m = matchDescriptionQuery(q, {
        name: w.name,
        searchName: w.searchName,
        description: w.frame,
        otherTexts: [w.itemTypeName, w.slot, w.element, w.ammo],
      });
      if (!m.matched) continue;
      hits.push(
        toHit(
          kind,
          {
            idKey: w.hash,
            name: w.name,
            description: w.itemTypeName ? `${w.itemTypeName} · ${w.frame}` : w.frame,
            icon: w.icon,
            hash: w.hash,
            meta: {
              slot: w.slot,
              element: w.element,
              ammo: w.ammo,
              frame: w.frame,
              itemTypeName: w.itemTypeName,
            },
            matchField: m.matchField,
          },
          ownedHashes,
        ),
      );
    }
    return hits;
  }

  if (kind === "exotic_weapon") {
    const weapons = await getStore("exotic-weapons");
    for (const w of weapons) {
      const m = matchDescriptionQuery(q, {
        name: w.name,
        searchName: w.searchName,
        description: w.intrinsic?.description ?? "",
        otherTexts: [w.intrinsic?.name ?? "", w.frame, w.slot, w.element],
      });
      if (!m.matched) continue;
      hits.push(
        toHit(
          kind,
          {
            idKey: w.hash,
            name: w.name,
            description: w.intrinsic?.description ?? "",
            icon: w.icon,
            hash: w.hash,
            meta: {
              slot: w.slot,
              element: w.element,
              ammo: w.ammo,
              frame: w.frame,
              intrinsicName: w.intrinsic?.name,
            },
            matchField: m.matchField,
          },
          ownedHashes,
        ),
      );
    }
    return hits;
  }

  if (kind === "armor") {
    for (const a of legendaryArmor ?? []) {
      const m = matchDescriptionQuery(q, {
        name: a.name,
        searchName: a.searchName,
        description: a.description ?? "",
        otherTexts: [a.setBonusName ?? "", a.slot, a.classType ?? ""],
      });
      if (!m.matched) continue;
      hits.push(
        toHit(
          kind,
          {
            idKey: a.hash,
            name: a.name,
            description: a.description ?? a.setBonusName ?? "",
            icon: a.icon,
            hash: a.hash,
            meta: {
              slot: a.slot,
              classType: a.classType,
              setBonusName: a.setBonusName,
            },
            matchField: m.matchField,
          },
          ownedHashes,
        ),
      );
    }
    return hits;
  }

  if (kind === "exotic_armor") {
    const armor = await getStore("exotic-armor");
    for (const a of armor) {
      const m = matchDescriptionQuery(q, {
        name: a.name,
        searchName: a.searchName,
        description: a.intrinsic?.description ?? "",
        otherTexts: [a.intrinsic?.name ?? "", a.slot, a.classType],
      });
      if (!m.matched) continue;
      hits.push(
        toHit(
          kind,
          {
            idKey: a.hash,
            name: a.name,
            description: a.intrinsic?.description ?? "",
            icon: a.icon,
            hash: a.hash,
            meta: {
              slot: a.slot,
              classType: a.classType,
              archetype: a.archetype,
              intrinsicName: a.intrinsic?.name,
            },
            matchField: m.matchField,
          },
          ownedHashes,
        ),
      );
    }
    return hits;
  }

  if (kind === "mod") {
    const mods = await getStore("mods");
    for (const mod of mods) {
      const m = matchDescriptionQuery(q, {
        name: mod.name,
        searchName: mod.searchName,
        description: mod.description,
        otherTexts: [mod.slotCategory],
      });
      if (!m.matched) continue;
      hits.push(
        toHit(
          kind,
          {
            idKey: mod.hash,
            name: mod.name,
            description: mod.description,
            icon: mod.icon,
            hash: mod.hash,
            meta: {
              slotCategory: mod.slotCategory,
              energyCost: mod.energyCost,
            },
            matchField: m.matchField,
          },
          ownedHashes,
        ),
      );
    }
    return hits;
  }

  if (kind === "weapon_perk") {
    const perks = await getStore("weapon-perks");
    for (const p of perks) {
      const m = matchDescriptionQuery(q, {
        name: p.name,
        searchName: p.searchName,
        description: p.description,
      });
      if (!m.matched) continue;
      const sourceLabel = formatWeaponPerkSourceLabel(p.source, p.plugTypeName);
      hits.push(
        toHit(
          kind,
          {
            idKey: p.hash,
            name: p.name,
            description: p.description,
            icon: p.icon,
            hash: p.hash,
            meta: {
              ...(sourceLabel ? { sourceLabel } : {}),
              plugTypeName: p.plugTypeName ?? null,
            },
            matchField: m.matchField,
          },
          ownedHashes,
        ),
      );
    }
    return hits;
  }

  if (kind === "origin_trait") {
    const traits = await getStore("origin-traits");
    for (const t of traits) {
      const m = matchDescriptionQuery(q, {
        name: t.name,
        searchName: t.searchName,
        description: t.description,
      });
      if (!m.matched) continue;
      hits.push(
        toHit(
          kind,
          {
            idKey: t.hash,
            name: t.name,
            description: t.description,
            icon: t.icon,
            hash: t.hash,
            matchField: m.matchField,
          },
          ownedHashes,
        ),
      );
    }
    return hits;
  }

  if (kind === "armor_set_bonus") {
    const sets = await getStore("set-bonuses");
    for (const set of sets) {
      for (const perk of set.perks) {
        const m = matchDescriptionQuery(q, {
          name: set.name,
          searchName: set.searchName,
          otherTexts: [perk.name, perk.description],
        });
        if (!m.matched) continue;
        const pieces = perk.requiredCount as 2 | 4;
        hits.push(
          toHit(
            kind,
            {
              idKey: `${set.hash}:${pieces}`,
              name: `${set.name} ${pieces}pc — ${perk.name}`,
              description: perk.description,
              icon: set.icon,
              hash: set.hash,
              meta: {
                armorSetName: set.name,
                armorSetHash: set.hash,
                bonusPieces: pieces,
                bonusName: perk.name,
              },
              matchField: m.matchField,
            },
            ownedHashes,
          ),
        );
      }
    }
    return hits;
  }

  if (kind === "artifact_perk") {
    const artifacts = await getStore("artifacts");
    for (const art of artifacts) {
      for (const perk of art.perks ?? []) {
        const artifactName = perk.artifactName?.trim() || art.name;
        const m = matchDescriptionQuery(q, {
          name: perk.name,
          searchName: perk.searchName,
          description: perk.description,
          otherTexts: [artifactName, art.name],
        });
        if (!m.matched) continue;
        hits.push(
          toHit(
            kind,
            {
              idKey: perk.hash,
              name: perk.name,
              description: perk.description ?? "",
              icon: perk.icon ?? art.icon,
              hash: perk.hash,
              meta: {
                artifactName,
                parentItemHash: art.hash,
                column: perk.column,
                row: perk.row,
              },
              matchField: m.matchField,
            },
            ownedHashes,
          ),
        );
      }
    }
    return hits;
  }

  if (kind === "aspect") {
    const aspects = await getStore("aspects");
    for (const a of aspects) {
      const m = matchDescriptionQuery(q, {
        name: a.name,
        searchName: a.searchName,
        description: a.description,
        otherTexts: [a.element, a.classType ?? ""],
      });
      if (!m.matched) continue;
      hits.push(
        toHit(
          kind,
          {
            idKey: a.hash,
            name: a.name,
            description: a.description,
            icon: a.icon,
            hash: a.hash,
            meta: {
              classType: a.classType,
              element: a.element,
              fragmentCapacity: a.fragmentCapacity,
            },
            matchField: m.matchField,
          },
          ownedHashes,
        ),
      );
    }
    return hits;
  }

  if (kind === "fragment") {
    const fragments = await getStore("fragments");
    for (const f of fragments) {
      const m = matchDescriptionQuery(q, {
        name: f.name,
        searchName: f.searchName,
        description: f.description,
        otherTexts: [f.element],
      });
      if (!m.matched) continue;
      hits.push(
        toHit(
          kind,
          {
            idKey: f.hash,
            name: f.name,
            description: f.description,
            icon: f.icon,
            hash: f.hash,
            meta: { element: f.element },
            matchField: m.matchField,
          },
          ownedHashes,
        ),
      );
    }
    return hits;
  }

  // ability
  const abilities = await getStore("abilities");
  for (const a of abilities) {
    const m = matchDescriptionQuery(q, {
      name: a.name,
      searchName: a.searchName,
      description: a.description,
      otherTexts: [
        a.kind,
        a.element,
        a.classType ?? "",
        ...(a.subclassAffinities ?? []),
        ...(a.verbs ?? []),
      ],
    });
    if (!m.matched) continue;
    hits.push(
      toHit(
        kind,
        {
          idKey: a.hash,
          name: a.name,
          description: a.description,
          icon: a.icon,
          hash: a.hash,
          meta: {
            kind: a.kind,
            classType: a.classType,
            element: a.element,
            subclassAffinities: a.subclassAffinities,
            verbs: a.verbs,
          },
          matchField: m.matchField,
        },
        ownedHashes,
      ),
    );
  }
  return hits;
}

/**
 * Mixed-kind composition search over entity-cache stores (+ optional legendary armor).
 * Whitespace-only query → NEED_QUERY (no full catalog dump).
 */
export async function searchCompositionCatalog(
  getStore: EntityStoreGetter,
  input: SearchCompositionCatalogInput,
): Promise<SearchCompositionCatalogResult> {
  const query = input.q ?? "";
  const trimmed = query.trim();
  const activeKinds = input.kinds?.length ? input.kinds : [...COMPOSITION_KINDS];
  const limit = input.limit ?? 48;

  if (!trimmed) {
    return {
      query: trimmed,
      kinds: activeKinds,
      hits: [],
      truncated: false,
      code: "NEED_QUERY",
    };
  }

  const softCap = softCapForKind(limit, activeKinds.length);
  const pooled: RankedHit[] = [];

  for (const kind of activeKinds) {
    const kindHits = await collectKindHits(
      kind,
      trimmed,
      getStore,
      input.ownedHashes,
      input.legendaryArmor,
    );
    kindHits.sort(sortRanked);
    pooled.push(...kindHits.slice(0, softCap));
  }

  pooled.sort(sortRanked);
  const truncated = pooled.length > limit;
  const hits = pooled.slice(0, limit).map(stripRank);

  let code: SearchCompositionCatalogResult["code"];
  if (hits.length === 0 && input.kinds?.length) {
    code = "FILTERED_EMPTY";
  }

  return {
    query: trimmed,
    kinds: activeKinds,
    hits,
    truncated,
    ...(code ? { code } : {}),
  };
}
