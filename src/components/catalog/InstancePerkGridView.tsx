"use client";

import { useEffect, useRef, useState } from "react";

import { WeaponStatsPanel } from "@/components/catalog/WeaponStatsPanel";
import {
  Button,
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
import type { WeaponStatLine } from "@/lib/inventory/instances/weaponStats";

type PerkGridResponse = InstancePerkGrid & {
  power?: number;
  location?: string;
  isMasterwork?: boolean;
  isCrafted?: boolean;
  stats?: WeaponStatLine[];
  intrinsic?: {
    name: string;
    description: string;
    icon: string | null;
  } | null;
  error?: string;
};

/**
 * Read-only DIM-style per-copy weapon detail: combat stats + multi-option perk columns.
 */
export function InstancePerkGridView({
  instanceId,
  enabled = true,
  /** Catalog frame name (e.g. Rapid-Fire Frame) for intrinsic strip. */
  frameHint,
}: {
  instanceId: string;
  enabled?: boolean;
  frameHint?: string | null;
}) {
  const [grid, setGrid] = useState<PerkGridResponse | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [syncBusy, setSyncBusy] = useState(false);
  const refreshRef = useRef(createPerkGridRefreshState());

  async function fetchGrid(): Promise<PerkGridResponse | null> {
    const res = await fetch(
      `/api/user/inventory/instances/${encodeURIComponent(instanceId)}/perk-grid`,
    );
    const body = (await res.json()) as PerkGridResponse;
    if (!res.ok) {
      setError(body.error ?? "Failed to load perk grid");
      setGrid(null);
      return null;
    }
    return body;
  }

  async function load(opts?: { forceSync?: boolean }) {
    if (!enabled || !instanceId) return;
    setLoading(true);
    setError(null);
    try {
      let next = await fetchGrid();
      const needSync =
        opts?.forceSync ||
        (next?.captureStatus === "pending" &&
          shouldAutoSync(refreshRef.current, instanceId));

      if (needSync) {
        setSyncBusy(true);
        refreshRef.current = markSyncAttempted(refreshRef.current, instanceId);
        try {
          await fetch("/api/bungie/sync", { method: "POST" });
        } finally {
          refreshRef.current = markSyncFinished(refreshRef.current);
          setSyncBusy(false);
        }
        next = await fetchGrid();
      }
      setGrid(next);
    } catch {
      setError("Failed to load perk grid");
      setGrid(null);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    if (!enabled || !instanceId) {
      setGrid(null);
      setError(null);
      return;
    }
    let cancelled = false;
    void (async () => {
      if (cancelled) return;
      await load();
    })();
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps -- reload only when instance changes
  }, [instanceId, enabled]);

  if (!enabled) return null;

  if (loading && !grid) {
    return (
      <Text size="xs" tone="muted">
        Loading instance detail…
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
  const rpm = grid.stats?.find((s) => s.name === "RPM")?.value;
  const impact = grid.stats?.find((s) => s.name === "Impact")?.value;
  const frameLabel =
    grid.intrinsic?.name ||
    frameHint ||
    null;
  const frameSub =
    rpm != null && impact != null
      ? `${rpm} rpm / ${impact} impact`
      : grid.intrinsic?.description?.slice(0, 80) || null;

  // Main combat sockets first (barrel/mag/traits/origin); keep others after.
  const primaryKinds = new Set([
    "barrel",
    "magazine",
    "trait",
    "origin",
    "intrinsic",
    "masterwork",
    "catalyst",
  ]);
  const mainColumns = grid.columns.filter((c) => primaryKinds.has(c.columnKind));
  const extraColumns = grid.columns.filter((c) => !primaryKinds.has(c.columnKind));
  const columns = [...mainColumns, ...extraColumns];

  return (
    <Stack gap={12}>
      <WeaponStatsPanel
        stats={grid.stats ?? []}
        frameLabel={frameLabel}
        frameSub={frameSub}
      />

      <Stack gap={8}>
        <div className="flex flex-wrap items-baseline justify-between gap-2">
          <Text size="xs" tone="muted" className="uppercase tracking-widest">
            Per-copy perks
            {loading || syncBusy ? " · refreshing…" : ""}
          </Text>
          <Text size="xs" tone="muted">
            {optionCount} option{optionCount === 1 ? "" : "s"} · {columns.length}{" "}
            col{columns.length === 1 ? "" : "s"}
            {grid.captureStatus !== "complete" ? ` · ${grid.captureStatus}` : ""}
          </Text>
        </div>

        {grid.captureStatus === "pending" ? (
          <Callout tone="warning">
            <Stack gap={6}>
              <Text size="sm">
                Full multi-perk columns need a fresh inventory sync (Bungie
                reusable plugs). Showing equipped plugs only until capture
                completes.
              </Text>
              <Button
                size="sm"
                variant="outline"
                disabled={syncBusy || loading}
                onClick={() => {
                  refreshRef.current = createPerkGridRefreshState();
                  void load({ forceSync: true });
                }}
              >
                {syncBusy ? "Syncing…" : "Sync inventory now"}
              </Button>
            </Stack>
          </Callout>
        ) : null}
        {grid.captureStatus === "unavailable" ? (
          <Callout tone="warning">
            Per-copy alternate plugs unavailable for this copy — equipped only.
          </Callout>
        ) : null}

        {columns.length === 0 ? (
          <Text size="xs" tone="muted">
            No perk columns for this copy.
          </Text>
        ) : (
          <div className="flex gap-3 overflow-x-auto pb-1">
            {columns.map((column) => (
              <div
                key={column.socketIndex}
                className="flex flex-col gap-1.5 min-w-[2.75rem] shrink-0 items-center"
              >
                <span
                  className="text-[9px] tracking-widest uppercase text-muted text-center truncate max-w-[4rem] w-full"
                  title={column.label}
                >
                  {column.label}
                </span>
                <div className="flex flex-col gap-1.5 items-center">
                  {column.options.map((opt) => (
                    <div
                      key={opt.hash}
                      className={`relative rounded-sm p-0.5 ${
                        opt.isEquipped
                          ? "ring-2 ring-accent ring-offset-1 ring-offset-surface"
                          : "opacity-85 hover:opacity-100"
                      }`}
                    >
                      <EntityHotspot
                        kind={column.label}
                        name={opt.displayName}
                        description={
                          opt.description?.trim() ||
                          "No description captured for this plug yet."
                        }
                        icon={opt.icon}
                        size={40}
                        showLabel="never"
                        meta={[
                          opt.isEquipped
                            ? "Currently equipped"
                            : "Available on this copy",
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
    </Stack>
  );
}
