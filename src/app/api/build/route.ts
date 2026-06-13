import { NextResponse } from "next/server";

import { buildRequestSchema } from "@/lib/llm/buildSchema";
import { isAbortError } from "@/lib/llm/llmClient";
import { ManifestNotReadyError, runBuildGeneration } from "@/lib/services";

export const runtime = "nodejs";
/** Local model generation is slow; allow up to 5 minutes. */
export const maxDuration = 300;

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

  const parsed = buildRequestSchema.safeParse(body);
  if (!parsed.success) {
    const issues = parsed.error.issues
      .map((issue) => `${issue.path.join(".")}: ${issue.message}`)
      .join("; ");
    return NextResponse.json({ error: `Invalid build request: ${issues}` }, { status: 400 });
  }

  try {
    const outcome = await runBuildGeneration(parsed.data, request.signal);
    return NextResponse.json(outcome);
  } catch (error) {
    if (isAbortError(error)) {
      return new NextResponse(null, { status: 499 });
    }
    const message = error instanceof Error ? error.message : "Build generation failed";
    // #region agent log
    fetch('http://127.0.0.1:7497/ingest/c1e77a25-b3cb-458d-a22e-6f4c8c0c4060',{method:'POST',headers:{'Content-Type':'application/json','X-Debug-Session-Id':'7c9b57'},body:JSON.stringify({sessionId:'7c9b57',location:'build/route.ts:catch',message:'runBuildGeneration failed',data:{message,name:error instanceof Error?error.name:'unknown',cause:error instanceof Error&&'cause' in error?String((error as Error&{cause?:unknown}).cause):undefined,signalAborted:request.signal.aborted},timestamp:Date.now(),hypothesisId:'A,C,D'})}).catch(()=>{});
    // #endregion
    return NextResponse.json({ error: message }, { status: errorStatus(error) });
  }
}
