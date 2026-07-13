import { NextResponse } from "next/server";

import { getBungieOAuthConfig, getSessionSecret } from "@/lib/config/env";
import { createBungieAuthClient } from "@/lib/bungie/oauth";
import { createBungieProfileClient } from "@/lib/bungie/profile";
import { fetchInGameLoadouts } from "@/lib/bungie/fetchInGameLoadouts";
import { getSession, getValidTokens } from "@/lib/bungie/session";
import { getServices } from "@/lib/services";

export const runtime = "nodejs";

const NOT_CONFIGURED = {
  error:
    "Bungie sign-in is not configured. Set BUNGIE_* and SESSION_SECRET in .env.local.",
};

/**
 * Live Bungie character loadouts (component 206) with icon/color resolved
 * from DestinyLoadout*Definition — same presentation path as DIM.
 */
export async function GET(request: Request): Promise<NextResponse> {
  if (!getBungieOAuthConfig() || !getSessionSecret()) {
    return NextResponse.json(NOT_CONFIGURED, { status: 503 });
  }

  const redirectUri = new URL("/api/auth/callback", request.url).toString();
  const authClient = createBungieAuthClient(redirectUri);
  const profileClient = createBungieProfileClient();
  if (!authClient || !profileClient) {
    return NextResponse.json(NOT_CONFIGURED, { status: 503 });
  }

  const session = await getSession();
  const tokens = await getValidTokens(session, authClient);
  if (!tokens) {
    return NextResponse.json({ error: "Not signed in" }, { status: 401 });
  }

  try {
    const { manifest } = await getServices();
    const result = await fetchInGameLoadouts({
      accessToken: tokens.accessToken,
      profileClient,
      manifest,
    });
    return NextResponse.json({
      membershipDisplayName: result.membershipDisplayName,
      manifestVersion: result.manifestVersion,
      loadouts: result.loadouts,
    });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Failed to fetch Bungie loadouts";
    // Missing loadout presentation tables until next manifest refresh
    if (/Raw table|not on disk|ensureCurrent/i.test(message)) {
      return NextResponse.json(
        {
          error:
            "Loadout icon tables are not downloaded yet. Refresh the Destiny manifest from Settings, then try again.",
          detail: message,
        },
        { status: 503 },
      );
    }
    return NextResponse.json({ error: message }, { status: 502 });
  }
}
