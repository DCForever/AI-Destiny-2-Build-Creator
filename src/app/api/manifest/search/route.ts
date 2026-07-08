import { NextResponse } from "next/server";
import { z } from "zod";

import { getServices } from "@/lib/services";

export const runtime = "nodejs";

const querySchema = z.object({
  q: z.string().trim().min(1).max(80),
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
  limit: z.coerce.number().int().min(1).max(20).default(8),
});

type SearchResult = {
  record: {
    name: string;
    hash: number;
    icon: string | null;
    slot?: string;
    kind?: string;
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

export async function GET(request: Request): Promise<NextResponse> {
  const url = new URL(request.url);
  const parsed = querySchema.safeParse({
    q: url.searchParams.get("q") ?? "",
    category: url.searchParams.get("category") ?? "weapons",
    slot: url.searchParams.get("slot") ?? undefined,
    kind: url.searchParams.get("kind") ?? undefined,
    limit: url.searchParams.get("limit") ?? "8",
  });

  if (!parsed.success) {
    const issues = parsed.error.issues.map((i) => i.message).join("; ");
    return NextResponse.json({ error: issues }, { status: 400 });
  }

  try {
    const { resolver } = await getServices();
    const store = parsed.data.category;
    const raw = await resolver.search(store, parsed.data.q, parsed.data.limit * 2);
    const filtered = kindFilter(slotFilter(raw, parsed.data.slot), store, parsed.data.kind).slice(
      0,
      parsed.data.limit,
    );

    return NextResponse.json({
      results: filtered.map((r) => ({
        name: r.record.name,
        hash: r.record.hash,
        icon: r.record.icon,
        slot: "slot" in r.record ? r.record.slot : undefined,
        kind: "kind" in r.record ? r.record.kind : undefined,
        confidence: r.confidence,
        isExotic: store === "exotic-weapons",
      })),
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Search failed";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
