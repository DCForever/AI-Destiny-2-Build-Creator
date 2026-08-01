import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { apiErrorResponse, unauthorizedResponse } from "@/lib/api/response";
import { getDb } from "@/lib/db/client";
import { createSynergySchema } from "@/lib/synergies/schemas";
import {
  createUserSynergy,
  listUserSynergiesConsolidated,
  withLinkDescriptions,
} from "@/lib/synergies/synergyService";
import type { SynergyType } from "@/lib/synergies/schemas";

export const runtime = "nodejs";

export async function GET(request: Request): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const url = new URL(request.url);
  const type = url.searchParams.get("type") as SynergyType | null;

  const db = getDb();
  const synergies = await listUserSynergiesConsolidated(
    db,
    auth.user.id,
    type ?? undefined,
  );
  return NextResponse.json({ synergies });
}

export async function POST(request: Request): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Request body must be JSON" }, { status: 400 });
  }

  const parsed = createSynergySchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues.map((i) => i.message).join("; ") },
      { status: 400 },
    );
  }

  try {
    const db = getDb();
    const synergy = await createUserSynergy(db, auth.user.id, parsed.data);
    return NextResponse.json(
      { synergy: await withLinkDescriptions(synergy) },
      { status: 201 },
    );
  } catch (error) {
    return apiErrorResponse(error);
  }
}
