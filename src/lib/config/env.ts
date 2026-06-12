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

export interface BungieOAuthConfig {
  apiKey: string;
  clientId: string;
  clientSecret: string;
}

const DEFAULT_OLLAMA_URL = "http://127.0.0.1:11434";
const DEFAULT_OLLAMA_MODEL = "gemma4";

function readTrimmed(name: string): string | null {
  const value = process.env[name]?.trim();
  return value ? value : null;
}

export function getOllamaConfig(): OllamaConfig {
  return {
    url: readTrimmed("OLLAMA_URL") ?? DEFAULT_OLLAMA_URL,
    model: readTrimmed("OLLAMA_MODEL") ?? DEFAULT_OLLAMA_MODEL,
  };
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
