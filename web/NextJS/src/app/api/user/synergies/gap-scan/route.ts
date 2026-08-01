import { NextResponse } from "next/server";
import { z } from "zod";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { apiErrorResponse, unauthorizedResponse } from "@/lib/api/response";
import { getDb } from "@/lib/db/client";
import { readUserPreferences } from "@/lib/preferences/store";
import { runGapScan } from "@/lib/synergies/runGapScan";
import { DEFAULT_GAP_KINDS } from "@/lib/synergies/gapScanTypes";

export const runtime = "nodejs";

const bodySchema = z.object({
  scope: z.enum(["owned", "manifest", "both"]).default("both"),
  kinds: z
    .array(
      z.enum([
        "type",
        "weapon",
        "weapon_perk",
        "origin_trait",
        "armor_set_bonus",
      ]),
    )
    .optional(),
  /** Search missing type designations (e.g. "Sliding"). */
  query: z.string().trim().max(80).optional(),
  limit: z.number().int().min(1).max(500).optional(),
  maxPerKind: z.number().int().min(1).max(2000).optional(),
});

/**
 * Scan for missing synergy type designations (default) and/or unlinked gear.
 * Returns gaps and a propose-pass id for bulk confirm via
 * POST /api/llm/propose-pass/:passId/confirm.
 */
export async function POST(request: Request): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

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
    const prefs = await readUserPreferences(auth.user.bungieMembershipId);
    const result = await runGapScan(getDb(), auth.user.id, {
      scope: parsed.data.scope,
      kinds: parsed.data.kinds ?? [...DEFAULT_GAP_KINDS],
      query: parsed.data.query,
      limit: parsed.data.limit,
      maxPerKind: parsed.data.maxPerKind,
      ignoredKeys: prefs.ignoredSynergyTypeKeys ?? [],
    });
    return NextResponse.json(result);
  } catch (error) {
    return apiErrorResponse(error);
  }
}
