/**
 * Typed access to environment configuration. Server-only.
 *
 * Optional integrations (Bungie OAuth, SearXNG) expose `null` when not
 * configured so callers degrade gracefully instead of crashing at import time.
 */

export interface OllamaConfig {
  url: string;
  model: string;
}

export type LlmProvider = "ollama" | "openai" | "grok";

export interface LlmConfig {
  provider: LlmProvider;
  url: string;
  model: string;
  /** Optional Bearer token for OpenAI-compatible servers. */
  apiKey: string | null;
}

export interface BungieOAuthConfig {
  apiKey: string;
  clientId: string;
  clientSecret: string;
}

const DEFAULT_OLLAMA_URL = "http://127.0.0.1:11434";
const DEFAULT_OLLAMA_MODEL = "gemma4";
const DEFAULT_OPENAI_URL = "http://127.0.0.1:1234/v1";
const DEFAULT_OPENAI_MODEL = "local-model";
const DEFAULT_GROK_URL = "https://api.x.ai/v1";
const DEFAULT_GROK_MODEL = "grok-4.3";

function readTrimmed(name: string): string | null {
  const value = process.env[name]?.trim();
  return value ? value : null;
}

function parseLlmProvider(raw: string | null): LlmProvider | null {
  if (raw === "ollama" || raw === "openai" || raw === "grok") return raw;
  return null;
}

/** True when the URL host is localhost or 127.0.0.1 (local LLM servers). */
export function isLocalLlmUrl(url: string): boolean {
  try {
    const host = new URL(url).hostname.toLowerCase();
    return host === "localhost" || host === "127.0.0.1";
  } catch {
    return false;
  }
}

function resolveGrokPrimaryUrl(llmUrl: string | null): string {
  if (llmUrl && !isLocalLlmUrl(llmUrl)) return llmUrl;
  return DEFAULT_GROK_URL;
}

function resolveApiKey(provider: LlmProvider): string | null {
  const llmApiKey = readTrimmed("LLM_API_KEY");
  if (provider === "grok") {
    return llmApiKey ?? readTrimmed("XAI_API_KEY");
  }
  return llmApiKey;
}

/** @deprecated Use getLlmConfig() instead. */
export function getOllamaConfig(): OllamaConfig {
  const config = getLlmConfig();
  return { url: config.url, model: config.model };
}

export function getLlmConfig(): LlmConfig {
  const llmUrl = readTrimmed("LLM_URL");
  const llmModel = readTrimmed("LLM_MODEL");
  const ollamaUrl = readTrimmed("OLLAMA_URL");
  const ollamaModel = readTrimmed("OLLAMA_MODEL");
  const explicitProvider = parseLlmProvider(readTrimmed("LLM_PROVIDER"));

  let provider: LlmProvider;
  if (explicitProvider) {
    provider = explicitProvider;
  } else if ((llmUrl || llmModel) && !(ollamaUrl || ollamaModel)) {
    provider = "openai";
  } else if ((ollamaUrl || ollamaModel) && !(llmUrl || llmModel)) {
    provider = "ollama";
  } else {
    provider = "openai";
  }

  let url: string;
  let model: string;

  if (provider === "grok") {
    url = resolveGrokPrimaryUrl(llmUrl);
    model = llmModel ?? DEFAULT_GROK_MODEL;
  } else {
    url =
      llmUrl ??
      ollamaUrl ??
      (provider === "ollama" ? DEFAULT_OLLAMA_URL : DEFAULT_OPENAI_URL);
    model =
      llmModel ??
      ollamaModel ??
      (provider === "ollama" ? DEFAULT_OLLAMA_MODEL : DEFAULT_OPENAI_MODEL);
  }

  return {
    provider,
    url,
    model,
    apiKey: resolveApiKey(provider),
  };
}

/**
 * Local LLM fallback when primary is Grok. Auto-detected from OLLAMA_* or a
 * local LLM_URL — no extra env vars required.
 */
export function getLlmFallbackConfig(): LlmConfig | null {
  const primary = getLlmConfig();
  if (primary.provider !== "grok") return null;

  const ollamaUrl = readTrimmed("OLLAMA_URL");
  const ollamaModel = readTrimmed("OLLAMA_MODEL");
  if (ollamaUrl || ollamaModel) {
    return {
      provider: "ollama",
      url: ollamaUrl ?? DEFAULT_OLLAMA_URL,
      model: ollamaModel ?? DEFAULT_OLLAMA_MODEL,
      apiKey: null,
    };
  }

  const llmUrl = readTrimmed("LLM_URL");
  if (llmUrl && isLocalLlmUrl(llmUrl)) {
    return {
      provider: "openai",
      url: llmUrl,
      model: readTrimmed("LLM_MODEL") ?? DEFAULT_OPENAI_MODEL,
      apiKey: readTrimmed("LLM_API_KEY"),
    };
  }

  return null;
}

export function getSearxngUrl(): string | null {
  return readTrimmed("SEARXNG_URL");
}

/** Bungie API key alone is enough for manifest downloads. */
export function getBungieApiKey(): string | null {
  return readTrimmed("BUNGIE_API_KEY");
}

/** Full OAuth config; null unless every value is present. */
export function getBungieOAuthConfig(): BungieOAuthConfig | null {
  const apiKey = readTrimmed("BUNGIE_API_KEY");
  const clientId = readTrimmed("BUNGIE_CLIENT_ID");
  const clientSecret = readTrimmed("BUNGIE_CLIENT_SECRET");
  if (!apiKey || !clientId || !clientSecret) return null;
  return { apiKey, clientId, clientSecret };
}

/**
 * DIM Sync API key for dim.gg loadout shares; null when not configured.
 * Self-service for localhost dev: POST https://api.destinyitemmanager.com/new_app
 */
export function getDimApiKey(): string | null {
  return readTrimmed("DIM_API_KEY");
}

export function getSessionSecret(): string | null {
  const secret = readTrimmed("SESSION_SECRET");
  if (!secret || secret.length < 32) return null;
  return secret;
}
