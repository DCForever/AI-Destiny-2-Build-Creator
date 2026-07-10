import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { unauthorizedResponse } from "@/lib/api/response";
import { getBuild } from "@/lib/db/repositories/buildRepository";
import { getSynergiesByIds } from "@/lib/db/repositories/synergyRepository";
import { getDb } from "@/lib/db/client";
import { suggestStatNudges } from "@/lib/builds/statNudges";

export const runtime = "nodejs";

type RouteContext = { params: Promise<{ id: string }> };

export async function GET(request: Request, context: RouteContext): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const { id } = await context.params;
  const db = getDb();
  const build = getBuild(db, auth.user.id, id);
  if (!build) return NextResponse.json({ error: "Not found" }, { status: 404 });

  const synergies = getSynergiesByIds(db, auth.user.id, build.synergyIds);
  return NextResponse.json({
    nudges: suggestStatNudges(synergies),
    softStatTargets: build.softStatTargets,
  });
}
