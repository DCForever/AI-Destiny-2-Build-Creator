import { getDimApiKey } from "@/lib/config/env";
import type { DimLoadout } from "./dimLoadout";

export interface DimShareResult {
  shareUrl: string;
}

const DIM_BASE = "https://api.destinyitemmanager.com";

async function extractErrorMessage(response: Response): Promise<string> {
  try {
    const body = (await response.json()) as Record<string, unknown>;
    if (typeof body.message === "string") return body.message;
  } catch {
    // fall through to statusText
  }
  return response.statusText;
}

export class DimSyncClient {
  private readonly apiKey: string;
  private readonly fetchFn: typeof fetch;

  constructor(opts: { apiKey: string; fetchFn?: typeof fetch }) {
    this.apiKey = opts.apiKey;
    this.fetchFn = opts.fetchFn ?? fetch;
  }

  private baseHeaders(): Record<string, string> {
    return {
      "X-API-Key": this.apiKey,
      "Content-Type": "application/json",
    };
  }

  async getAuthToken(
    bungieAccessToken: string,
    bungieMembershipId: string,
  ): Promise<string> {
    const response = await this.fetchFn(`${DIM_BASE}/auth/token`, {
      method: "POST",
      headers: this.baseHeaders(),
      body: JSON.stringify({ bungieAccessToken, membershipId: bungieMembershipId }),
    });

    if (response.status === 401) {
      throw new Error("Bungie token rejected by DIM Sync — sign in again");
    }

    if (!response.ok) {
      const msg = await extractErrorMessage(response);
      throw new Error(`DIM Sync auth failed (${response.status}): ${msg}`);
    }

    const data = (await response.json()) as Record<string, unknown>;
    if (typeof data.accessToken !== "string") {
      throw new Error("DIM Sync auth response missing accessToken");
    }
    return data.accessToken;
  }

  async shareLoadout(
    dimToken: string,
    platformMembershipId: string,
    loadout: DimLoadout,
  ): Promise<DimShareResult> {
    const response = await this.fetchFn(`${DIM_BASE}/loadout_share`, {
      method: "POST",
      headers: {
        ...this.baseHeaders(),
        Authorization: `Bearer ${dimToken}`,
      },
      body: JSON.stringify({ platformMembershipId, loadout }),
    });

    if (!response.ok) {
      const msg = await extractErrorMessage(response);
      throw new Error(`DIM Sync share failed (${response.status}): ${msg}`);
    }

    const data = (await response.json()) as Record<string, unknown>;
    if (typeof data.shareUrl !== "string") {
      throw new Error("DIM Sync share response missing shareUrl");
    }
    return { shareUrl: data.shareUrl };
  }
}

export function createDimSyncClient(): DimSyncClient | null {
  const apiKey = getDimApiKey();
  if (!apiKey) return null;
  return new DimSyncClient({ apiKey });
}
