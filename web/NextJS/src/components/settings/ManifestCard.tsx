"use client";

import { useCallback, useEffect, useState } from "react";

import { Badge, type BadgeTone } from "@/components/ui";

interface ManifestStatus {
  cachedVersion: string | null;
  remoteVersion: string | null;
  isStale: boolean;
  entityCache: {
    manifestVersion: string;
    builtAt: string;
    counts: Record<string, number>;
  } | null;
}

function Spinner() {
  return (
    <span
      className="inline-block size-3 border border-line border-t-accent rounded-full animate-spin"
      aria-hidden="true"
    />
  );
}

function parseManifestStatus(value: unknown): ManifestStatus | null {
  if (typeof value !== "object" || value === null) return null;
  const record = value as Record<string, unknown>;
  if ("error" in record && typeof record.error === "string") return null;

  const cachedVersion =
    record.cachedVersion === null || typeof record.cachedVersion === "string"
      ? record.cachedVersion
      : null;
  const remoteVersion =
    record.remoteVersion === null || typeof record.remoteVersion === "string"
      ? record.remoteVersion
      : null;
  const isStale = record.isStale === true;

  let entityCache: ManifestStatus["entityCache"] = null;
  if (typeof record.entityCache === "object" && record.entityCache !== null) {
    const cache = record.entityCache as Record<string, unknown>;
    if (
      typeof cache.manifestVersion === "string" &&
      typeof cache.builtAt === "string" &&
      typeof cache.counts === "object" &&
      cache.counts !== null
    ) {
      entityCache = {
        manifestVersion: cache.manifestVersion,
        builtAt: cache.builtAt,
        counts: cache.counts as Record<string, number>,
      };
    }
  }

  return { cachedVersion, remoteVersion, isStale, entityCache };
}

function manifestBadge(status: ManifestStatus | null): {
  label: string;
  tone: BadgeTone;
} {
  if (!status?.cachedVersion) {
    return { label: "NOT DOWNLOADED", tone: "unresolved" };
  }
  if (status.isStale) {
    return { label: "STALE", tone: "fuzzy" };
  }
  if (status.entityCache) {
    return { label: "READY", tone: "verified" };
  }
  return { label: "STALE", tone: "fuzzy" };
}

async function fetchManifestStatus(): Promise<{
  status: ManifestStatus | null;
  error?: string;
}> {
  const res = await fetch("/api/manifest");
  const body: unknown = await res.json();
  if (!res.ok) {
    const record = typeof body === "object" && body !== null ? body as Record<string, unknown> : {};
    const message = typeof record.error === "string" ? record.error : "Manifest status failed";
    return { status: null, error: message };
  }
  const status = parseManifestStatus(body);
  if (!status) {
    return { status: null, error: "Invalid manifest status response" };
  }
  return { status };
}

import type { InventoryParseDiagnostics } from "@/lib/bungie/types";

interface InventorySyncResult {
  itemCount: number;
  lastFullSyncAt: string;
  diagnostics?: InventoryParseDiagnostics;
}

function parseInventorySyncResult(value: unknown): InventorySyncResult | null {
  if (typeof value !== "object" || value === null) return null;
  const record = value as Record<string, unknown>;
  if (typeof record.itemCount !== "number" || typeof record.lastFullSyncAt !== "string") {
    return null;
  }
  const diagnostics =
    typeof record.diagnostics === "object" && record.diagnostics !== null
      ? (record.diagnostics as InventoryParseDiagnostics)
      : undefined;
  return { itemCount: record.itemCount, lastFullSyncAt: record.lastFullSyncAt, diagnostics };
}

function formatSyncDiagnostics(diagnostics: InventoryParseDiagnostics): string {
  const lines = [
    `Bungie raw items: ${diagnostics.raw.total.toLocaleString()}`,
    `Parsed from Bungie: ${diagnostics.parsed.total.toLocaleString()} (${diagnostics.parsed.equipmentTotal.toLocaleString()} weapons/armor incl. vault containers, ${diagnostics.parsed.subclassTotal} subclasses)`,
    `Dropped: ${diagnostics.dropped.total.toLocaleString()} (unknown bucket: ${diagnostics.dropped.unknownBucket}, missing instance id: ${diagnostics.dropped.missingInstanceId})`,
  ];
  if (diagnostics.resolution) {
    lines.push(
      `Stored after resolution: ${diagnostics.resolution.storedTotal.toLocaleString()} (${diagnostics.resolution.storedEquipment.toLocaleString()} weapons/armor; ${diagnostics.resolution.resolvedFromTransfer.toLocaleString()} from vault/postmaster, ${diagnostics.resolution.droppedNonEquipment.toLocaleString()} non-equipment dropped)`,
    );
  }
  if (diagnostics.manifest) {
    lines.push(
      `Manifest match: ${diagnostics.manifest.inWeaponsCatalog} weapons, ${diagnostics.manifest.inExoticArmorCatalog} exotic armor, ${diagnostics.manifest.unmatchedEquipmentHashes} unmatched hashes`,
    );
  }
  const unknownBuckets = Object.entries(diagnostics.dropped.unknownBuckets)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 8)
    .map(([hash, count]) => `  bucket ${hash}: ${count}`)
    .join("\n");
  if (unknownBuckets) {
    lines.push("Top unknown buckets:\n" + unknownBuckets);
  }
  return lines.join("\n");
}

async function syncInventoryAfterManifest(): Promise<{
  result: InventorySyncResult | null;
  error?: string;
}> {
  const res = await fetch("/api/bungie/sync", { method: "POST" });
  const body: unknown = await res.json();
  if (!res.ok) {
    const record = typeof body === "object" && body !== null ? (body as Record<string, unknown>) : {};
    const message = typeof record.error === "string" ? record.error : "Inventory sync failed";
    return { result: null, error: message };
  }
  const result = parseInventorySyncResult(body);
  if (!result) {
    return { result: null, error: "Invalid inventory sync response" };
  }
  return { result };
}

interface ManifestCardProps {
  /** When true, inventory sync runs automatically after a successful manifest refresh. */
  signedIn?: boolean;
}

export function ManifestCard({ signedIn = false }: ManifestCardProps) {
  const [loading, setLoading] = useState(true);
  const [status, setStatus] = useState<ManifestStatus | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState(false);
  const [refreshError, setRefreshError] = useState<string | null>(null);
  const [syncMessage, setSyncMessage] = useState<string | null>(null);
  const [syncDiagnostics, setSyncDiagnostics] = useState<InventoryParseDiagnostics | null>(null);
  const [syncWarning, setSyncWarning] = useState<string | null>(null);
  const [refreshPhase, setRefreshPhase] = useState<"manifest" | "inventory" | null>(null);

  const applyResult = useCallback((result: { status: ManifestStatus | null; error?: string }) => {
    if (result.status) {
      setStatus(result.status);
      setLoadError(null);
      return;
    }
    setLoadError(result.error ?? "Manifest status failed");
  }, []);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      setLoading(true);
      setLoadError(null);
      try {
        const result = await fetchManifestStatus();
        if (cancelled) return;
        applyResult(result);
      } catch (err) {
        if (cancelled) return;
        const message = err instanceof Error ? err.message : "Manifest status failed";
        setLoadError(message);
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [applyResult]);

  const handleRefresh = async () => {
    setRefreshing(true);
    setRefreshError(null);
    setSyncMessage(null);
    setSyncDiagnostics(null);
    setSyncWarning(null);
    setRefreshPhase("manifest");
    try {
      const res = await fetch("/api/manifest", { method: "POST" });
      const body: unknown = await res.json();
      if (!res.ok) {
        const record =
          typeof body === "object" && body !== null ? body as Record<string, unknown> : {};
        const message = typeof record.error === "string" ? record.error : "Manifest refresh failed";
        setRefreshError(message);
        return;
      }
      const next = parseManifestStatus(body);
      if (!next) {
        setRefreshError("Invalid manifest refresh response");
        return;
      }
      setStatus(next);
      setLoadError(null);

      if (signedIn) {
        setRefreshPhase("inventory");
        const sync = await syncInventoryAfterManifest();
        if (sync.result) {
          setSyncMessage(
            `Inventory synced (${sync.result.itemCount.toLocaleString()} items).`,
          );
          setSyncDiagnostics(sync.result.diagnostics ?? null);
        } else {
          setSyncDiagnostics(null);
          setSyncWarning(
            sync.error
              ? `Manifest refreshed. Inventory sync failed: ${sync.error}`
              : "Manifest refreshed. Inventory sync failed.",
          );
        }
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : "Manifest refresh failed";
      setRefreshError(message);
    } finally {
      setRefreshing(false);
      setRefreshPhase(null);
    }
  };

  const badge = manifestBadge(status);
  const builtAtLabel = status?.entityCache
    ? new Date(status.entityCache.builtAt).toLocaleString()
    : null;

  return (
    <div className="panel-notch p-5 space-y-4">
      <div className="flex items-center justify-between gap-3">
        <h2 className="text-[11px] tracking-widest uppercase text-muted">Manifest</h2>
        {loading ? (
          <span className="flex items-center gap-2" aria-label="Loading manifest status">
            <Spinner />
          </span>
        ) : (
          <Badge tone={badge.tone}>{badge.label}</Badge>
        )}
      </div>

      <p className="text-xs text-muted leading-relaxed">
        Bungie manifest tables and derived entity stores. Required for build generation and
        loadout verification. When signed in, refreshing the manifest also syncs your inventory.
      </p>

      {loadError && <p className="text-xs text-danger">{loadError}</p>}

      {status && (
        <div className="space-y-1" role="status" aria-live="polite">
          <div className="font-mono text-xs text-foreground">
            cached {status.cachedVersion ?? "—"}
          </div>
          <div className="font-mono text-xs text-foreground">
            remote {status.remoteVersion ?? "—"}
          </div>
          {builtAtLabel && (
            <div className="font-mono text-xs text-foreground">
              entities built {builtAtLabel}
            </div>
          )}
          {status.entityCache && (
            <div className="flex flex-wrap gap-1.5 pt-1">
              {Object.entries(status.entityCache.counts).map(([storeName, count]) => (
                <span
                  key={storeName}
                  className="border border-line px-2 py-0.5 text-[10px] font-mono text-muted"
                >
                  {storeName} {count}
                </span>
              ))}
            </div>
          )}
        </div>
      )}

      {refreshing && (
        <div className="flex items-start gap-2 text-xs text-muted">
          <Spinner />
          <span>
            {refreshPhase === "inventory"
              ? "Syncing inventory from Bungie…"
              : "Downloading manifest and rebuilding entity stores… this can take a few minutes"}
          </span>
        </div>
      )}

      {refreshError && <p className="text-xs text-danger">{refreshError}</p>}
      {syncMessage && <p className="text-xs text-muted">{syncMessage}</p>}
      {syncDiagnostics && (
        <details className="text-xs text-muted">
          <summary className="cursor-pointer hover:text-foreground">Sync breakdown</summary>
          <pre className="mt-2 whitespace-pre-wrap font-mono text-[10px] leading-relaxed border border-line p-2">
            {formatSyncDiagnostics(syncDiagnostics)}
          </pre>
        </details>
      )}
      {syncWarning && <p className="text-xs text-danger">{syncWarning}</p>}

      <button
        type="button"
        onClick={() => void handleRefresh()}
        disabled={loading || refreshing}
        className="w-full py-2 border border-accent text-accent text-xs tracking-widest uppercase hover:bg-accent/10 transition-colors focus-visible:outline-accent disabled:opacity-50"
      >
        Refresh manifest
      </button>
    </div>
  );
}
