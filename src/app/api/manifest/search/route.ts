import { NextResponse } from "next/server";
import { z } from "zod";

import { getServices } from "@/lib/services";
import type { StoreName } from "@/lib/manifest/types/stores";

export const runtime = "nodejs";

const BROWSE_CATEGORIES = new Set([
  "abilities",
  "aspects",
  "fragments",
  "exotic-armor",
  "exotic-weapons",
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

function classTypeFilter(results: SearchResult[], classType: string | undefined) {
  if (!classType) return results;
  return results.filter((r) => {
    if (!("classType" in r.record)) return true;
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

function applyFilters(results: SearchResult[], query: z.infer<typeof querySchema>) {
  return elementFilter(
    classTypeFilter(kindFilter(slotFilter(results, query.slot), query.category, query.kind), query.classType),
    query.element,
  );
}

function toSearchResult(record: SearchResult["record"], confidence = 1): SearchResult {
  return { record, confidence };
}

function toResponseResult(result: SearchResult, store: string) {
  return {
    name: result.record.name,
    hash: result.record.hash,
    icon: result.record.icon ?? null,
    slot: "slot" in result.record ? result.record.slot : undefined,
    kind: "kind" in result.record ? result.record.kind : undefined,
    classType: "classType" in result.record ? result.record.classType : undefined,
    element: "element" in result.record ? result.record.element : undefined,
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
    limit: url.searchParams.get("limit") ?? undefined,
  });

  if (!parsed.success) {
    const issues = parsed.error.issues.map((i) => i.message).join("; ");
    return NextResponse.json({ error: issues }, { status: 400 });
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
      : (await entityCache.getStore(store as StoreName)).map((record) => toSearchResult(record));
    const filtered = applyFilters(raw, parsed.data).slice(0, limit);

    return NextResponse.json({
      results: filtered.map((result) => toResponseResult(result, store)),
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Search failed";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
