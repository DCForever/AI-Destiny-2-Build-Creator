import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { apiErrorResponse, unauthorizedResponse } from "@/lib/api/response";
import { getDb } from "@/lib/db/client";
import { optimizeFromSet, refreshOptimizeBodySchema } from "@/lib/optimizer/optimizeFromSet";

export const runtime = "nodejs";

type RouteContext = { params: Promise<{ id: string }> };

export async function POST(request: Request, context: RouteContext): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const { id } = await context.params;
  let body: unknown = {};
  try {
    body = await request.json();
  } catch {
    body = {};
  }

  const parsed = refreshOptimizeBodySchema.safeParse(body ?? {});
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues.map((issue) => issue.message).join("; "), code: "VALIDATION" },
      { status: 400 },
    );
  }

  try {
    const db = getDb();
    const result = await optimizeFromSet({
      db,
      userId: auth.user.id,
      auth,
      setId: id,
      ...(parsed.data.overrides ? { overrides: parsed.data.overrides } : {}),
      ...(parsed.data.maxResults != null ? { maxResults: parsed.data.maxResults } : {}),
    });
    return NextResponse.json(result);
  } catch (error) {
    return apiErrorResponse(error);
  }
}
