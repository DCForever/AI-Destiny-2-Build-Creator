import { describe, expect, it, vi } from "vitest";

import { HttpBungieAuthClient, needsRefresh, isSessionExpired } from "./oauth";
import type { BungieTokens } from "./types";

const TEST_CONFIG = {
  apiKey: "test-api-key",
  clientId: "client123",
  clientSecret: "supersecret999",
};

const REDIRECT_URI = "https://example.com/api/auth/callback";

function makeClient(fetchFn: typeof fetch) {
  return new HttpBungieAuthClient({ config: TEST_CONFIG, redirectUri: REDIRECT_URI, fetchFn });
}

const RAW_TOKEN_RESPONSE = {
  access_token: "acc",
  token_type: "Bearer",
  expires_in: 3600,
  refresh_token: "ref",
  refresh_expires_in: 7776000,
  membership_id: "mem123",
};

function makeOkFetch(body: unknown): typeof fetch {
  return vi.fn().mockResolvedValue({
    ok: true,
    json: async () => body,
  }) as unknown as typeof fetch;
}

function makeErrorFetch(status: number): typeof fetch {
  return vi.fn().mockResolvedValue({
    ok: false,
    status,
    statusText: "Bad Request",
    json: async () => ({}),
  }) as unknown as typeof fetch;
}

describe("HttpBungieAuthClient.buildAuthorizeUrl", () => {
  it("includes client_id and state as URL-encoded params", () => {
    const client = makeClient(makeOkFetch({}));
    const url = client.buildAuthorizeUrl("state-abc");

    expect(url).toContain("client_id=client123");
    expect(url).toContain("state=state-abc");
    expect(url).toContain("response_type=code");
    expect(url).toContain("https://www.bungie.net/en/oauth/authorize");
  });

  it("URL-encodes special characters in state", () => {
    const client = makeClient(makeOkFetch({}));
    const url = client.buildAuthorizeUrl("a b+c");

    expect(url).not.toContain("a b+c");
  });
});

describe("HttpBungieAuthClient.exchangeCode", () => {
  it("posts urlencoded body with correct grant_type and code", async () => {
    const fetchFn = makeOkFetch(RAW_TOKEN_RESPONSE);
    await makeClient(fetchFn).exchangeCode("my-code");

    const [, init] = (fetchFn as ReturnType<typeof vi.fn>).mock.calls[0] as [
      string,
      RequestInit,
    ];
    expect(init.body).toContain("grant_type=authorization_code");
    expect(init.body).toContain("code=my-code");
  });

  it("sends Basic auth header with base64-encoded clientId:clientSecret", async () => {
    const fetchFn = makeOkFetch(RAW_TOKEN_RESPONSE);
    await makeClient(fetchFn).exchangeCode("code");

    const [, init] = (fetchFn as ReturnType<typeof vi.fn>).mock.calls[0] as [
      string,
      RequestInit,
    ];
    const expected = `Basic ${Buffer.from("client123:supersecret999").toString("base64")}`;
    expect((init.headers as Record<string, string>)["Authorization"]).toBe(expected);
  });

  it("maps token response and applies 60s expiry margin on expiresAt", async () => {
    const before = Date.now();
    const tokens = await makeClient(makeOkFetch(RAW_TOKEN_RESPONSE)).exchangeCode("x");
    const after = Date.now();

    expect(tokens.accessToken).toBe("acc");
    expect(tokens.refreshToken).toBe("ref");
    expect(tokens.bungieMembershipId).toBe("mem123");
    expect(tokens.expiresAt).toBeGreaterThanOrEqual(before + 3600 * 1000 - 60_000);
    expect(tokens.expiresAt).toBeLessThanOrEqual(after + 3600 * 1000 - 60_000);
    expect(tokens.refreshExpiresAt).toBeGreaterThanOrEqual(before + 7776000 * 1000);
  });

  it("throws a descriptive error on non-OK response without leaking the secret", async () => {
    const promise = makeClient(makeErrorFetch(400)).exchangeCode("code");

    await expect(promise).rejects.toThrow(/400/);
    await expect(promise).rejects.not.toThrow(TEST_CONFIG.clientSecret);
  });

  it("throws when response body has unexpected shape", async () => {
    const promise = makeClient(makeOkFetch({ wrong: "shape" })).exchangeCode("x");

    await expect(promise).rejects.toThrow(/unexpected shape/i);
  });
});

describe("HttpBungieAuthClient.refreshTokens", () => {
  it("posts refresh_token grant with the stored refresh token", async () => {
    const fetchFn = makeOkFetch(RAW_TOKEN_RESPONSE);
    const tokens: BungieTokens = {
      accessToken: "old",
      refreshToken: "refresh-abc",
      expiresAt: 0,
      refreshExpiresAt: Date.now() + 1_000_000,
      bungieMembershipId: "m",
    };
    await makeClient(fetchFn).refreshTokens(tokens);

    const [, init] = (fetchFn as ReturnType<typeof vi.fn>).mock.calls[0] as [
      string,
      RequestInit,
    ];
    expect(init.body).toContain("grant_type=refresh_token");
    expect(init.body).toContain("refresh_token=refresh-abc");
  });
});

describe("needsRefresh", () => {
  it("returns true when expiresAt is in the past", () => {
    const tokens: BungieTokens = {
      accessToken: "",
      refreshToken: "",
      expiresAt: Date.now() - 1,
      refreshExpiresAt: Date.now() + 1_000_000,
      bungieMembershipId: "",
    };
    expect(needsRefresh(tokens)).toBe(true);
  });

  it("returns false when expiresAt is in the future", () => {
    const tokens: BungieTokens = {
      accessToken: "",
      refreshToken: "",
      expiresAt: Date.now() + 10_000,
      refreshExpiresAt: Date.now() + 1_000_000,
      bungieMembershipId: "",
    };
    expect(needsRefresh(tokens)).toBe(false);
  });
});

describe("isSessionExpired", () => {
  it("returns true when refreshExpiresAt is in the past", () => {
    const tokens: BungieTokens = {
      accessToken: "",
      refreshToken: "",
      expiresAt: 0,
      refreshExpiresAt: Date.now() - 1,
      bungieMembershipId: "",
    };
    expect(isSessionExpired(tokens)).toBe(true);
  });

  it("returns false when refreshExpiresAt is in the future", () => {
    const tokens: BungieTokens = {
      accessToken: "",
      refreshToken: "",
      expiresAt: 0,
      refreshExpiresAt: Date.now() + 10_000,
      bungieMembershipId: "",
    };
    expect(isSessionExpired(tokens)).toBe(false);
  });
});
