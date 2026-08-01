import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { apiErrorResponse, unauthorizedResponse } from "@/lib/api/response";
import { getDb } from "@/lib/db/client";
import { loadOwnedArmorOwnership } from "@/lib/inventory/loadOwnedArmorOwnership";
import {
  materializeCombination,
  materializeCombinationBodySchema,
} from "@/lib/sets/materializeCombination";

export const runtime = "nodejs";

export async function POST(request: Request): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Request body must be JSON" }, { status: 400 });
  }

  const parsed = materializeCombinationBodySchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues.map((issue) => issue.message).join("; "), code: "VALIDATION" },
      { status: 400 },
    );
  }

  try {
    const db = getDb();
    const ownership = await loadOwnedArmorOwnership({ db, userId: auth.user.id, auth });
    const result = await materializeCombination(db, auth.user.id, parsed.data, ownership);
    return NextResponse.json(result);
  } catch (error) {
    return apiErrorResponse(error);
  }
}
