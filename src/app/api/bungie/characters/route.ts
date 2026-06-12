import { NextResponse } from "next/server";

import { getBungieOAuthConfig, getSessionSecret } from "@/lib/config/env";
import { createBungieAuthClient } from "@/lib/bungie/oauth";
import { createBungieProfileClient } from "@/lib/bungie/profile";
import { getSession, getValidTokens } from "@/lib/bungie/session";

export const runtime = "nodejs";

const NOT_CONFIGURED = {
  error: "Bungie sign-in is not configured. Set BUNGIE_* and SESSION_SECRET in .env.local.",
};

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
    const memberships = await profileClient.getMemberships(tokens.accessToken);
    const membership = memberships[0];
    if (!membership) {
      return NextResponse.json({ error: "No Destiny memberships found" }, { status: 404 });
    }
    const characters = await profileClient.getCharacters(tokens.accessToken, membership);
    return NextResponse.json({ membership, characters });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to fetch characters";
    return NextResponse.json({ error: message }, { status: 502 });
  }
}
