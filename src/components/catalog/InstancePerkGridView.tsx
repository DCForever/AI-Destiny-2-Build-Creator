"use client";

import { useEffect, useRef, useState } from "react";

import {
  Callout,
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
 * Icon-dense columns; hover/pin for name + description.
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

  const optionCount = grid.columns.reduce((n, c) => n + c.options.length, 0);

  return (
    <Stack gap={8}>
      <RowHeader
        loading={loading}
        captureStatus={grid.captureStatus}
        optionCount={optionCount}
        columnCount={grid.columns.length}
      />

      {grid.captureStatus === "pending" ? (
        <Callout tone="warning">
          Per-copy alternates pending — showing equipped only. Syncing may fill
          the full roll for this copy.
        </Callout>
      ) : null}
      {grid.captureStatus === "unavailable" ? (
        <Callout tone="warning">
          Per-copy alternates unavailable — showing equipped only. Re-sync
          inventory after playing to capture multi-perk sockets.
        </Callout>
      ) : null}

      {grid.columns.length === 0 ? (
        <Text size="xs" tone="muted">
          No perk columns for this copy.
        </Text>
      ) : (
        <div className="flex gap-2 overflow-x-auto pb-1">
          {grid.columns.map((column) => (
            <div
              key={column.socketIndex}
              className="flex flex-col gap-1.5 min-w-[2.75rem] shrink-0"
            >
              <span
                className="text-[9px] tracking-widest uppercase text-muted text-center truncate max-w-[3.5rem]"
                title={column.label}
              >
                {column.label}
              </span>
              <div className="flex flex-col gap-1 items-center">
                {column.options.map((opt) => (
                  <div
                    key={opt.hash}
                    className={`relative rounded-sm p-0.5 ${
                      opt.isEquipped
                        ? "ring-2 ring-accent ring-offset-1 ring-offset-surface"
                        : "opacity-90 hover:opacity-100"
                    }`}
                  >
                    <EntityHotspot
                      kind={column.label}
                      name={opt.displayName}
                      description={
                        opt.description?.trim() ||
                        "No description in catalog yet for this plug."
                      }
                      icon={opt.icon}
                      size={36}
                      showLabel="never"
                      meta={[
                        opt.isEquipped ? "Currently equipped" : "Available on this copy",
                        opt.isEnhanced ? "Enhanced" : null,
                      ].filter(Boolean) as string[]}
                    />
                    {opt.isEnhanced ? (
                      <span
                        className="absolute -top-0.5 -right-0.5 size-1.5 rounded-full bg-accent"
                        title="Enhanced"
                        aria-hidden
                      />
                    ) : null}
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </Stack>
  );
}

function RowHeader({
  loading,
  captureStatus,
  optionCount,
  columnCount,
}: {
  loading: boolean;
  captureStatus: string;
  optionCount: number;
  columnCount: number;
}) {
  return (
    <div className="flex flex-wrap items-baseline justify-between gap-2">
      <Text size="xs" tone="muted" className="uppercase tracking-widest">
        Per-copy perks
        {loading ? " · refreshing…" : ""}
      </Text>
      {columnCount > 0 ? (
        <Text size="xs" tone="muted">
          {optionCount} perk{optionCount === 1 ? "" : "s"} · {columnCount} col
          {columnCount === 1 ? "" : "s"}
          {captureStatus === "complete" ? "" : ` · ${captureStatus}`}
        </Text>
      ) : null}
    </div>
  );
}
