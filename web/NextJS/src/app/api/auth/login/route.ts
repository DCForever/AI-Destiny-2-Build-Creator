import { NextResponse } from "next/server";

import { getBungieOAuthConfig, getSessionSecret } from "@/lib/config/env";
import { createBungieAuthClient } from "@/lib/bungie/oauth";
import { getSession } from "@/lib/bungie/session";
import { sanitizeReturnUrl } from "@/lib/auth/returnUrl";

export const runtime = "nodejs";

const NOT_CONFIGURED = {
  error: "Bungie sign-in is not configured. Set BUNGIE_* and SESSION_SECRET in .env.local.",
};

const HTTPS_DEV_HINT =
  "Bungie OAuth requires HTTPS in development. Run npm run dev:https and open https://127.0.0.1:3000.";

export async function GET(request: Request): Promise<NextResponse> {
  if (!getBungieOAuthConfig() || !getSessionSecret()) {
    return NextResponse.json(NOT_CONFIGURED, { status: 503 });
  }

  const requestUrl = new URL(request.url);

  if (process.env.NODE_ENV === "development" && requestUrl.protocol !== "https:") {
    return NextResponse.json({ error: HTTPS_DEV_HINT }, { status: 400 });
  }

  const redirectUri = new URL("/api/auth/callback", request.url).toString();
  const authClient = createBungieAuthClient(redirectUri);
  if (!authClient) {
    return NextResponse.json(NOT_CONFIGURED, { status: 503 });
  }

  const state = crypto.randomUUID();
  const returnUrl = sanitizeReturnUrl(requestUrl.searchParams.get("returnUrl"), requestUrl);

  const session = await getSession();
  session.oauthState = state;
  session.oauthReturnUrl = returnUrl;
  await session.save();

  const authorizeUrl = authClient.buildAuthorizeUrl(state);
  return NextResponse.redirect(authorizeUrl, { status: 307 });
}
