import { NextResponse } from "next/server";
import { z } from "zod";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { unauthorizedResponse } from "@/lib/api/response";
import { getBuild } from "@/lib/db/repositories/buildRepository";
import { getVariant } from "@/lib/db/repositories/variantRepository";
import { getSynergiesByIds } from "@/lib/db/repositories/synergyRepository";
import { listSets } from "@/lib/db/repositories/setRepository";
import { getDb } from "@/lib/db/client";
import { buildAutomaticSuggestionContext, suggestSets } from "@/lib/suggestions/suggestSets";

export const runtime = "nodejs";

type RouteContext = { params: Promise<{ id: string; variantId: string }> };

const bodySchema = z.object({ goal: z.string().trim().optional() });

export async function POST(request: Request, context: RouteContext): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const { id, variantId } = await context.params;
  let body: unknown = {};
  try {
    const text = await request.text();
    if (text) body = JSON.parse(text);
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = bodySchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.issues.map((i) => i.message).join("; ") }, { status: 400 });
  }

  const db = getDb();
  const build = getBuild(db, auth.user.id, id);
  const variant = getVariant(db, id, variantId);
  if (!build || !variant) return NextResponse.json({ error: "Not found" }, { status: 404 });

  const synergies = getSynergiesByIds(db, auth.user.id, build.synergyIds);
  const ctx = buildAutomaticSuggestionContext(build, variant, synergies);
  if (parsed.data.goal) ctx.goal = parsed.data.goal;

  const suggestions = suggestSets(listSets(db, auth.user.id), ctx);
  return NextResponse.json({ suggestions, context: ctx });
}
