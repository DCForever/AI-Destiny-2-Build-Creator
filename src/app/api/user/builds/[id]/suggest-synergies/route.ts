import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { unauthorizedResponse } from "@/lib/api/response";
import { getBuild } from "@/lib/db/repositories/buildRepository";
import { listSynergies } from "@/lib/db/repositories/synergyRepository";
import { getDb } from "@/lib/db/client";
import { suggestSynergiesWithGoal } from "@/lib/suggestions/suggestSynergies";

export const runtime = "nodejs";

type RouteContext = { params: Promise<{ id: string }> };

export async function GET(request: Request, context: RouteContext): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const { id } = await context.params;
  const url = new URL(request.url);
  const goal = url.searchParams.get("goal") ?? undefined;

  const db = getDb();
  const build = getBuild(db, auth.user.id, id);
  if (!build) return NextResponse.json({ error: "Not found" }, { status: 404 });

  const suggestions = await suggestSynergiesWithGoal({
    build,
    designatedTypes: build.synergyTypes,
    available: listSynergies(db, auth.user.id),
    goal,
  });

  return NextResponse.json({ suggestions });
}
