import type { LlmProvider } from "@/lib/config/env";

import type {
  ChatMessage,
  ChatOptions,
  ChatResponse,
  LlmClient,
} from "./llmClient";

export type FallbackActiveClient = "primary" | "fallback";

export interface FallbackHealthResult {
  healthy: boolean;
  detail: string;
  active: FallbackActiveClient;
}

export interface FallbackLlmClientLabels {
  primaryLabel: LlmProvider;
  fallbackLabel: LlmProvider;
}

const RETRIABLE_STATUS = new Set([429, 502, 503, 504]);

export function isRetriableLlmError(error: unknown): boolean {
  if (!(error instanceof Error)) return true;
  const message = error.message;
  const statusMatch = message.match(/\((\d{3})\)/);
  if (statusMatch) {
    const status = Number(statusMatch[1]);
    if (status === 400 || status === 401 || status === 403) return false;
    if (RETRIABLE_STATUS.has(status)) return true;
  }
  if (/Cannot reach LLM|fetch failed|network error|ECONNREFUSED|timed out/i.test(message)) {
    return true;
  }
  return false;
}

export class FallbackLlmClient implements LlmClient {
  private active: FallbackActiveClient = "primary";
  readonly labels: FallbackLlmClientLabels;

  constructor(
    private readonly primary: LlmClient,
    private readonly fallback: LlmClient,
    labels: FallbackLlmClientLabels,
  ) {
    this.labels = labels;
  }

  getActiveClient(): FallbackActiveClient {
    return this.active;
  }

  async chat(messages: ChatMessage[], options?: ChatOptions): Promise<ChatResponse> {
    const client = this.active === "primary" ? this.primary : this.fallback;
    try {
      return await client.chat(messages, options);
    } catch (error) {
      if (this.active === "fallback" || !isRetriableLlmError(error)) {
        throw error;
      }
      this.active = "fallback";
      return this.fallback.chat(messages, options);
    }
  }

  async listModels(): Promise<string[]> {
    const health = await this.healthCheck();
    const client = health.active === "primary" ? this.primary : this.fallback;
    return client.listModels();
  }

  async healthCheck(): Promise<FallbackHealthResult> {
    const primaryHealth = await this.primary.healthCheck();
    if (primaryHealth.healthy) {
      this.active = "primary";
      return { ...primaryHealth, active: "primary" };
    }

    const fallbackHealth = await this.fallback.healthCheck();
    if (fallbackHealth.healthy) {
      this.active = "fallback";
      return {
        healthy: true,
        active: "fallback",
        detail: `Primary unavailable (${primaryHealth.detail}); using ${this.labels.fallbackLabel} fallback`,
      };
    }

    return {
      healthy: false,
      active: "primary",
      detail: `Primary: ${primaryHealth.detail}; fallback: ${fallbackHealth.detail}`,
    };
  }
}

export function isFallbackLlmClient(client: LlmClient): client is FallbackLlmClient {
  return client instanceof FallbackLlmClient;
}
