import { getBungieOAuthConfig, type BungieOAuthConfig } from "@/lib/config/env";
import type { BungieAuthClient, BungieTokens } from "./types";

const TOKEN_ENDPOINT = "https://www.bungie.net/platform/app/oauth/token/";
const AUTHORIZE_BASE = "https://www.bungie.net/en/oauth/authorize";
const EXPIRY_MARGIN_MS = 60_000;

export interface HttpBungieAuthClientOptions {
  config: BungieOAuthConfig;
  redirectUri: string;
  fetchFn?: typeof fetch;
}

interface RawTokenResponse {
  access_token: string;
  expires_in: number;
  refresh_token: string;
  refresh_expires_in: number;
  membership_id: string;
}

function isRawTokenResponse(val: unknown): val is RawTokenResponse {
  if (typeof val !== "object" || val === null) return false;
  const v = val as Record<string, unknown>;
  return (
    typeof v.access_token === "string" &&
    typeof v.expires_in === "number" &&
    typeof v.refresh_token === "string" &&
    typeof v.refresh_expires_in === "number" &&
    typeof v.membership_id === "string"
  );
}

function mapTokenResponse(raw: RawTokenResponse): BungieTokens {
  const now = Date.now();
  return {
    accessToken: raw.access_token,
    refreshToken: raw.refresh_token,
    expiresAt: now + raw.expires_in * 1000 - EXPIRY_MARGIN_MS,
    refreshExpiresAt: now + raw.refresh_expires_in * 1000,
    bungieMembershipId: raw.membership_id,
  };
}

export class HttpBungieAuthClient implements BungieAuthClient {
  private readonly config: BungieOAuthConfig;
  private readonly redirectUri: string;
  private readonly fetchFn: typeof fetch;

  constructor(opts: HttpBungieAuthClientOptions) {
    this.config = opts.config;
    this.redirectUri = opts.redirectUri;
    this.fetchFn = opts.fetchFn ?? fetch;
  }

  buildAuthorizeUrl(state: string): string {
    const params = new URLSearchParams({
      client_id: this.config.clientId,
      response_type: "code",
      state,
    });
    return `${AUTHORIZE_BASE}?${params.toString()}`;
  }

  async exchangeCode(code: string): Promise<BungieTokens> {
    const body = new URLSearchParams({ grant_type: "authorization_code", code });
    return this.postTokenRequest(body);
  }

  async refreshTokens(tokens: BungieTokens): Promise<BungieTokens> {
    const body = new URLSearchParams({
      grant_type: "refresh_token",
      refresh_token: tokens.refreshToken,
    });
    return this.postTokenRequest(body);
  }

  private buildBasicAuth(): string {
    const creds = `${this.config.clientId}:${this.config.clientSecret}`;
    return `Basic ${Buffer.from(creds).toString("base64")}`;
  }

  private async postTokenRequest(body: URLSearchParams): Promise<BungieTokens> {
    const response = await this.fetchFn(TOKEN_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        Authorization: this.buildBasicAuth(),
      },
      body: body.toString(),
    });

    if (!response.ok) {
      throw new Error(
        `Bungie token endpoint returned ${response.status}: ${response.statusText}`,
      );
    }

    const data: unknown = await response.json();
    if (!isRawTokenResponse(data)) {
      throw new Error("Bungie token response has unexpected shape");
    }
    return mapTokenResponse(data);
  }
}

export function needsRefresh(tokens: BungieTokens): boolean {
  return tokens.expiresAt <= Date.now();
}

export function isSessionExpired(tokens: BungieTokens): boolean {
  return tokens.refreshExpiresAt <= Date.now();
}

export function createBungieAuthClient(redirectUri: string): BungieAuthClient | null {
  const config = getBungieOAuthConfig();
  if (!config) return null;
  return new HttpBungieAuthClient({ config, redirectUri });
}
