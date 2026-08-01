"use client";

import { Suspense, useCallback, useState } from "react";

import { BungieAuthControl, type AuthStatus } from "@/components/BungieAuthControl";
import { InventorySyncCard } from "@/components/settings/InventorySyncCard";
import { ManifestCard } from "./ManifestCard";
import { StatusCard } from "./StatusCard";
import {
  Callout,
  Cluster,
  FilterChip,
  PageFrame,
  PageFrameBody,
  PageFrameChrome,
  PageHeader,
  Panel,
  SectionLabel,
  Stack,
  Text,
} from "@/components/ui";
import type { UserPreferences } from "@/lib/preferences/types";

const BUNGIE_ENV_HINT =
  "Set BUNGIE_API_KEY, BUNGIE_CLIENT_ID, BUNGIE_CLIENT_SECRET, SESSION_SECRET in .env.local";

const CLASSES = ["Titan", "Hunter", "Warlock"] as const;

async function loadLlmStatus(): Promise<{ ok: boolean; lines: string[] }> {
  const res = await fetch("/api/llm");
  const body: unknown = await res.json();
  const record =
    typeof body === "object" && body !== null
      ? (body as Record<string, unknown>)
      : {};
  const healthy = record.healthy === true;
  const lines: string[] = ["Product generate path is retired — status for local tooling only."];
  if (typeof record.provider === "string") lines.push(`provider: ${record.provider}`);
  if (typeof record.active === "string" && record.active !== "primary") {
    lines.push(`active: ${record.active}`);
  }
  if (typeof record.detail === "string") lines.push(record.detail);
  const fallback =
    typeof record.fallback === "object" && record.fallback !== null
      ? (record.fallback as Record<string, unknown>)
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
  const record =
    typeof body === "object" && body !== null
      ? (body as Record<string, unknown>)
      : {};
  return {
    ok: record.healthy === true,
    lines: typeof record.detail === "string" ? [record.detail] : [],
  };
}

async function loadBungieStatus(): Promise<{ ok: boolean; lines: string[] }> {
  const res = await fetch("/api/auth/status");
  const body: unknown = await res.json();
  const record =
    typeof body === "object" && body !== null
      ? (body as Record<string, unknown>)
      : {};

  if (res.status === 503) {
    const message =
      typeof record.error === "string" ? record.error : BUNGIE_ENV_HINT;
    return { ok: false, lines: [message] };
  }

  if (!res.ok) {
    const message =
      typeof record.error === "string"
        ? record.error
        : "Could not check Bungie sign-in status";
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
      const body = (await res.json()) as { error?: string };
      setPrefsError(body.error ?? "Failed to load preferences");
      return;
    }
    const body = (await res.json()) as { preferences: UserPreferences };
    setPrefs(body.preferences);
  }, []);

  const handleAuthChange = useCallback(
    (auth: AuthStatus) => {
      setSignedIn(auth.signedIn);
      if (auth.signedIn) {
        void loadPreferences();
      } else {
        setPrefs(null);
      }
    },
    [loadPreferences],
  );

  const saveDefaultClass = async (
    defaultClass: UserPreferences["defaultClass"],
  ) => {
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
        const body = (await res.json()) as { error?: string };
        setPrefsError(body.error ?? "Failed to save preferences");
        return;
      }
      const body = (await res.json()) as { preferences: UserPreferences };
      setPrefs(body.preferences);
      setPrefsSaved(true);
    } catch {
      setPrefsError("Failed to save preferences");
    } finally {
      setSaving(false);
    }
  };

  return (
    <PageFrame width="narrow">
      <PageFrameChrome>
        <PageHeader
          title="Settings"
          description="Account, manifest, inventory sync, and service status. Manifest is required; inventory sync powers Catalog and owned pickers."
        />
      </PageFrameChrome>
      <PageFrameBody scroll>
        <Stack gap={16}>
          <Panel tone="raised" pad="md">
            <Stack gap={12}>
              <SectionLabel>Account</SectionLabel>
              <Suspense
                fallback={
                  <Text size="xs" tone="muted">
                    Loading sign-in…
                  </Text>
                }
              >
                <BungieAuthControl onAuthChange={handleAuthChange} />
              </Suspense>
              {signedIn ? (
                <Stack gap={8}>
                  <Text size="xs" tone="muted">
                    Default guardian class
                  </Text>
                  <Cluster gap={6}>
                    {CLASSES.map((cls) => (
                      <FilterChip
                        key={cls}
                        label={cls}
                        active={prefs?.defaultClass === cls}
                        onClick={() => void saveDefaultClass(cls)}
                        disabled={saving}
                      />
                    ))}
                  </Cluster>
                  {prefsSaved ? (
                    <Text size="xs" tone="muted">
                      Preferences saved.
                    </Text>
                  ) : null}
                  {prefsError ? (
                    <Callout tone="danger">{prefsError}</Callout>
                  ) : null}
                </Stack>
              ) : (
                <Text size="sm" tone="muted">
                  Sign in to set your default guardian class.
                </Text>
              )}
            </Stack>
          </Panel>

          <ManifestCard signedIn={signedIn} />

          <InventorySyncCard signedIn={signedIn} />

          <StatusCard
            title="Bungie API"
            description="OAuth for inventory, in-game loadouts, and Apply to character."
            load={loadBungieStatus}
          />

          <StatusCard
            title="Local LLM"
            description="Retired from product IA. Optional status for local tooling only."
            load={loadLlmStatus}
          />

          <StatusCard
            title="SearXNG"
            description="Optional web search helper. Pipeline works without it."
            load={loadSearxngStatus}
          />
        </Stack>
      </PageFrameBody>
    </PageFrame>
  );
}
