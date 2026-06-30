import { NextResponse } from "next/server";
import { z } from "zod";

import { listSubTypeOptions } from "@/lib/synergies/subTypeVocabularies";
import { SUB_TYPE_REQUIRED_TYPES } from "@/lib/synergies/synergyTypeRules";

export const runtime = "nodejs";

const querySchema = z.object({
  category: z.enum(SUB_TYPE_REQUIRED_TYPES),
});

export async function GET(request: Request): Promise<NextResponse> {
  const url = new URL(request.url);
  const parsed = querySchema.safeParse({ category: url.searchParams.get("category") });
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid category" }, { status: 400 });
  }

  try {
    const options = await listSubTypeOptions(parsed.data.category);
    return NextResponse.json({ category: parsed.data.category, options });
  } catch {
    return NextResponse.json({ error: "Manifest not loaded" }, { status: 503 });
  }
}
