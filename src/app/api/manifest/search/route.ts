import { NextResponse } from "next/server";
import { z } from "zod";

import { getSubclassMeta } from "@/data/subclasses";
import { resolveVerbSubType } from "@/data/synergyVerbs";
import { getServices } from "@/lib/services";
import type { StoreName } from "@/lib/manifest/types/stores";

export const runtime = "nodejs";

const BROWSE_CATEGORIES = new Set([
  "abilities",
  "aspects",
  "fragments",
  "exotic-armor",
  "exotic-weapons",
  "artifacts",
  "mods",
]);

const querySchema = z.object({
  q: z.string().trim().max(80).optional().default(""),
  category: z
    .enum([
      "weapons",
      "exotic-weapons",
      "mods",
      "exotic-armor",
      "aspects",
      "fragments",
      "abilities",
      "artifacts",
    ])
    .default("weapons"),
  slot: z.enum(["Kinetic", "Energy", "Power"]).optional(),
  kind: z.enum(["super", "grenade", "melee", "classAbility", "movement"]).optional(),
  classType: z.enum(["Titan", "Hunter", "Warlock"]).optional(),
  element: z.string().trim().min(1).optional(),
  subclass: z.string().trim().min(1).optional(),
  verb: z.string().trim().min(1).optional(),
  limit: z.coerce.number().int().min(1).max(50).optional(),
});

type SearchResult = {
  record: {
    name: string;
    hash: number;
    icon?: string | null;
    slot?: string;
    kind?: string;
    classType?: string | null;
    element?: string;
    description?: string;
    subclassAffinities?: string[];
    verbs?: string[];
  };
  confidence: number;
};

function slotFilter(
  results: SearchResult[],
  slot: "Kinetic" | "Energy" | "Power" | undefined,
) {
  if (!slot) return results;
  return results.filter((r) => r.record.slot === slot);
}

function kindFilter(
  results: SearchResult[],
  category: string,
  kind: string | undefined,
) {
  if (category !== "abilities" || !kind) return results;
  return results.filter((r) => r.record.kind === kind);
}

/** Supers/melee/movement/class abilities are never shared across classes. */
const CLASS_LOCKED_KINDS = new Set(["super", "classAbility", "melee", "movement"]);

/**
 * Null classType usually means shared (e.g. grenades). Class-locked kinds with
 * affinities spanning multiple classes are mis-enriched — exclude them when
 * browsing by class so Hunter/Titan Strand supers do not appear for Warlock.
 */
function affinitiesExclusiveToClass(
  affinities: string[] | undefined,
  classType: string,
): boolean {
  if (!affinities || affinities.length === 0) return true;
  const classes = affinities
    .map((name) => getSubclassMeta(name)?.classType)
    .filter((value): value is NonNullable<typeof value> => value != null);
  if (classes.length === 0) return true;
  return classes.every((value) => value === classType);
}

function classTypeFilter(
  results: SearchResult[],
  classType: string | undefined,
  kind: string | undefined,
) {
  if (!classType) return results;
  return results.filter((r) => {
    if (!("classType" in r.record)) return true;
    if (r.record.classType == null) {
      if (kind && CLASS_LOCKED_KINDS.has(kind)) {
        return affinitiesExclusiveToClass(r.record.subclassAffinities, classType);
      }
      // FR-001 clarify: null classType = shared / class-agnostic — include with class filter.
      return true;
    }
    return r.record.classType === classType;
  });
}

function elementFilter(results: SearchResult[], element: string | undefined) {
  if (!element) return results;
  return results.filter((r) => {
    if (!("element" in r.record)) return true;
    return r.record.element === element;
  });
}

function normalizeLabel(value: string): string {
  return value.trim().toLowerCase();
}

function subclassFilter(
  results: SearchResult[],
  category: string,
  subclass: string | undefined,
) {
  if (category !== "abilities" || !subclass) return results;
  const wanted = normalizeLabel(subclass);
  return results.filter((r) =>
    (r.record.subclassAffinities ?? []).some((a) => normalizeLabel(a) === wanted),
  );
}

function verbFilter(
  results: SearchResult[],
  category: string,
  verb: string | undefined,
) {
  if (category !== "abilities" || !verb) return results;
  const canonical = resolveVerbSubType(verb) ?? verb;
  const wanted = normalizeLabel(canonical);
  return results.filter((r) =>
    (r.record.verbs ?? []).some((v) => normalizeLabel(v) === wanted),
  );
}

function applyFilters(results: SearchResult[], query: z.infer<typeof querySchema>) {
  return verbFilter(
    subclassFilter(
      elementFilter(
        classTypeFilter(
          kindFilter(slotFilter(results, query.slot), query.category, query.kind),
          query.classType,
          query.kind,
        ),
        query.element,
      ),
      query.category,
      query.subclass,
    ),
    query.category,
    query.verb,
  );
}

function toSearchResult(record: SearchResult["record"], confidence = 1): SearchResult {
  return { record, confidence };
}

function toResponseResult(result: SearchResult, store: string) {
  const perks =
    store === "artifacts" &&
    "perks" in result.record &&
    Array.isArray((result.record as { perks?: unknown }).perks)
      ? (
          (result.record as {
            perks: Array<{ hash: number; name: string; column?: number; row?: number }>;
          }).perks
        ).map((p) => ({
          hash: p.hash,
          name: p.name,
          column: p.column,
          row: p.row,
        }))
      : undefined;

  return {
    name: result.record.name,
    hash: result.record.hash,
    icon: result.record.icon ?? null,
    slot: "slot" in result.record ? result.record.slot : undefined,
    kind: "kind" in result.record ? result.record.kind : undefined,
    classType: "classType" in result.record ? result.record.classType : undefined,
    element: "element" in result.record ? result.record.element : undefined,
    ...(result.record.description !== undefined
      ? { description: result.record.description }
      : {}),
    ...(result.record.subclassAffinities !== undefined
      ? { subclassAffinities: result.record.subclassAffinities }
      : {}),
    ...(result.record.verbs !== undefined ? { verbs: result.record.verbs } : {}),
    ...(perks ? { perks } : {}),
    confidence: result.confidence,
    isExotic: store === "exotic-weapons",
  };
}

export async function GET(request: Request): Promise<NextResponse> {
  const url = new URL(request.url);
  const parsed = querySchema.safeParse({
    q: url.searchParams.get("q") ?? "",
    category: url.searchParams.get("category") ?? "weapons",
    slot: url.searchParams.get("slot") ?? undefined,
    kind: url.searchParams.get("kind") ?? undefined,
    classType: url.searchParams.get("classType") ?? undefined,
    element: url.searchParams.get("element") ?? undefined,
    subclass: url.searchParams.get("subclass") ?? undefined,
    verb: url.searchParams.get("verb") ?? undefined,
    limit: url.searchParams.get("limit") ?? undefined,
  });

  if (!parsed.success) {
    const issues = parsed.error.issues.map((i) => i.message).join("; ");
    return NextResponse.json({ error: issues }, { status: 400 });
  }

  if (
    parsed.data.category !== "abilities" &&
    (parsed.data.subclass != null || parsed.data.verb != null)
  ) {
    return NextResponse.json(
      { error: "subclass and verb filters are only supported for category=abilities" },
      { status: 400 },
    );
  }

  try {
    const { entityCache, resolver } = await getServices();
    const store = parsed.data.category;
    const limit = parsed.data.limit ?? (parsed.data.q ? 8 : 50);
    if (!parsed.data.q && !BROWSE_CATEGORIES.has(store)) {
      return NextResponse.json({ error: "Empty search is not supported for this category" }, { status: 400 });
    }

    const raw = parsed.data.q
      ? await resolver.search(store, parsed.data.q, limit * 2)
      : (await entityCache.getStore(store as StoreName)).map((record) =>
          toSearchResult(record as SearchResult["record"]),
        );
    const filtered = applyFilters(raw, parsed.data).slice(0, limit);

    return NextResponse.json({
      results: filtered.map((result) => toResponseResult(result, store)),
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Search failed";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
