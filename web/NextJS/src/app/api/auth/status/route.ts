import { NextResponse } from "next/server";

import { getBungieOAuthConfig, getSessionSecret } from "@/lib/config/env";
import { createBungieAuthClient } from "@/lib/bungie/oauth";
import { getSession, getValidTokens } from "@/lib/bungie/session";

export const runtime = "nodejs";

const NOT_CONFIGURED = {
  error: "Bungie sign-in is not configured. Set BUNGIE_* and SESSION_SECRET in .env.local.",
};

export async function GET(request: Request): Promise<NextResponse> {
  const configured = getBungieOAuthConfig() !== null && getSessionSecret() !== null;

  if (!configured) {
    return NextResponse.json({ ...NOT_CONFIGURED, configured: false }, { status: 503 });
  }

  const redirectUri = new URL("/api/auth/callback", request.url).toString();
  const authClient = createBungieAuthClient(redirectUri);
  if (!authClient) {
    return NextResponse.json({ configured: false, signedIn: false }, { status: 503 });
  }

  try {
    const session = await getSession();
    const tokens = await getValidTokens(session, authClient);
    if (!tokens) {
      return NextResponse.json({ configured: true, signedIn: false });
    }
    return NextResponse.json({
      configured: true,
      signedIn: true,
      bungieMembershipId: tokens.bungieMembershipId,
    });
  } catch {
    return NextResponse.json({ configured: true, signedIn: false });
  }
}
