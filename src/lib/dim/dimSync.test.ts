import { describe, it, expect, vi, type Mock } from "vitest";
import { DimSyncClient } from "./dimSync";
import type { DimLoadout } from "./dimLoadout";

const FAKE_KEY = "test-api-key-not-real";

const minimalLoadout: DimLoadout = {
  id: "00000000-0000-0000-0000-000000000001",
  name: "Test Loadout",
  classType: 0,
  equipped: [{ hash: 1001 }],
  unequipped: [],
  parameters: { autoStatMods: true, includeRuntimeStatBenefits: true },
};

function makeFetch(status: number, body: unknown): Mock {
  return vi.fn().mockResolvedValue({
    ok: status >= 200 && status < 300,
    status,
    statusText: "OK",
    json: async () => body,
  });
}

describe("DimSyncClient.getAuthToken", () => {
  it("POSTs to /auth/token with X-API-Key header and returns accessToken", async () => {
    const fetchFn = makeFetch(200, { accessToken: "dim-token-abc", expiresInSeconds: 3600 });
    const client = new DimSyncClient({ apiKey: FAKE_KEY, fetchFn });

    const token = await client.getAuthToken("bungie-access", "mem-123");

    expect(token).toBe("dim-token-abc");
    expect(fetchFn).toHaveBeenCalledOnce();

    const [url, init] = fetchFn.mock.calls[0] as [string, RequestInit];
    expect(url).toBe("https://api.destinyitemmanager.com/auth/token");
    expect(init.method).toBe("POST");

    const headers = init.headers as Record<string, string>;
    expect(headers["X-API-Key"]).toBe(FAKE_KEY);

    const body = JSON.parse(init.body as string) as Record<string, unknown>;
    expect(body).toEqual({ bungieAccessToken: "bungie-access", membershipId: "mem-123" });
  });

  it("throws descriptive error on 401 without exposing api key", async () => {
    const fetchFn = makeFetch(401, { message: "Invalid token" });
    const client = new DimSyncClient({ apiKey: FAKE_KEY, fetchFn });

    await expect(client.getAuthToken("bad-token", "mem-123")).rejects.toThrow(
      "Bungie token rejected by DIM Sync — sign in again",
    );

    const error = await client.getAuthToken("bad-token", "mem-123").catch((e: unknown) =>
      e instanceof Error ? e.message : "",
    );
    expect(error).not.toContain(FAKE_KEY);
  });

  it("throws on non-401 error with status and message", async () => {
    const fetchFn = makeFetch(500, { message: "Internal Server Error" });
    const client = new DimSyncClient({ apiKey: FAKE_KEY, fetchFn });

    await expect(client.getAuthToken("tok", "mem")).rejects.toThrow("500");
  });

  it("throws when accessToken is missing from response", async () => {
    const fetchFn = makeFetch(200, { notAccessToken: "surprise" });
    const client = new DimSyncClient({ apiKey: FAKE_KEY, fetchFn });

    await expect(client.getAuthToken("tok", "mem")).rejects.toThrow(
      "DIM Sync auth response missing accessToken",
    );
  });
});

describe("DimSyncClient.shareLoadout", () => {
  it("POSTs to /loadout_share with Authorization and X-API-Key headers", async () => {
    const shareUrl = "https://dim.gg/loadout/abc123";
    const fetchFn = makeFetch(200, { shareUrl });
    const client = new DimSyncClient({ apiKey: FAKE_KEY, fetchFn });

    const result = await client.shareLoadout("dim-token", "plat-mem-id", minimalLoadout);

    expect(result.shareUrl).toBe(shareUrl);
    expect(fetchFn).toHaveBeenCalledOnce();

    const [url, init] = fetchFn.mock.calls[0] as [string, RequestInit];
    expect(url).toBe("https://api.destinyitemmanager.com/loadout_share");
    expect(init.method).toBe("POST");

    const headers = init.headers as Record<string, string>;
    expect(headers["X-API-Key"]).toBe(FAKE_KEY);
    expect(headers["Authorization"]).toBe("Bearer dim-token");

    const body = JSON.parse(init.body as string) as Record<string, unknown>;
    expect(body.platformMembershipId).toBe("plat-mem-id");
    expect(body.loadout).toEqual(minimalLoadout);
  });

  it("throws on non-OK response without exposing api key", async () => {
    const fetchFn = makeFetch(403, { message: "Forbidden" });
    const client = new DimSyncClient({ apiKey: FAKE_KEY, fetchFn });

    const error = await client
      .shareLoadout("dim-token", "mem", minimalLoadout)
      .catch((e: unknown) => (e instanceof Error ? e.message : ""));

    expect(error).toContain("403");
    expect(error).not.toContain(FAKE_KEY);
  });

  it("throws when shareUrl is missing from response", async () => {
    const fetchFn = makeFetch(200, { notShareUrl: "nope" });
    const client = new DimSyncClient({ apiKey: FAKE_KEY, fetchFn });

    await expect(
      client.shareLoadout("dim-token", "mem", minimalLoadout),
    ).rejects.toThrow("DIM Sync share response missing shareUrl");
  });
});
