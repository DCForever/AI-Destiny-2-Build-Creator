export type InventorySyncStatus = {
  itemCount: number;
  syncVersion: number;
  lastFullSyncAt: string | null;
  lastSyncAt: string | null;
};

/** Prefer full inventory sync timestamp, then user lastSyncAt. */
export function resolveLastSyncIso(status: InventorySyncStatus | null | undefined): string | null {
  if (!status) return null;
  return status.lastFullSyncAt ?? status.lastSyncAt ?? null;
}

/** Human-readable last sync for Settings Inventory panel. */
export function formatLastSyncLabel(
  status: InventorySyncStatus | null | undefined,
  now = new Date(),
): string {
  const iso = resolveLastSyncIso(status);
  if (!iso) return "Never";
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return "Never";

  const sameDay =
    date.getFullYear() === now.getFullYear() &&
    date.getMonth() === now.getMonth() &&
    date.getDate() === now.getDate();

  if (sameDay) {
    return date.toLocaleTimeString(undefined, {
      hour: "numeric",
      minute: "2-digit",
    });
  }

  return date.toLocaleString(undefined, {
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  });
}

export function inventorySyncSummary(
  status: InventorySyncStatus | null | undefined,
): { lastSyncLabel: string; itemCountLabel: string; hasSynced: boolean } {
  const hasSynced = resolveLastSyncIso(status) != null;
  return {
    lastSyncLabel: formatLastSyncLabel(status),
    itemCountLabel: hasSynced ? `${status?.itemCount ?? 0} items` : "—",
    hasSynced,
  };
}
