import { NextResponse } from "next/server";

import { getLlmConfig, getLlmFallbackConfig } from "@/lib/config/env";
import { createClientForConfig } from "@/lib/llm/createLlmClient";
import { isFallbackLlmClient } from "@/lib/llm/fallbackLlmClient";
import { getServices } from "@/lib/services";

export const runtime = "nodejs";

export async function GET(): Promise<NextResponse> {
  const config = getLlmConfig();
  const fallbackConfig = getLlmFallbackConfig();
  const { llm } = await getServices();
  const health = await llm.healthCheck();

  const active =
    isFallbackLlmClient(llm) && "active" in health
      ? (health as { active: string }).active
      : "primary";

  let fallback: { provider: string; healthy: boolean; detail: string } | undefined;
  if (fallbackConfig) {
    const fallbackHealth = await createClientForConfig(fallbackConfig).healthCheck();
    fallback = {
      provider: fallbackConfig.provider,
      healthy: fallbackHealth.healthy,
      detail: fallbackHealth.detail,
    };
  }

  const base = {
    provider: config.provider,
    healthy: health.healthy,
    detail: health.detail,
    active,
    ...(fallback ? { fallback } : {}),
  };

  if (!health.healthy) {
    return NextResponse.json({ ...base, models: [] });
  }

  const models = await llm.listModels();
  return NextResponse.json({ ...base, models });
}
