import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { apiErrorResponse, unauthorizedResponse } from "@/lib/api/response";
import { getDb } from "@/lib/db/client";
import { updateSynergySchema } from "@/lib/synergies/schemas";
import {
  deleteUserSynergy,
  getUserSynergy,
  updateUserSynergy,
} from "@/lib/synergies/synergyService";

export const runtime = "nodejs";

type RouteContext = { params: Promise<{ id: string }> };

export async function GET(request: Request, context: RouteContext): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const { id } = await context.params;
  const db = getDb();
  const synergy = getUserSynergy(db, auth.user.id, id);
  if (!synergy) return NextResponse.json({ error: "Not found" }, { status: 404 });
  return NextResponse.json({ synergy });
}

export async function PATCH(request: Request, context: RouteContext): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const { id } = await context.params;
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Request body must be JSON" }, { status: 400 });
  }

  const parsed = updateSynergySchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues.map((i) => i.message).join("; ") },
      { status: 400 },
    );
  }

  try {
    const db = getDb();
    const synergy = await updateUserSynergy(db, auth.user.id, id, parsed.data);
    if (!synergy) return NextResponse.json({ error: "Not found" }, { status: 404 });
    return NextResponse.json({ synergy });
  } catch (error) {
    return apiErrorResponse(error);
  }
}

export async function DELETE(request: Request, context: RouteContext): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const { id } = await context.params;
  const db = getDb();
  const deleted = deleteUserSynergy(db, auth.user.id, id);
  if (!deleted) return NextResponse.json({ error: "Not found" }, { status: 404 });
  return NextResponse.json({ deleted: true });
}
