import { NextResponse } from "next/server";

import { getBungieOAuthConfig, getSessionSecret } from "@/lib/config/env";
import { createBungieAuthClient } from "@/lib/bungie/oauth";
import { getSession } from "@/lib/bungie/session";

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
  if (!authClient) {
    return NextResponse.json(NOT_CONFIGURED, { status: 503 });
  }

  const state = crypto.randomUUID();
  const session = await getSession();
  session.oauthState = state;
  await session.save();

  const authorizeUrl = authClient.buildAuthorizeUrl(state);
  return NextResponse.redirect(authorizeUrl, { status: 307 });
}
