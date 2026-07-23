import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { apiErrorResponse, unauthorizedResponse } from "@/lib/api/response";
import { getDb } from "@/lib/db/client";
import {
  buildImprovementSuggestions,
  parseImprovementSuggestionsQuery,
} from "@/lib/optimizer/improvementSuggestions";

export const runtime = "nodejs";

export async function GET(request: Request): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const query = parseImprovementSuggestionsQuery(new URL(request.url));
  try {
    const db = getDb();
    const result = await buildImprovementSuggestions({
      db,
      userId: auth.user.id,
      auth,
      afterSync: query.afterSync,
      ...(query.armorSetId ? { armorSetId: query.armorSetId } : {}),
    });
    return NextResponse.json(result);
  } catch (error) {
    return apiErrorResponse(error);
  }
}
