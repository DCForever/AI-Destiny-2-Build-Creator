import { NextResponse } from "next/server";
import { z } from "zod";

import { getServices } from "@/lib/services";

export const runtime = "nodejs";

const querySchema = z.object({
  q: z.string().trim().min(1).max(80),
  category: z.enum(["weapons", "exotic-weapons", "mods", "exotic-armor"]).default("weapons"),
  slot: z.enum(["Kinetic", "Energy", "Power"]).optional(),
  limit: z.coerce.number().int().min(1).max(20).default(8),
});

function slotFilter(
  results: Array<{ record: { slot?: string; name: string; hash: number; icon: string | null }; confidence: number }>,
  slot: "Kinetic" | "Energy" | "Power" | undefined,
) {
  if (!slot) return results;
  return results.filter((r) => r.record.slot === slot);
}

export async function GET(request: Request): Promise<NextResponse> {
  const url = new URL(request.url);
  const parsed = querySchema.safeParse({
    q: url.searchParams.get("q") ?? "",
    category: url.searchParams.get("category") ?? "weapons",
    slot: url.searchParams.get("slot") ?? undefined,
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
    const filtered = slotFilter(raw, parsed.data.slot).slice(0, parsed.data.limit);

    return NextResponse.json({
      results: filtered.map((r) => ({
        name: r.record.name,
        hash: r.record.hash,
        icon: r.record.icon,
        slot: "slot" in r.record ? r.record.slot : undefined,
        confidence: r.confidence,
        isExotic: store === "exotic-weapons",
      })),
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Search failed";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
