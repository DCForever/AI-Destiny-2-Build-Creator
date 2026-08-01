import { describe, expect, it, vi } from "vitest";

import type { ChatResponse, LlmClient } from "./llmClient";
import {
  FallbackLlmClient,
  isRetriableLlmError,
} from "./fallbackLlmClient";

function mockClient(overrides: Partial<LlmClient> = {}): LlmClient {
  return {
    chat: vi.fn(async (): Promise<ChatResponse> => ({
      message: { role: "assistant", content: "ok" },
      done: true,
    })),
    listModels: vi.fn(async () => ["model-a"]),
    healthCheck: vi.fn(async () => ({ healthy: true, detail: "ok" })),
    ...overrides,
  };
}

describe("isRetriableLlmError", () => {
  it("treats 401 as non-retriable", () => {
    expect(isRetriableLlmError(new Error("OpenAI /chat/completions failed (401): unauthorized"))).toBe(
      false,
    );
  });

  it("treats 503 as retriable", () => {
    expect(isRetriableLlmError(new Error("OpenAI /chat/completions failed (503): unavailable"))).toBe(
      true,
    );
  });

  it("treats connection errors as retriable", () => {
    expect(isRetriableLlmError(new Error("Cannot reach LLM at https://api.x.ai/v1 (ECONNREFUSED)"))).toBe(
      true,
    );
  });
});

describe("FallbackLlmClient", () => {
  it("uses primary when chat succeeds", async () => {
    const primary = mockClient();
    const fallback = mockClient();
    const client = new FallbackLlmClient(primary, fallback, {
      primaryLabel: "grok",
      fallbackLabel: "ollama",
    });

    await client.chat([{ role: "user", content: "hi" }]);

    expect(primary.chat).toHaveBeenCalledOnce();
    expect(fallback.chat).not.toHaveBeenCalled();
    expect(client.getActiveClient()).toBe("primary");
  });

  it("falls back on retriable primary failure and stays sticky", async () => {
    const primary = mockClient({
      chat: vi
        .fn()
        .mockRejectedValueOnce(new Error("OpenAI /chat/completions failed (503): down"))
        .mockResolvedValue({
          message: { role: "assistant", content: "should not run" },
          done: true,
        }),
    });
    const fallback = mockClient();
    const client = new FallbackLlmClient(primary, fallback, {
      primaryLabel: "grok",
      fallbackLabel: "ollama",
    });

    await client.chat([{ role: "user", content: "first" }]);
    await client.chat([{ role: "user", content: "second" }]);

    expect(primary.chat).toHaveBeenCalledOnce();
    expect(fallback.chat).toHaveBeenCalledTimes(2);
    expect(client.getActiveClient()).toBe("fallback");
  });

  it("does not fall back on non-retriable primary failure", async () => {
    const primary = mockClient({
      chat: vi.fn().mockRejectedValue(new Error("OpenAI /chat/completions failed (401): bad key")),
    });
    const fallback = mockClient();
    const client = new FallbackLlmClient(primary, fallback, {
      primaryLabel: "grok",
      fallbackLabel: "ollama",
    });

    await expect(client.chat([{ role: "user", content: "hi" }])).rejects.toThrow("401");
    expect(fallback.chat).not.toHaveBeenCalled();
  });

  it("throws when both primary and fallback fail", async () => {
    const primary = mockClient({
      chat: vi.fn().mockRejectedValue(new Error("OpenAI /chat/completions failed (503): down")),
    });
    const fallback = mockClient({
      chat: vi.fn().mockRejectedValue(new Error("Cannot reach LLM at http://127.0.0.1:11434")),
    });
    const client = new FallbackLlmClient(primary, fallback, {
      primaryLabel: "grok",
      fallbackLabel: "ollama",
    });

    await expect(client.chat([{ role: "user", content: "hi" }])).rejects.toThrow("127.0.0.1:11434");
  });

  it("healthCheck reports fallback when primary is down", async () => {
    const primary = mockClient({
      healthCheck: vi.fn(async () => ({ healthy: false, detail: "auth failed" })),
    });
    const fallback = mockClient({
      healthCheck: vi.fn(async () => ({ healthy: true, detail: "3 model(s) available" })),
    });
    const client = new FallbackLlmClient(primary, fallback, {
      primaryLabel: "grok",
      fallbackLabel: "ollama",
    });

    const health = await client.healthCheck();

    expect(health.healthy).toBe(true);
    expect(health.active).toBe("fallback");
    expect(health.detail).toContain("ollama");
  });

  it("listModels uses active client after healthCheck selects fallback", async () => {
    const primary = mockClient({
      healthCheck: vi.fn(async () => ({ healthy: false, detail: "down" })),
      listModels: vi.fn(async () => ["grok-4.3"]),
    });
    const fallback = mockClient({
      healthCheck: vi.fn(async () => ({ healthy: true, detail: "ok" })),
      listModels: vi.fn(async () => ["gemma4"]),
    });
    const client = new FallbackLlmClient(primary, fallback, {
      primaryLabel: "grok",
      fallbackLabel: "ollama",
    });

    const models = await client.listModels();

    expect(models).toEqual(["gemma4"]);
    expect(fallback.listModels).toHaveBeenCalled();
  });
});
