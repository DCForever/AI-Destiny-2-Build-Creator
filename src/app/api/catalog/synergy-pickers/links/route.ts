import { NextResponse } from "next/server";
import { z } from "zod";

import { searchSynergyLinkPickerItems } from "@/lib/synergies/synergyPickerLinks";

export const runtime = "nodejs";

const querySchema = z.object({
  kind: z.enum(["origin_trait", "weapon_perk", "armor_set_bonus"]),
  q: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(100).optional(),
});

export async function GET(request: Request): Promise<NextResponse> {
  const url = new URL(request.url);
  const parsed = querySchema.safeParse({
    kind: url.searchParams.get("kind"),
    q: url.searchParams.get("q") ?? undefined,
    limit: url.searchParams.get("limit") ?? undefined,
  });
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid query" }, { status: 400 });
  }

  try {
    const limit = parsed.data.limit ?? 50;
    const items = await searchSynergyLinkPickerItems(parsed.data.kind, parsed.data.q ?? "", limit);
    return NextResponse.json({ kind: parsed.data.kind, items });
  } catch {
    return NextResponse.json({ error: "Manifest not loaded" }, { status: 503 });
  }
}
