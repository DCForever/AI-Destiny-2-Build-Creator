"use client";

import { useEffect, useRef, useState } from "react";

import {
  Callout,
  Cluster,
  EntityHotspot,
  Stack,
  Text,
} from "@/components/ui";
import {
  createPerkGridRefreshState,
  markSyncAttempted,
  markSyncFinished,
  shouldAutoSync,
} from "@/lib/inventory/instances/perkGridRefresh";
import type { InstancePerkGrid } from "@/lib/inventory/instances/types";

/**
 * Read-only DIM-style per-copy weapon perk grid (011).
 * Loads GET .../instances/:id/perk-grid; auto re-sync once when captureStatus is pending.
 */
export function InstancePerkGridView({
  instanceId,
  /** When false, do not fetch (e.g. armor copies). */
  enabled = true,
}: {
  instanceId: string;
  enabled?: boolean;
}) {
  const [grid, setGrid] = useState<InstancePerkGrid | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const refreshRef = useRef(createPerkGridRefreshState());

  useEffect(() => {
    if (!enabled || !instanceId) {
      setGrid(null);
      setError(null);
      return;
    }

    let cancelled = false;

    async function load() {
      setLoading(true);
      setError(null);

      async function fetchGrid(): Promise<InstancePerkGrid | null> {
        const res = await fetch(
          `/api/user/inventory/instances/${encodeURIComponent(instanceId)}/perk-grid`,
        );
        const body = (await res.json()) as InstancePerkGrid & { error?: string };
        if (!res.ok) {
          if (!cancelled) {
            setError(body.error ?? "Failed to load perk grid");
            setGrid(null);
          }
          return null;
        }
        return body;
      }

      try {
        let next = await fetchGrid();
        if (
          next?.captureStatus === "pending" &&
          shouldAutoSync(refreshRef.current, instanceId)
        ) {
          refreshRef.current = markSyncAttempted(refreshRef.current, instanceId);
          try {
            await fetch("/api/bungie/sync", { method: "POST" });
          } finally {
            refreshRef.current = markSyncFinished(refreshRef.current);
          }
          if (!cancelled) next = await fetchGrid();
        }
        if (!cancelled) setGrid(next);
      } catch {
        if (!cancelled) {
          setError("Failed to load perk grid");
          setGrid(null);
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    void load();
    return () => {
      cancelled = true;
    };
  }, [instanceId, enabled]);

  if (!enabled) return null;

  if (loading && !grid) {
    return (
      <Text size="xs" tone="muted">
        Loading perk grid…
      </Text>
    );
  }

  if (error) {
    return (
      <Text size="xs" tone="danger">
        {error}
      </Text>
    );
  }

  if (!grid) return null;

  return (
    <Stack gap={8}>
      <Text size="xs" tone="muted" className="uppercase tracking-widest">
        Per-copy perks
        {loading ? " · refreshing…" : ""}
      </Text>

      {grid.captureStatus === "pending" ? (
        <Callout tone="warning">
          Per-copy alternates pending — showing equipped only (FR-015/018).
        </Callout>
      ) : null}
      {grid.captureStatus === "unavailable" ? (
        <Callout tone="warning">
          Per-copy alternates unavailable — showing equipped only.
        </Callout>
      ) : null}

      {grid.columns.length === 0 ? (
        <Text size="xs" tone="muted">
          No perk columns for this copy.
        </Text>
      ) : (
        <div className="flex gap-3 overflow-x-auto pb-1">
          {grid.columns.map((column) => (
            <Stack
              key={column.socketIndex}
              gap={6}
              className="min-w-[7.5rem] max-w-[10rem] shrink-0"
            >
              <span title={column.label}>
                <Text
                  size="xs"
                  tone="muted"
                  className="uppercase tracking-widest truncate"
                >
                  {column.label}
                </Text>
              </span>
              <Stack gap={4}>
                {column.options.map((opt) => (
                  <div
                    key={opt.hash}
                    className={`rounded-sm border p-1 ${
                      opt.isEquipped
                        ? "border-accent bg-accent/10"
                        : "border-line bg-surface"
                    }`}
                  >
                    <EntityHotspot
                      kind={column.label}
                      name={opt.displayName}
                      description={opt.description}
                      icon={opt.icon}
                      size={28}
                      showLabel="auto"
                      meta={[
                        opt.isEquipped ? "Equipped" : null,
                        opt.isEnhanced ? "Enhanced" : null,
                        `Hash ${opt.hash}`,
                      ].filter(Boolean) as string[]}
                    />
                    {opt.isEquipped ? (
                      <Text
                        size="xs"
                        tone="accent"
                        className="mt-0.5 block text-[9px] tracking-widest uppercase"
                      >
                        Equipped
                      </Text>
                    ) : null}
                  </div>
                ))}
              </Stack>
            </Stack>
          ))}
        </div>
      )}

      {grid.captureStatus === "complete" ? (
        <Cluster gap={4}>
          <Text size="xs" tone="muted">
            {grid.columns.reduce((n, c) => n + c.options.length, 0)} options ·{" "}
            {grid.columns.length} columns
          </Text>
        </Cluster>
      ) : null}
    </Stack>
  );
}
