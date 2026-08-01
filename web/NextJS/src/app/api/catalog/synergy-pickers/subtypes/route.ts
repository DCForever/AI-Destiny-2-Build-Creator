import { NextResponse } from "next/server";
import { z } from "zod";

import { filterSubTypeOptions, listSubTypeOptions } from "@/lib/synergies/subTypeVocabularies";
import { SUB_TYPE_REQUIRED_TYPES } from "@/lib/synergies/synergyTypeRules";

export const runtime = "nodejs";

const querySchema = z.object({
  category: z.enum(SUB_TYPE_REQUIRED_TYPES),
  q: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(2000).optional(),
});

export async function GET(request: Request): Promise<NextResponse> {
  const url = new URL(request.url);
  const parsed = querySchema.safeParse({
    category: url.searchParams.get("category"),
    q: url.searchParams.get("q") ?? undefined,
    limit: url.searchParams.get("limit") ?? undefined,
  });
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid category" }, { status: 400 });
  }

  try {
    const q = parsed.data.q?.trim() ?? "";
    const limit = parsed.data.limit ?? (q ? 50 : 2000);
    const allOptions = await listSubTypeOptions(parsed.data.category);
    const options = filterSubTypeOptions(allOptions, q, limit);
    return NextResponse.json({ category: parsed.data.category, options });
  } catch {
    return NextResponse.json({ error: "Manifest not loaded" }, { status: 503 });
  }
}
