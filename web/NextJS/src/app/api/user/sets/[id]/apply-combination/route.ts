import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { apiErrorResponse, unauthorizedResponse } from "@/lib/api/response";
import { getDb } from "@/lib/db/client";
import { loadOwnedArmorOwnership } from "@/lib/inventory/loadOwnedArmorOwnership";
import {
  applyCombinationBodySchema,
  applyCombinationInPlace,
} from "@/lib/sets/applyCombinationInPlace";

export const runtime = "nodejs";

type RouteContext = { params: Promise<{ id: string }> };

export async function POST(request: Request, context: RouteContext): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const { id } = await context.params;
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Request body must be JSON" }, { status: 400 });
  }

  const parsed = applyCombinationBodySchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues.map((issue) => issue.message).join("; "), code: "VALIDATION" },
      { status: 400 },
    );
  }

  try {
    const db = getDb();
    const ownership = await loadOwnedArmorOwnership({ db, userId: auth.user.id, auth });
    const result = await applyCombinationInPlace(db, auth.user.id, id, parsed.data, ownership);
    return NextResponse.json(result);
  } catch (error) {
    return apiErrorResponse(error);
  }
}
