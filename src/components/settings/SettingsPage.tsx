"use client";

import { ManifestCard } from "./ManifestCard";
import { StatusCard } from "./StatusCard";

const BUNGIE_ENV_HINT =
  "Set BUNGIE_API_KEY, BUNGIE_CLIENT_ID, BUNGIE_CLIENT_SECRET, SESSION_SECRET in .env.local";

async function loadLlmStatus(): Promise<{ ok: boolean; lines: string[] }> {
  const res = await fetch("/api/llm");
  const body: unknown = await res.json();
  const record = typeof body === "object" && body !== null ? body as Record<string, unknown> : {};
  const healthy = record.healthy === true;
  const lines: string[] = [];
  if (typeof record.provider === "string") lines.push(`provider: ${record.provider}`);
  if (typeof record.active === "string" && record.active !== "primary") {
    lines.push(`active: ${record.active}`);
  }
  if (typeof record.detail === "string") lines.push(record.detail);
  const fallback =
    typeof record.fallback === "object" && record.fallback !== null
      ? record.fallback as Record<string, unknown>
      : null;
  if (fallback && typeof fallback.provider === "string") {
    const fbHealthy = fallback.healthy === true ? "healthy" : "unavailable";
    lines.push(`fallback (${fallback.provider}): ${fbHealthy}`);
    if (typeof fallback.detail === "string") lines.push(fallback.detail);
  }
  if (Array.isArray(record.models) && record.models.length > 0) {
    const models = record.models.filter((m): m is string => typeof m === "string");
    if (models.length > 0) lines.push(`models: ${models.join(", ")}`);
  }
  return { ok: healthy, lines };
}

async function loadSearxngStatus(): Promise<{ ok: boolean; lines: string[] }> {
  const res = await fetch("/api/search");
  const body: unknown = await res.json();
  const record = typeof body === "object" && body !== null ? body as Record<string, unknown> : {};
  return {
    ok: record.healthy === true,
    lines: typeof record.detail === "string" ? [record.detail] : [],
  };
}

async function loadBungieStatus(): Promise<{ ok: boolean; lines: string[] }> {
  const res = await fetch("/api/auth/status");
  const body: unknown = await res.json();
  const record = typeof body === "object" && body !== null ? body as Record<string, unknown> : {};

  if (res.status === 503) {
    const message =
      typeof record.error === "string" ? record.error : BUNGIE_ENV_HINT;
    return { ok: false, lines: [message] };
  }

  if (!res.ok) {
    const message =
      typeof record.error === "string" ? record.error : "Could not check Bungie sign-in status";
    return { ok: false, lines: [message] };
  }

  const configured = record.configured === true;
  const signedIn = record.signedIn === true;
  const lines = [`signed in: ${signedIn ? "yes" : "no"}`];
  if (typeof record.bungieMembershipId === "string") {
    lines.push(`membership id: ${record.bungieMembershipId}`);
  }
  return { ok: configured, lines };
}

export function SettingsPage() {
  return (
    <div className="flex-1 max-w-3xl mx-auto p-6 space-y-6">
      <div>
        <h1 className="text-lg text-foreground mb-2">Settings</h1>
        <p className="text-sm text-muted leading-relaxed">
          Service status for the local toolchain. The app degrades gracefully: only the manifest
          is required to generate builds.
        </p>
      </div>

      <ManifestCard />

      <StatusCard
        title="Local LLM"
        description="Generates and analyzes builds. Set LLM_PROVIDER (openai, ollama, or grok). With grok, OLLAMA_* or a local LLM_URL auto-configures a fallback when Grok is unavailable."
        load={loadLlmStatus}
      />

      <StatusCard
        title="SearXNG"
        description="Optional web search for meta-checking. The pipeline works without it. Configure with SEARXNG_URL."
        load={loadSearxngStatus}
      />

      <StatusCard
        title="Bungie Sign-in"
        description="Optional OAuth sign-in used by the Analyzer to import your equipped loadout."
        load={loadBungieStatus}
      />
    </div>
  );
}
