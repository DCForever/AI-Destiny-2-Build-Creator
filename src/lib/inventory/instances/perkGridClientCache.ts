/**
 * Browser-only helpers for catalog weapon detail performance.
 * Dedupes concurrent perk-grid GETs, caches successful responses briefly,
 * and serializes auto inventory sync so N owned cards do not each POST /api/bungie/sync.
 */

const DEFAULT_TTL_MS = 60_000;

type CacheEntry = {
  expiresAt: number;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  value: any;
};

const responseCache = new Map<string, CacheEntry>();
const inflight = new Map<string, Promise<unknown>>();

let syncChain: Promise<void> = Promise.resolve();
let lastSyncAt = 0;
const SYNC_COOLDOWN_MS = 15_000;

export function clearPerkGridClientCache(): void {
  responseCache.clear();
  inflight.clear();
}

export function getCachedPerkGrid<T>(instanceId: string): T | null {
  const hit = responseCache.get(instanceId);
  if (!hit) return null;
  if (Date.now() > hit.expiresAt) {
    responseCache.delete(instanceId);
    return null;
  }
  return hit.value as T;
}

export function setCachedPerkGrid<T>(
  instanceId: string,
  value: T,
  ttlMs = DEFAULT_TTL_MS,
): void {
  responseCache.set(instanceId, {
    value,
    expiresAt: Date.now() + ttlMs,
  });
}

/**
 * Deduped fetch of the perk-grid endpoint. Concurrent callers for the same
 * instanceId share one network request. Successful JSON is cached.
 */
export async function fetchPerkGridDeduped<T>(
  instanceId: string,
  opts?: { force?: boolean; signal?: AbortSignal },
): Promise<T> {
  if (!opts?.force) {
    const cached = getCachedPerkGrid<T>(instanceId);
    if (cached) return cached;
  } else {
    responseCache.delete(instanceId);
  }

  const existing = inflight.get(instanceId) as Promise<T> | undefined;
  if (existing && !opts?.force) {
    return existing;
  }

  const url = `/api/user/inventory/instances/${encodeURIComponent(instanceId)}/perk-grid`;
  const promise = (async () => {
    const res = await fetch(url, { signal: opts?.signal });
    const body = (await res.json()) as T & { error?: string };
    if (!res.ok) {
      throw new Error(
        typeof body?.error === "string" ? body.error : "Failed to load perk grid",
      );
    }
    setCachedPerkGrid(instanceId, body);
    return body as T;
  })().finally(() => {
    if (inflight.get(instanceId) === promise) {
      inflight.delete(instanceId);
    }
  });

  inflight.set(instanceId, promise);
  return promise;
}

/**
 * At most one bungie sync in flight; subsequent callers await the same run
 * (or skip if a successful sync completed within the cooldown window).
 */
export function runSharedInventorySync(opts?: {
  force?: boolean;
}): Promise<void> {
  const now = Date.now();
  if (!opts?.force && now - lastSyncAt < SYNC_COOLDOWN_MS) {
    return Promise.resolve();
  }

  const run = syncChain.then(async () => {
    if (!opts?.force && Date.now() - lastSyncAt < SYNC_COOLDOWN_MS) {
      return;
    }
    try {
      await fetch("/api/bungie/sync", { method: "POST" });
      lastSyncAt = Date.now();
    } catch {
      /* caller may retry via force */
    }
  });

  // Keep the chain alive even if sync fails.
  syncChain = run.then(
    () => undefined,
    () => undefined,
  );
  return run;
}
