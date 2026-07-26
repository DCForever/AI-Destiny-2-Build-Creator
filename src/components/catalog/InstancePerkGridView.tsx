"use client";

import { memo, useEffect, useRef, useState } from "react";

import { WeaponStatsPanel } from "@/components/catalog/WeaponStatsPanel";
import {
  Button,
  Callout,
  EntityHotspot,
  Stack,
  Text,
} from "@/components/ui";
import {
  fetchPerkGridDeduped,
  getCachedPerkGrid,
  runSharedInventorySync,
} from "@/lib/inventory/instances/perkGridClientCache";
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
export const InstancePerkGridView = memo(function InstancePerkGridView({
  instanceId,
  enabled = true,
  frameHint,
}: {
  instanceId: string;
  enabled?: boolean;
  frameHint?: string | null;
}) {
  const [grid, setGrid] = useState<PerkGridResponse | null>(() =>
    instanceId ? getCachedPerkGrid<PerkGridResponse>(instanceId) : null,
  );
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [syncBusy, setSyncBusy] = useState(false);
  const refreshRef = useRef(createPerkGridRefreshState());
  const loadGenRef = useRef(0);

  async function load(opts?: { forceSync?: boolean; forceFetch?: boolean }) {
    if (!enabled || !instanceId) return;
    const gen = ++loadGenRef.current;
    const hasWarm = Boolean(getCachedPerkGrid(instanceId) || grid);
    if (!hasWarm) setLoading(true);
    setError(null);
    try {
      let next = await fetchPerkGridDeduped<PerkGridResponse>(instanceId, {
        force: opts?.forceFetch || opts?.forceSync,
      });
      if (gen !== loadGenRef.current) return;

      const needSync =
        opts?.forceSync ||
        (next?.captureStatus === "pending" &&
          shouldAutoSync(refreshRef.current, instanceId));

      if (needSync) {
        setSyncBusy(true);
        refreshRef.current = markSyncAttempted(refreshRef.current, instanceId);
        try {
          await runSharedInventorySync({ force: Boolean(opts?.forceSync) });
        } finally {
          refreshRef.current = markSyncFinished(refreshRef.current);
          if (gen === loadGenRef.current) setSyncBusy(false);
        }
        if (gen !== loadGenRef.current) return;
        next = await fetchPerkGridDeduped<PerkGridResponse>(instanceId, {
          force: true,
        });
      }
      if (gen === loadGenRef.current) setGrid(next);
    } catch (e) {
      if (gen === loadGenRef.current) {
        if (e instanceof DOMException && e.name === "AbortError") return;
        setError(e instanceof Error ? e.message : "Failed to load perk grid");
        if (!grid) setGrid(null);
      }
    } finally {
      if (gen === loadGenRef.current) setLoading(false);
    }
  }

  useEffect(() => {
    if (!enabled || !instanceId) {
      setGrid(null);
      setError(null);
      return;
    }
    const warm = getCachedPerkGrid<PerkGridResponse>(instanceId);
    if (warm) setGrid(warm);
    void load();
    return () => {
      loadGenRef.current += 1;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
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
      <Stack gap={6}>
        <Text size="xs" tone="danger">
          {error}
        </Text>
        <Button size="sm" variant="outline" onClick={() => void load({ forceSync: true })}>
          Retry / sync
        </Button>
      </Stack>
    );
  }

  if (!grid) return null;

  const optionCount = grid.columns.reduce((n, c) => n + c.options.length, 0);
  const rpm = grid.stats?.find((s) => s.name === "RPM")?.value;
  const impact = grid.stats?.find((s) => s.name === "Impact")?.value;
  const frameLabel = grid.intrinsic?.name || frameHint || null;
  const frameSub =
    rpm != null && impact != null
      ? `${rpm} rpm / ${impact} impact`
      : grid.intrinsic?.description?.slice(0, 80) || null;

  // Combat sockets first; de-emphasize trackers / orphan masterworks.
  const primaryKinds = new Set([
    "intrinsic",
    "barrel",
    "magazine",
    "trait",
    "origin",
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
            {grid.captureStatus === "complete" ? " · complete" : ` · ${grid.captureStatus}`}
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

        {grid.captureStatus === "complete" && optionCount > columns.length ? (
          <Text size="xs" tone="muted">
            Columns with multiple icons are perks this copy can switch between
            (equipped ring). Hover any icon for name and description.
          </Text>
        ) : null}

        {columns.length === 0 ? (
          <Text size="xs" tone="muted">
            No perk columns for this copy.
          </Text>
        ) : (
          <div className="flex gap-4 overflow-x-auto pb-2 items-start">
            {columns.map((column) => (
              <div
                key={column.socketIndex}
                className="flex flex-col gap-1.5 shrink-0 items-center min-w-[3rem]"
              >
                <div className="text-center w-full">
                  <div
                    className="text-[9px] tracking-widest uppercase text-muted truncate max-w-[4.5rem] mx-auto"
                    title={column.label}
                  >
                    {column.label}
                  </div>
                  {column.options.length > 1 ? (
                    <div className="text-[9px] text-accent tabular-nums">
                      ×{column.options.length}
                    </div>
                  ) : null}
                </div>
                <div className="flex flex-col gap-0 items-center">
                  {column.options.map((opt, i) => (
                    <div key={opt.hash} className="flex flex-col items-center">
                      {i > 0 ? (
                        <span
                          className="text-accent text-[10px] leading-none py-0.5"
                          aria-hidden
                        >
                          ▴
                        </span>
                      ) : null}
                      <div
                        className={`relative rounded-sm p-0.5 ${
                          opt.isEquipped
                            ? "ring-2 ring-accent ring-offset-1 ring-offset-surface"
                            : "opacity-80 hover:opacity-100"
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
                      </div>
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
});
