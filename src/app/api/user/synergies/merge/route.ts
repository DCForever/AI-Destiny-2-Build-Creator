import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { apiErrorResponse, unauthorizedResponse } from "@/lib/api/response";
import { getDb } from "@/lib/db/client";
import { mergeSynergiesSchema } from "@/lib/synergies/schemas";
import {
  mergeUserSynergies,
  withLinkDescriptions,
} from "@/lib/synergies/synergyService";

export const runtime = "nodejs";

/**
 * Merge one or more library synergies into a survivor (same type + subType).
 * Unions links, joins descriptions, deletes sources.
 */
export async function POST(request: Request): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Request body must be JSON" }, { status: 400 });
  }

  const parsed = mergeSynergiesSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues.map((i) => i.message).join("; ") },
      { status: 400 },
    );
  }

  try {
    const result = await mergeUserSynergies(getDb(), auth.user.id, parsed.data);
    return NextResponse.json({
      ...result,
      synergy: await withLinkDescriptions(result.synergy),
    });
  } catch (error) {
    return apiErrorResponse(error);
  }
}
