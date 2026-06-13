"use client";

import { Suspense, useCallback, useState } from "react";
import { BungieAuthControl, type AuthStatus } from "@/components/BungieAuthControl";
import { ManifestCard } from "./ManifestCard";
import { StatusCard } from "./StatusCard";
import type { UserPreferences } from "@/lib/preferences/types";

const BUNGIE_ENV_HINT =
  "Set BUNGIE_API_KEY, BUNGIE_CLIENT_ID, BUNGIE_CLIENT_SECRET, SESSION_SECRET in .env.local";

const CLASSES = ["Titan", "Hunter", "Warlock"] as const;

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

function fieldLabel(text: string) {
  return (
    <span className="text-[11px] tracking-widest uppercase text-muted">{text}</span>
  );
}

export function SettingsPage() {
  const [signedIn, setSignedIn] = useState(false);
  const [prefs, setPrefs] = useState<UserPreferences | null>(null);
  const [saving, setSaving] = useState(false);
  const [prefsError, setPrefsError] = useState<string | null>(null);
  const [prefsSaved, setPrefsSaved] = useState(false);

  const loadPreferences = useCallback(async () => {
    setPrefsError(null);
    const res = await fetch("/api/user/preferences");
    if (res.status === 401) {
      setPrefs(null);
      return;
    }
    if (!res.ok) {
      const body = await res.json() as { error?: string };
      setPrefsError(body.error ?? "Failed to load preferences");
      return;
    }
    const body = await res.json() as { preferences: UserPreferences };
    setPrefs(body.preferences);
  }, []);

  const handleAuthChange = useCallback((auth: AuthStatus) => {
    setSignedIn(auth.signedIn);
    if (auth.signedIn) {
      void loadPreferences();
    } else {
      setPrefs(null);
    }
  }, [loadPreferences]);

  const saveDefaultClass = async (defaultClass: UserPreferences["defaultClass"]) => {
    if (!signedIn) return;
    setSaving(true);
    setPrefsError(null);
    setPrefsSaved(false);
    try {
      const res = await fetch("/api/user/preferences", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ defaultClass }),
      });
      if (!res.ok) {
        const body = await res.json() as { error?: string };
        setPrefsError(body.error ?? "Failed to save preferences");
        return;
      }
      const body = await res.json() as { preferences: UserPreferences };
      setPrefs(body.preferences);
      setPrefsSaved(true);
    } catch {
      setPrefsError("Failed to save preferences");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="flex-1 max-w-3xl mx-auto p-6 space-y-6">
      <div>
        <h1 className="text-lg text-foreground mb-2">Settings</h1>
        <p className="text-sm text-muted leading-relaxed">
          Service status for the local toolchain. The app degrades gracefully: only the manifest
          is required to generate builds.
        </p>
      </div>

      <div className="panel-notch p-5 space-y-4">
        <div className="text-[11px] tracking-widest uppercase text-muted">Account</div>
        <Suspense fallback={<p className="text-xs text-muted">Loading sign-in…</p>}>
          <BungieAuthControl onAuthChange={handleAuthChange} />
        </Suspense>
        {signedIn && (
          <div className="space-y-2">
            <div>{fieldLabel("Default Guardian Class")}</div>
            <div className="flex gap-0 border border-line">
              {CLASSES.map((cls) => (
                <button
                  key={cls}
                  type="button"
                  disabled={saving}
                  onClick={() => void saveDefaultClass(cls)}
                  className={`flex-1 py-2 text-xs tracking-widest uppercase transition-colors focus-visible:outline-accent disabled:opacity-50 ${
                    prefs?.defaultClass === cls
                      ? "bg-accent text-background font-semibold"
                      : "text-muted hover:text-foreground"
                  }`}
                >
                  {cls}
                </button>
              ))}
            </div>
            {prefsSaved && <p className="text-xs text-muted">Preferences saved.</p>}
            {prefsError && <p className="text-xs text-danger">{prefsError}</p>}
          </div>
        )}
        {!signedIn && (
          <p className="text-xs text-muted">Sign in to set your default guardian class.</p>
        )}
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
