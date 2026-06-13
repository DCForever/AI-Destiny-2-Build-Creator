import { NextResponse } from "next/server";

import { getBungieOAuthConfig, getSessionSecret } from "@/lib/config/env";
import { createBungieAuthClient } from "@/lib/bungie/oauth";
import { consumeOAuthState } from "@/lib/bungie/oauthStateStore";
import { getSession } from "@/lib/bungie/session";

export const runtime = "nodejs";

const NOT_CONFIGURED = {
  error: "Bungie sign-in is not configured. Set BUNGIE_* and SESSION_SECRET in .env.local.",
};

export async function GET(request: Request): Promise<NextResponse> {
  if (!getBungieOAuthConfig() || !getSessionSecret()) {
    return NextResponse.json(NOT_CONFIGURED, { status: 503 });
  }

  const url = new URL(request.url);
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state");

  if (!code || !state) {
    return NextResponse.json({ error: "Missing code or state query parameter" }, { status: 400 });
  }

  if (!consumeOAuthState(state)) {
    return NextResponse.json({ error: "OAuth state mismatch — possible CSRF attempt" }, { status: 400 });
  }

  const redirectUri = new URL("/api/auth/callback", request.url).toString();
  const authClient = createBungieAuthClient(redirectUri);
  if (!authClient) {
    return NextResponse.json(NOT_CONFIGURED, { status: 503 });
  }

  const session = await getSession();

  try {
    const tokens = await authClient.exchangeCode(code);
    session.tokens = tokens;
    await session.save();
  } catch (error) {
    const message = error instanceof Error ? error.message : "Token exchange failed";
    return NextResponse.json({ error: message }, { status: 502 });
  }

  return NextResponse.redirect(new URL("/analyze", request.url), { status: 307 });
}
