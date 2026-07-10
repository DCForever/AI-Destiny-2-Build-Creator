import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { apiErrorResponse, unauthorizedResponse } from "@/lib/api/response";
import { assertEquipReady } from "@/lib/builds/equipReady";
import { getResolvedVariant } from "@/lib/builds/buildService";
import { getDb } from "@/lib/db/client";

export const runtime = "nodejs";

type RouteContext = { params: Promise<{ id: string; variantId: string }> };

export async function POST(request: Request, context: RouteContext): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const { id, variantId } = await context.params;
  try {
    const db = getDb();
    const resolved = await getResolvedVariant(db, auth.user.id, id, variantId);
    if (!resolved) return NextResponse.json({ error: "Not found" }, { status: 404 });
    const readiness = { equipReady: resolved.equipReady, pinStatuses: resolved.pinStatuses };
    assertEquipReady(readiness);
    return NextResponse.json({ allowed: true, ...readiness });
  } catch (error) {
    return apiErrorResponse(error);
  }
}
