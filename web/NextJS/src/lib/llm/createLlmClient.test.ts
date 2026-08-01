import { afterEach, describe, expect, it, vi } from "vitest";

import { getLlmConfig, getLlmFallbackConfig } from "@/lib/config/env";

import { createLlmClient } from "./createLlmClient";
import { FallbackLlmClient } from "./fallbackLlmClient";
import { HttpOllamaClient } from "./ollamaClient";
import { OpenAiCompatibleClient } from "./openAiClient";

const ENV_KEYS = [
  "LLM_PROVIDER",
  "LLM_URL",
  "LLM_MODEL",
  "LLM_MODEL_GROK",
  "LLM_API_KEY",
  "XAI_API_KEY",
  "OLLAMA_URL",
  "OLLAMA_MODEL",
] as const;

function clearLlmEnv(): void {
  for (const key of ENV_KEYS) {
    delete process.env[key];
  }
}

describe("getLlmConfig", () => {
  afterEach(() => {
    clearLlmEnv();
    vi.unstubAllEnvs();
  });

  it("defaults to openai provider and LM Studio-friendly URL when unset", () => {
    clearLlmEnv();
    const config = getLlmConfig();
    expect(config.provider).toBe("openai");
    expect(config.url).toBe("http://127.0.0.1:1234/v1");
    expect(config.model).toBe("local-model");
    expect(config.apiKey).toBeNull();
  });

  it("uses OLLAMA_* fallback when only legacy vars are set", () => {
    vi.stubEnv("OLLAMA_URL", "http://localhost:11434");
    vi.stubEnv("OLLAMA_MODEL", "gemma4");
    const config = getLlmConfig();
    expect(config.provider).toBe("ollama");
    expect(config.url).toBe("http://localhost:11434");
    expect(config.model).toBe("gemma4");
  });

  it("honors explicit LLM_PROVIDER=openai with LLM_URL and LLM_MODEL", () => {
    vi.stubEnv("LLM_PROVIDER", "openai");
    vi.stubEnv("LLM_URL", "http://127.0.0.1:9999/v1");
    vi.stubEnv("LLM_MODEL", "my-model");
    vi.stubEnv("LLM_API_KEY", "test-key");
    const config = getLlmConfig();
    expect(config.provider).toBe("openai");
    expect(config.url).toBe("http://127.0.0.1:9999/v1");
    expect(config.model).toBe("my-model");
    expect(config.apiKey).toBe("test-key");
  });

  it("honors explicit LLM_PROVIDER=ollama", () => {
    vi.stubEnv("LLM_PROVIDER", "ollama");
    vi.stubEnv("LLM_URL", "http://127.0.0.1:11434");
    vi.stubEnv("LLM_MODEL", "llama3");
    const config = getLlmConfig();
    expect(config.provider).toBe("ollama");
  });

  it("defaults grok to xAI URL and model", () => {
    vi.stubEnv("LLM_PROVIDER", "grok");
    const config = getLlmConfig();
    expect(config.provider).toBe("grok");
    expect(config.url).toBe("https://api.x.ai/v1");
    expect(config.model).toBe("grok-4.3");
    expect(config.apiKey).toBeNull();
  });

  it("uses XAI_API_KEY for grok when LLM_API_KEY is unset", () => {
    vi.stubEnv("LLM_PROVIDER", "grok");
    vi.stubEnv("XAI_API_KEY", "xai-secret");
    const config = getLlmConfig();
    expect(config.apiKey).toBe("xai-secret");
  });

  it("uses LLM_MODEL_GROK when set for grok provider", () => {
    vi.stubEnv("LLM_PROVIDER", "grok");
    vi.stubEnv("LLM_MODEL_GROK", "grok-4.3-latest");
    const config = getLlmConfig();
    expect(config.model).toBe("grok-4.3-latest");
  });

  it("does not use LLM_MODEL as grok primary", () => {
    vi.stubEnv("LLM_PROVIDER", "grok");
    vi.stubEnv("LLM_URL", "http://127.0.0.1:1234/v1");
    vi.stubEnv("LLM_MODEL", "local-model");
    const config = getLlmConfig();
    expect(config.url).toBe("https://api.x.ai/v1");
    expect(config.model).toBe("grok-4.3");
  });
});

describe("getLlmFallbackConfig", () => {
  afterEach(() => {
    clearLlmEnv();
    vi.unstubAllEnvs();
  });

  it("returns null when primary is not grok", () => {
    vi.stubEnv("LLM_PROVIDER", "openai");
    vi.stubEnv("OLLAMA_URL", "http://127.0.0.1:11434");
    expect(getLlmFallbackConfig()).toBeNull();
  });

  it("returns ollama fallback when OLLAMA_* is set with grok primary", () => {
    vi.stubEnv("LLM_PROVIDER", "grok");
    vi.stubEnv("OLLAMA_URL", "http://127.0.0.1:11434");
    vi.stubEnv("OLLAMA_MODEL", "gemma4");
    const fallback = getLlmFallbackConfig();
    expect(fallback).toEqual({
      provider: "ollama",
      url: "http://127.0.0.1:11434",
      model: "gemma4",
      apiKey: null,
    });
  });

  it("returns local openai fallback when LLM_URL is localhost with grok primary", () => {
    vi.stubEnv("LLM_PROVIDER", "grok");
    vi.stubEnv("LLM_URL", "http://127.0.0.1:1234/v1");
    vi.stubEnv("LLM_MODEL", "my-local-model");
    const fallback = getLlmFallbackConfig();
    expect(fallback).toEqual({
      provider: "openai",
      url: "http://127.0.0.1:1234/v1",
      model: "my-local-model",
      apiKey: null,
    });
  });

  it("prefers ollama over local LLM_URL when both are set", () => {
    vi.stubEnv("LLM_PROVIDER", "grok");
    vi.stubEnv("OLLAMA_URL", "http://127.0.0.1:11434");
    vi.stubEnv("LLM_URL", "http://127.0.0.1:1234/v1");
    const fallback = getLlmFallbackConfig();
    expect(fallback?.provider).toBe("ollama");
  });

  it("returns null for grok-only config with no local vars", () => {
    vi.stubEnv("LLM_PROVIDER", "grok");
    vi.stubEnv("XAI_API_KEY", "secret");
    expect(getLlmFallbackConfig()).toBeNull();
  });
});

describe("createLlmClient", () => {
  afterEach(() => {
    clearLlmEnv();
    vi.unstubAllEnvs();
  });

  it("returns OpenAiCompatibleClient for openai provider", () => {
    vi.stubEnv("LLM_PROVIDER", "openai");
    expect(createLlmClient()).toBeInstanceOf(OpenAiCompatibleClient);
  });

  it("returns HttpOllamaClient for ollama provider", () => {
    vi.stubEnv("LLM_PROVIDER", "ollama");
    expect(createLlmClient()).toBeInstanceOf(HttpOllamaClient);
  });

  it("returns OpenAiCompatibleClient for grok without fallback", () => {
    vi.stubEnv("LLM_PROVIDER", "grok");
    expect(createLlmClient()).toBeInstanceOf(OpenAiCompatibleClient);
  });

  it("returns FallbackLlmClient for grok with ollama fallback", () => {
    vi.stubEnv("LLM_PROVIDER", "grok");
    vi.stubEnv("OLLAMA_URL", "http://127.0.0.1:11434");
    expect(createLlmClient()).toBeInstanceOf(FallbackLlmClient);
  });

  it("returns FallbackLlmClient for grok with local LLM_URL fallback", () => {
    vi.stubEnv("LLM_PROVIDER", "grok");
    vi.stubEnv("LLM_URL", "http://127.0.0.1:1234/v1");
    expect(createLlmClient()).toBeInstanceOf(FallbackLlmClient);
  });
});
