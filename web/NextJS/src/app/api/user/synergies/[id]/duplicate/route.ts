import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { apiErrorResponse, unauthorizedResponse } from "@/lib/api/response";
import { getDb } from "@/lib/db/client";
import {
  duplicateUserSynergy,
  withLinkDescriptions,
} from "@/lib/synergies/synergyService";

export const runtime = "nodejs";

type RouteContext = { params: Promise<{ id: string }> };

/** POST /api/user/synergies/:id/duplicate — clone into a new library row. */
export async function POST(
  request: Request,
  context: RouteContext,
): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const { id } = await context.params;

  try {
    const db = getDb();
    const synergy = await duplicateUserSynergy(db, auth.user.id, id);
    if (!synergy) {
      return NextResponse.json({ error: "Not found" }, { status: 404 });
    }
    return NextResponse.json(
      { synergy: await withLinkDescriptions(synergy) },
      { status: 201 },
    );
  } catch (error) {
    return apiErrorResponse(error);
  }
}
