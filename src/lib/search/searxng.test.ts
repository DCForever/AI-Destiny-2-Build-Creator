import { describe, expect, it, vi } from "vitest";

import { HttpSearxngClient } from "./searxng";

const BASE_URL = "http://searxng.local";

function createClient(
  baseUrl: string | null,
  fetchFn: typeof fetch,
): HttpSearxngClient {
  return new HttpSearxngClient({ baseUrl, fetchFn });
}

describe("HttpSearxngClient", () => {
  it("returns unavailable without calling fetch when unconfigured", async () => {
    const fetchFn = vi.fn();
    const client = createClient(null, fetchFn);

    const outcome = await client.search("destiny 2");

    expect(outcome).toEqual({
      available: false,
      reason: "SearXNG is not configured (SEARXNG_URL unset)",
    });
    expect(fetchFn).not.toHaveBeenCalled();
  });

  it("returns unavailable for a blank query without calling fetch", async () => {
    const fetchFn = vi.fn();
    const client = createClient(BASE_URL, fetchFn);

    const outcome = await client.search("   ");

    expect(outcome).toEqual({
      available: false,
      reason: "Search query is blank",
    });
    expect(fetchFn).not.toHaveBeenCalled();
  });

  it("parses results, filters invalid entries, and applies limit", async () => {
    const fixture = {
      results: [
        {
          title: "Destiny 2 Builds Guide",
          content: "Community build tips for PvE.",
          url: "https://example.test/builds",
        },
        {
          title: "Missing URL entry",
          content: "Should be filtered out",
        },
        {
          title: " DIM Loadouts",
          content: "Loadout manager overview.",
          url: "https://example.test/dim",
        },
        {
          title: "Seasonal Meta",
          url: "https://example.test/meta",
        },
      ],
    };

    const fetchFn = vi.fn().mockResolvedValue(
      new Response(JSON.stringify(fixture), { status: 200 }),
    );
    const client = createClient(BASE_URL, fetchFn);

    const outcome = await client.search("destiny 2 builds", 2);

    expect(outcome).toEqual({
      available: true,
      results: [
        {
          title: "Destiny 2 Builds Guide",
          snippet: "Community build tips for PvE.",
          url: "https://example.test/builds",
        },
        {
          title: " DIM Loadouts",
          snippet: "Loadout manager overview.",
          url: "https://example.test/dim",
        },
      ],
    });
    expect(fetchFn).toHaveBeenCalledWith(
      `${BASE_URL}/search?q=${encodeURIComponent("destiny 2 builds")}&format=json`,
      expect.objectContaining({ signal: expect.any(AbortSignal) }),
    );
  });

  it("returns unavailable when SearXNG responds with 403", async () => {
    const fetchFn = vi.fn().mockResolvedValue(
      new Response("Forbidden", { status: 403 }),
    );
    const client = createClient(BASE_URL, fetchFn);

    const outcome = await client.search("destiny 2");

    expect(outcome.available).toBe(false);
    if (!outcome.available) {
      expect(outcome.reason).toContain("403");
      expect(outcome.reason.toLowerCase()).toContain("json format");
    }
  });

  it("returns unavailable when fetch rejects", async () => {
    const fetchFn = vi.fn().mockRejectedValue(new Error("network down"));
    const client = createClient(BASE_URL, fetchFn);

    const outcome = await client.search("destiny 2");

    expect(outcome).toEqual({
      available: false,
      reason: "SearXNG request failed: network down",
    });
  });

  it("returns unavailable when the response body is malformed JSON", async () => {
    const fetchFn = vi.fn().mockResolvedValue(
      new Response("not-json", { status: 200 }),
    );
    const client = createClient(BASE_URL, fetchFn);

    const outcome = await client.search("destiny 2");

    expect(outcome.available).toBe(false);
    if (!outcome.available) {
      expect(outcome.reason).toMatch(/SearXNG request failed:/);
    }
  });

  it("returns unavailable when JSON shape is unexpected", async () => {
    const fetchFn = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ hits: [] }), { status: 200 }),
    );
    const client = createClient(BASE_URL, fetchFn);

    const outcome = await client.search("destiny 2");

    expect(outcome.available).toBe(false);
    if (!outcome.available) {
      expect(outcome.reason).toContain("Unexpected SearXNG response shape");
    }
  });

  describe("healthCheck", () => {
    it("reports unhealthy when SearXNG is not configured", async () => {
      const fetchFn = vi.fn();
      const client = createClient(null, fetchFn);

      const status = await client.healthCheck();

      expect(status).toEqual({ healthy: false, detail: "not configured" });
      expect(fetchFn).not.toHaveBeenCalled();
    });

    it("reports healthy when a probe search succeeds", async () => {
      const fetchFn = vi.fn().mockResolvedValue(
        new Response(
          JSON.stringify({
            results: [
              {
                title: "Probe",
                content: "ok",
                url: "https://example.test/probe",
              },
            ],
          }),
          { status: 200 },
        ),
      );
      const client = createClient(BASE_URL, fetchFn);

      const status = await client.healthCheck();

      expect(status).toEqual({
        healthy: true,
        detail: "SearXNG search succeeded",
      });
      expect(fetchFn).toHaveBeenCalledWith(
        `${BASE_URL}/search?q=test&format=json`,
        expect.objectContaining({ signal: expect.any(AbortSignal) }),
      );
    });

    it("reports unhealthy when a probe search fails", async () => {
      const fetchFn = vi.fn().mockRejectedValue(new Error("connection refused"));
      const client = createClient(BASE_URL, fetchFn);

      const status = await client.healthCheck();

      expect(status).toEqual({
        healthy: false,
        detail: "SearXNG request failed: connection refused",
      });
    });
  });
});
