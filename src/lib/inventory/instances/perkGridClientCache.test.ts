import { afterEach, describe, expect, it, vi } from "vitest";

import {
  clearPerkGridClientCache,
  fetchPerkGridDeduped,
  getCachedPerkGrid,
  runSharedInventorySync,
  setCachedPerkGrid,
} from "./perkGridClientCache";

describe("perkGridClientCache", () => {
  afterEach(() => {
    clearPerkGridClientCache();
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it("returns cached value without refetch", async () => {
    setCachedPerkGrid("a", { ok: true });
    const fetchMock = vi.fn();
    vi.stubGlobal("fetch", fetchMock);
    const result = await fetchPerkGridDeduped<{ ok: boolean }>("a");
    expect(result).toEqual({ ok: true });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("dedupes concurrent fetches for the same instance", async () => {
    let resolveFetch!: (v: Response) => void;
    const fetchPromise = new Promise<Response>((r) => {
      resolveFetch = r;
    });
    const fetchMock = vi.fn(() => fetchPromise);
    vi.stubGlobal("fetch", fetchMock);

    const p1 = fetchPerkGridDeduped<{ captureStatus: string }>("inst-x");
    const p2 = fetchPerkGridDeduped<{ captureStatus: string }>("inst-x");
    expect(fetchMock).toHaveBeenCalledTimes(1);

    resolveFetch(
      new Response(JSON.stringify({ captureStatus: "complete", columns: [] }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }),
    );

    const [a, b] = await Promise.all([p1, p2]);
    expect(a.captureStatus).toBe("complete");
    expect(b.captureStatus).toBe("complete");
    expect(getCachedPerkGrid("inst-x")).toMatchObject({
      captureStatus: "complete",
    });
  });

  it("serializes shared inventory sync and cools down", async () => {
    const fetchMock = vi.fn(async () => new Response(null, { status: 200 }));
    vi.stubGlobal("fetch", fetchMock);

    await Promise.all([
      runSharedInventorySync({ force: true }),
      runSharedInventorySync({ force: true }),
    ]);
    // Second force still queues on the same chain; both may run sequentially.
    expect(fetchMock.mock.calls.length).toBeGreaterThanOrEqual(1);
    expect(
      fetchMock.mock.calls.every(
        (c) => (c as unknown as [string])[0] === "/api/bungie/sync",
      ),
    ).toBe(true);

    fetchMock.mockClear();
    await runSharedInventorySync();
    expect(fetchMock).not.toHaveBeenCalled();
  });
});
