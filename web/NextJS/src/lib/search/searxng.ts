import { getSearxngUrl } from "../config/env";

export interface SearchResultItem {
  title: string;
  snippet: string;
  url: string;
}

export type WebSearchOutcome =
  | { available: true; results: SearchResultItem[] }
  | { available: false; reason: string };

export interface SearxngClient {
  search(query: string, limit?: number): Promise<WebSearchOutcome>;
  healthCheck(): Promise<{ healthy: boolean; detail: string }>;
}

const DEFAULT_TIMEOUT_MS = 8000;
const NOT_CONFIGURED_REASON =
  "SearXNG is not configured (SEARXNG_URL unset)";
const BLANK_QUERY_REASON = "Search query is blank";
const JSON_FORMAT_403_REASON =
  "SearXNG returned 403: enable the JSON format in SearXNG settings.yml";

interface HttpSearxngClientOptions {
  baseUrl: string | null;
  fetchFn?: typeof fetch;
  timeoutMs?: number;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function errorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  return String(error);
}

function buildSearchUrl(baseUrl: string, query: string): string {
  const trimmedBase = baseUrl.replace(/\/+$/, "");
  return `${trimmedBase}/search?q=${encodeURIComponent(query)}&format=json`;
}

function mapRawResult(raw: unknown): SearchResultItem | null {
  if (!isRecord(raw)) {
    return null;
  }

  const title = raw.title;
  const url = raw.url;
  if (typeof title !== "string" || !title.trim()) {
    return null;
  }
  if (typeof url !== "string" || !url.trim()) {
    return null;
  }

  const content = raw.content;
  const snippet = typeof content === "string" ? content : "";
  return { title, snippet, url };
}

function parseSearxngResponse(json: unknown): SearchResultItem[] {
  if (!isRecord(json) || !Array.isArray(json.results)) {
    throw new Error("Unexpected SearXNG response shape");
  }

  const mapped: SearchResultItem[] = [];
  for (const raw of json.results) {
    const item = mapRawResult(raw);
    if (item) {
      mapped.push(item);
    }
  }
  return mapped;
}

function unavailableReason(error: unknown, timeoutMs: number): string {
  if (error instanceof Error && error.name === "AbortError") {
    return `SearXNG request timed out after ${timeoutMs}ms`;
  }
  return `SearXNG request failed: ${errorMessage(error)}`;
}

function httpFailureReason(status: number): string {
  if (status === 403) {
    return JSON_FORMAT_403_REASON;
  }
  return `SearXNG request failed with status ${status}`;
}

export class HttpSearxngClient implements SearxngClient {
  private readonly baseUrl: string | null;
  private readonly fetchFn: typeof fetch;
  private readonly timeoutMs: number;

  constructor(options: HttpSearxngClientOptions) {
    this.baseUrl = options.baseUrl;
    this.fetchFn = options.fetchFn ?? fetch;
    this.timeoutMs = options.timeoutMs ?? DEFAULT_TIMEOUT_MS;
  }

  async search(query: string, limit = 5): Promise<WebSearchOutcome> {
    if (!this.baseUrl) {
      return { available: false, reason: NOT_CONFIGURED_REASON };
    }

    const trimmedQuery = query.trim();
    if (!trimmedQuery) {
      return { available: false, reason: BLANK_QUERY_REASON };
    }

    try {
      const results = await this.fetchSearchResults(trimmedQuery);
      return { available: true, results: results.slice(0, limit) };
    } catch (error) {
      return { available: false, reason: unavailableReason(error, this.timeoutMs) };
    }
  }

  async healthCheck(): Promise<{ healthy: boolean; detail: string }> {
    if (!this.baseUrl) {
      return { healthy: false, detail: "not configured" };
    }

    const outcome = await this.search("test", 1);
    if (outcome.available) {
      return { healthy: true, detail: "SearXNG search succeeded" };
    }
    return { healthy: false, detail: outcome.reason };
  }

  private async fetchSearchResults(query: string): Promise<SearchResultItem[]> {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.timeoutMs);

    try {
      const response = await this.fetchFn(buildSearchUrl(this.baseUrl!, query), {
        signal: controller.signal,
      });

      if (!response.ok) {
        throw new Error(httpFailureReason(response.status));
      }

      const json: unknown = await response.json();
      return parseSearxngResponse(json);
    } finally {
      clearTimeout(timeoutId);
    }
  }
}

export function createSearxngClient(): SearxngClient {
  return new HttpSearxngClient({ baseUrl: getSearxngUrl() });
}
