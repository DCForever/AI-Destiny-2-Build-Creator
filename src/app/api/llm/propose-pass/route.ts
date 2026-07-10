import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { apiErrorResponse, unauthorizedResponse } from "@/lib/api/response";
import { proposePassRequestSchema } from "@/lib/llm/propose/proposalSchemas";
import { runProposePass } from "@/lib/llm/propose/runProposePass";
import { createLlmClient } from "@/lib/llm/createLlmClient";

export const runtime = "nodejs";

export async function POST(request: Request): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const parsed = proposePassRequestSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues.map((i) => i.message).join("; ") },
      { status: 400 },
    );
  }

  try {
    const client = parsed.data.useMock ? null : createLlmClient();
    const result = await runProposePass(parsed.data.descriptions, {
      client,
      useMock: parsed.data.useMock ?? process.env.LLM_PROPOSE_MOCK === "1",
    });
    return NextResponse.json(result);
  } catch (error) {
    return apiErrorResponse(error);
  }
}
