import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { unauthorizedResponse } from "@/lib/api/response";
import { compareBuildVariants } from "@/lib/builds/compareVariants";
import { getDb } from "@/lib/db/client";

export const runtime = "nodejs";

type RouteContext = { params: Promise<{ id: string }> };

export async function GET(request: Request, context: RouteContext): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const { id } = await context.params;
  const url = new URL(request.url);
  const variantIds = url.searchParams.get("variantIds")?.split(",").map((v) => v.trim()).filter(Boolean);

  const db = getDb();
  const compare = await compareBuildVariants(db, auth.user.id, id, variantIds);
  if (!compare) return NextResponse.json({ error: "Not found" }, { status: 404 });

  return NextResponse.json(compare);
}
