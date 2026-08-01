import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { unauthorizedResponse } from "@/lib/api/response";
import { getVariantCoverage } from "@/lib/builds/coverageService";
import { getDb } from "@/lib/db/client";

export const runtime = "nodejs";

type RouteContext = { params: Promise<{ id: string; variantId: string }> };

export async function GET(request: Request, context: RouteContext): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const { id, variantId } = await context.params;
  const db = getDb();
  const coverage = await getVariantCoverage(db, auth.user.id, id, variantId);
  if (!coverage) return NextResponse.json({ error: "Not found" }, { status: 404 });
  return NextResponse.json({ coverage });
}
