import type { LlmConfig } from "@/lib/config/env";
import { getLlmConfig, getLlmFallbackConfig } from "@/lib/config/env";

import { FallbackLlmClient } from "./fallbackLlmClient";
import type { LlmClient } from "./llmClient";
import { HttpOllamaClient } from "./ollamaClient";
import { OpenAiCompatibleClient } from "./openAiClient";

export function createClientForConfig(config: LlmConfig): LlmClient {
  if (config.provider === "ollama") {
    return new HttpOllamaClient({ baseUrl: config.url, model: config.model });
  }
  return new OpenAiCompatibleClient({
    baseUrl: config.url,
    model: config.model,
    apiKey: config.apiKey,
  });
}

export function createLlmClient(): LlmClient {
  const config = getLlmConfig();
  const primary = createClientForConfig(config);
  const fallbackConfig = getLlmFallbackConfig();
  if (fallbackConfig) {
    return new FallbackLlmClient(primary, createClientForConfig(fallbackConfig), {
      primaryLabel: config.provider,
      fallbackLabel: fallbackConfig.provider,
    });
  }
  return primary;
}

/** @deprecated Use createLlmClient() */
export function createOllamaClient(): LlmClient {
  return createLlmClient();
}

export type { LlmClient };
