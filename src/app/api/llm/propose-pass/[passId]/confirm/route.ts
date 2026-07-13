import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { apiErrorResponse, unauthorizedResponse } from "@/lib/api/response";
import { getDb } from "@/lib/db/client";
import { confirmPassRequestSchema } from "@/lib/llm/propose/proposalSchemas";
import { confirmProposals } from "@/lib/llm/propose/confirmProposals";

export const runtime = "nodejs";

type RouteContext = { params: Promise<{ passId: string }> };

export async function POST(request: Request, context: RouteContext): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const { passId } = await context.params;

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const parsed = confirmPassRequestSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues.map((i) => i.message).join("; ") },
      { status: 400 },
    );
  }

  try {
    const result = await confirmProposals(
      getDb(),
      auth.user.id,
      passId,
      parsed.data.acceptedIds,
      parsed.data.skippedIds,
      parsed.data.proposals,
    );
    return NextResponse.json(result);
  } catch (error) {
    return apiErrorResponse(error);
  }
}
