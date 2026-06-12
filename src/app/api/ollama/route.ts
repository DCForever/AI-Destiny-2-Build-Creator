import { NextResponse } from "next/server";

import { getServices } from "@/lib/services";

export const runtime = "nodejs";

export async function GET(): Promise<NextResponse> {
  const { ollama } = await getServices();
  const health = await ollama.healthCheck();
  if (!health.healthy) {
    return NextResponse.json({ healthy: false, detail: health.detail, models: [] });
  }
  const models = await ollama.listModels();
  return NextResponse.json({ healthy: true, detail: health.detail, models });
}
