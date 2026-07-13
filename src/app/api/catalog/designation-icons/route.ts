import { NextResponse } from "next/server";
import { z } from "zod";

import {
  curatedDesignationIconMap,
  designationIconMap,
  type DesignationRef,
} from "@/lib/synergies/designationIcons";

export const runtime = "nodejs";

const bodySchema = z.object({
  /** When true (default for empty body), return icons for all curated verbs + elements. */
  curated: z.boolean().optional(),
  designations: z
    .array(
      z.object({
        type: z.string().trim().min(1),
        subType: z.string().trim().min(1).nullable().optional(),
      }),
    )
    .optional(),
});

/**
 * Resolve official Bungie icons for synergy designations (type + subtype).
 * POST { designations: [{ type, subType }] } or { curated: true }.
 */
export async function POST(request: Request): Promise<NextResponse> {
  let body: unknown = {};
  try {
    const text = await request.text();
    if (text.trim()) body = JSON.parse(text);
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const parsed = bodySchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues.map((i) => i.message).join("; ") },
      { status: 400 },
    );
  }

  try {
    const refs = parsed.data.designations as DesignationRef[] | undefined;
    const useCurated =
      parsed.data.curated === true || !refs || refs.length === 0;

    const icons = useCurated
      ? await curatedDesignationIconMap()
      : await designationIconMap(refs!);

    return NextResponse.json({ icons });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Failed to resolve designation icons";
    return NextResponse.json({ error: message }, { status: 503 });
  }
}

/** GET ?curated=1 — preload verb + element icons. */
export async function GET(request: Request): Promise<NextResponse> {
  const curated =
    new URL(request.url).searchParams.get("curated") !== "0";
  try {
    const icons = curated
      ? await curatedDesignationIconMap()
      : await curatedDesignationIconMap();
    return NextResponse.json({ icons });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Failed to resolve designation icons";
    return NextResponse.json({ error: message }, { status: 503 });
  }
}
