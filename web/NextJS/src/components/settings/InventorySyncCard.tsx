"use client";

import { useCallback, useEffect, useState } from "react";

import {
  Button,
  Callout,
  Chip,
  Panel,
  Row,
  SectionLabel,
  Stack,
  Text,
} from "@/components/ui";
import type { ImprovementSuggestion } from "@/lib/optimizer/improvementSuggestions";
import {
  inventorySyncSummary,
  type InventorySyncStatus,
} from "@/lib/settings/formatInventorySync";

function Spinner() {
  return (
    <span
      className="inline-block size-3 border border-line border-t-accent rounded-full animate-spin"
      aria-hidden="true"
    />
  );
}

export function InventorySyncCard({ signedIn }: { signedIn: boolean }) {
  const [status, setStatus] = useState<InventorySyncStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [suggestions, setSuggestions] = useState<ImprovementSuggestion[]>([]);

  const loadStatus = useCallback(async (): Promise<InventorySyncStatus | null> => {
    if (!signedIn) return null;
    const res = await fetch("/api/bungie/inventory/status");
    if (res.status === 401) return null;
    if (!res.ok) {
      const body = (await res.json()) as { error?: string };
      throw new Error(body.error ?? "Could not load inventory status");
    }
    return (await res.json()) as InventorySyncStatus;
  }, [signedIn]);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      setLoading(true);
      setError(null);
      try {
        if (!signedIn) {
          if (!cancelled) setStatus(null);
          return;
        }
        const next = await loadStatus();
        if (cancelled) return;
        setStatus(next);
      } catch (err) {
        if (cancelled) return;
        setStatus(null);
        setError(err instanceof Error ? err.message : "Could not load inventory status");
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [signedIn, loadStatus]);

  /** Soft, suggest-then-confirm check after a successful sync — never auto-applies (BR-OPT-004). */
  async function fetchPostSyncSuggestions() {
    try {
      const res = await fetch("/api/user/armor/improvement-suggestions?afterSync=1");
      if (!res.ok) return;
      const body = (await res.json()) as { suggestions?: ImprovementSuggestion[] };
      setSuggestions(body.suggestions ?? []);
    } catch {
      // Soft suggestions are best-effort; ignore failures.
    }
  }

  async function confirmSuggestion(suggestion: ImprovementSuggestion) {
    const combo = suggestion.betterCombination;
    if (!combo) return;
    const payload: Record<string, unknown> = {
      pieces: combo.pieces.map((p) => ({ slot: p.slot, itemHash: p.itemHash, instanceId: p.instanceId })),
    };
    if (combo.assumedMods.length) {
      payload.assumedMods = combo.assumedMods.map((m) => ({ armorSlot: m.armorSlot, itemHash: m.itemHash }));
    }
    try {
      const res = await fetch(`/api/user/sets/${suggestion.armorSetId}/apply-combination`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      if (res.ok) {
        setSuggestions((prev) => prev.filter((s) => s.armorSetId !== suggestion.armorSetId));
      }
    } catch {
      // Leave the suggestion visible so the user can retry.
    }
  }

  function dismissSuggestion(armorSetId: string) {
    setSuggestions((prev) => prev.filter((s) => s.armorSetId !== armorSetId));
  }

  async function runSync() {
    setSyncing(true);
    setError(null);
    setMessage(null);
    try {
      const res = await fetch("/api/bungie/sync", { method: "POST" });
      const body = (await res.json()) as {
        error?: string;
        itemCount?: number;
      };
      if (!res.ok) {
        setError(body.error ?? "Inventory sync failed");
        return;
      }
      setMessage(
        typeof body.itemCount === "number"
          ? `Synced ${body.itemCount} items.`
          : "Inventory sync complete.",
      );
      setLoading(true);
      try {
        const next = await loadStatus();
        setStatus(next);
      } finally {
        setLoading(false);
      }
      void fetchPostSyncSuggestions();
    } catch {
      setError("Inventory sync failed");
    } finally {
      setSyncing(false);
    }
  }

  const summary = inventorySyncSummary(status);
  const showSpinner = loading || syncing;

  return (
    <Panel tone="raised" pad="md">
      <Stack gap={12}>
        <Row justify="between" align="center" gap={8} wrap>
          <SectionLabel>Inventory sync</SectionLabel>
          {showSpinner ? (
            <span className="flex items-center gap-2 text-xs text-muted">
              <Spinner />
              {syncing ? "Syncing…" : "Checking…"}
            </span>
          ) : (
            <Chip accent={summary.hasSynced}>
              {summary.hasSynced ? "ONLINE" : "OFFLINE"}
            </Chip>
          )}
        </Row>

        <Text size="sm" tone="muted">
          Powers Owned catalog scope, instance pickers, and In-Game Loadouts.
        </Text>

        {!signedIn ? (
          <Text size="sm" tone="muted">
            Sign in with Bungie to sync inventory.
          </Text>
        ) : (
          <Stack gap={6}>
            <Row justify="between" gap={8}>
              <Text size="xs" tone="muted">
                Last sync
              </Text>
              <Text size="sm" weight="medium">
                {summary.lastSyncLabel}
              </Text>
            </Row>
            <Row justify="between" gap={8}>
              <Text size="xs" tone="muted">
                Owned instances
              </Text>
              <Text size="sm" weight="medium">
                {summary.itemCountLabel}
              </Text>
            </Row>
            {status?.syncVersion != null && summary.hasSynced ? (
              <Row justify="between" gap={8}>
                <Text size="xs" tone="muted">
                  Sync version
                </Text>
                <Text size="sm" weight="medium">
                  {status.syncVersion}
                </Text>
              </Row>
            ) : null}
          </Stack>
        )}

        {syncing ? (
          <Callout tone="info">
            Inventory sync in progress — this can take a minute on first run.
          </Callout>
        ) : null}
        {error ? <Callout tone="danger">{error}</Callout> : null}
        {message ? <Callout tone="success">{message}</Callout> : null}
        {suggestions.length > 0 ? (
          <Callout tone="info" title="Better armor kits found">
            <Stack gap={8}>
              {suggestions.map((suggestion) => (
                <Row key={suggestion.armorSetId} justify="between" align="center" gap={8} wrap>
                  <Text size="sm">{suggestion.armorSetName}</Text>
                  <Row gap={6}>
                    <Button size="sm" variant="accent" onClick={() => void confirmSuggestion(suggestion)}>
                      Confirm
                    </Button>
                    <Button size="sm" variant="ghost" onClick={() => dismissSuggestion(suggestion.armorSetId)}>
                      Dismiss
                    </Button>
                  </Row>
                </Row>
              ))}
            </Stack>
          </Callout>
        ) : null}

        <Row gap={8}>
          <Button
            size="sm"
            variant="accent"
            disabled={!signedIn || syncing}
            onClick={() => void runSync()}
          >
            {syncing ? "Syncing…" : "Sync inventory"}
          </Button>
          <Button
            size="sm"
            variant="ghost"
            disabled={!signedIn || syncing || loading}
            onClick={() => {
              void (async () => {
                setLoading(true);
                setError(null);
                try {
                  setStatus(await loadStatus());
                } catch (err) {
                  setError(
                    err instanceof Error
                      ? err.message
                      : "Could not load inventory status",
                  );
                } finally {
                  setLoading(false);
                }
              })();
            }}
          >
            Refresh status
          </Button>
        </Row>
      </Stack>
    </Panel>
  );
}
