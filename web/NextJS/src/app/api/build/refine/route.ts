import { NextResponse } from "next/server";
import { z } from "zod";

import { generatedBuildSchema } from "@/lib/llm/buildSchema";
import { isAbortError } from "@/lib/llm/llmClient";
import { ManifestNotReadyError, runBuildRefine } from "@/lib/services";

export const runtime = "nodejs";
export const maxDuration = 300;

const refineRequestSchema = z.object({
  lockedSections: z.array(z.string().trim().min(1)).default([]),
  changeRequest: z.string().trim().min(1),
  priorBuild: generatedBuildSchema,
  activity: z.string().trim().min(1),
  className: z.enum(["Titan", "Hunter", "Warlock"]),
});

function errorStatus(error: unknown): number {
  if (error instanceof ManifestNotReadyError) return 503;
  if (error instanceof Error && /Ollama|OpenAI|LLM/.test(error.message)) return 502;
  return 500;
}

export async function POST(request: Request): Promise<NextResponse> {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Request body must be JSON" }, { status: 400 });
  }

  const parsed = refineRequestSchema.safeParse(body);
  if (!parsed.success) {
    const issues = parsed.error.issues
      .map((issue) => `${issue.path.join(".")}: ${issue.message}`)
      .join("; ");
    return NextResponse.json({ error: `Invalid refine request: ${issues}` }, { status: 400 });
  }

  try {
    const outcome = await runBuildRefine(parsed.data, request.signal);
    return NextResponse.json(outcome);
  } catch (error) {
    if (isAbortError(error)) {
      return new NextResponse(null, { status: 499 });
    }
    const message = error instanceof Error ? error.message : "Build refine failed";
    return NextResponse.json({ error: message }, { status: errorStatus(error) });
  }
}
