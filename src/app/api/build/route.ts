import { NextResponse } from "next/server";

import { buildRequestSchema } from "@/lib/llm/buildSchema";
import { ManifestNotReadyError, runBuildGeneration } from "@/lib/services";

export const runtime = "nodejs";
/** Local model generation is slow; allow up to 5 minutes. */
export const maxDuration = 300;

function errorStatus(error: unknown): number {
  if (error instanceof ManifestNotReadyError) return 503;
  if (error instanceof Error && /Ollama/.test(error.message)) return 502;
  return 500;
}

export async function POST(request: Request): Promise<NextResponse> {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Request body must be JSON" }, { status: 400 });
  }

  const parsed = buildRequestSchema.safeParse(body);
  if (!parsed.success) {
    const issues = parsed.error.issues
      .map((issue) => `${issue.path.join(".")}: ${issue.message}`)
      .join("; ");
    return NextResponse.json({ error: `Invalid build request: ${issues}` }, { status: 400 });
  }

  try {
    const outcome = await runBuildGeneration(parsed.data);
    return NextResponse.json(outcome);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Build generation failed";
    return NextResponse.json({ error: message }, { status: errorStatus(error) });
  }
}
