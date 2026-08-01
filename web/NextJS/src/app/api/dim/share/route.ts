import { NextResponse } from "next/server";

import { getBungieOAuthConfig, getSessionSecret } from "@/lib/config/env";
import { createBungieAuthClient } from "@/lib/bungie/oauth";
import { createBungieProfileClient } from "@/lib/bungie/profile";
import { getSession, getValidTokens } from "@/lib/bungie/session";
import { createDimSyncClient } from "@/lib/dim/dimSync";
import { buildDimLoadout } from "@/lib/dim/dimLoadout";
import type { ResolvedBuildSheet } from "@/lib/build/types";

export const runtime = "nodejs";

type ClassName = "Titan" | "Hunter" | "Warlock";

function isClassName(val: unknown): val is ClassName {
  return val === "Titan" || val === "Hunter" || val === "Warlock";
}

function isValidBody(
  body: unknown,
): body is { sheet: ResolvedBuildSheet; className: ClassName } {
  if (typeof body !== "object" || body === null) return false;
  const b = body as Record<string, unknown>;
  if (typeof b.sheet !== "object" || b.sheet === null) return false;
  const sheet = b.sheet as Record<string, unknown>;
  if (typeof sheet.build !== "object" || !Array.isArray(sheet.weapons)) return false;
  return isClassName(b.className);
}

export async function POST(request: Request): Promise<NextResponse> {
  const dimClient = createDimSyncClient();
  if (!dimClient) {
    return NextResponse.json(
      { error: "dim.gg sharing is not configured. Set DIM_API_KEY in .env.local." },
      { status: 503 },
    );
  }

  if (!getBungieOAuthConfig() || !getSessionSecret()) {
    return NextResponse.json(
      {
        error:
          "dim.gg sharing requires Bungie sign-in. Configure BUNGIE_* and SESSION_SECRET.",
      },
      { status: 503 },
    );
  }

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body." }, { status: 400 });
  }

  if (!isValidBody(body)) {
    return NextResponse.json(
      { error: "Body must include sheet (object with build and weapons) and className." },
      { status: 400 },
    );
  }

  const { sheet, className } = body;

  const redirectUri = new URL("/api/auth/callback", request.url).toString();
  const authClient = createBungieAuthClient(redirectUri);
  if (!authClient) {
    return NextResponse.json(
      {
        error:
          "dim.gg sharing requires Bungie sign-in. Configure BUNGIE_* and SESSION_SECRET.",
      },
      { status: 503 },
    );
  }

  const session = await getSession();
  const tokens = await getValidTokens(session, authClient);
  if (!tokens) {
    return NextResponse.json(
      { error: "Sign in with Bungie on the Analyzer page first." },
      { status: 401 },
    );
  }

  const profileClient = createBungieProfileClient();
  if (!profileClient) {
    return NextResponse.json(
      {
        error:
          "dim.gg sharing requires Bungie sign-in. Configure BUNGIE_* and SESSION_SECRET.",
      },
      { status: 503 },
    );
  }

  try {
    const memberships = await profileClient.getMemberships(tokens.accessToken);
    if (memberships.length === 0) {
      return NextResponse.json({ error: "No Destiny memberships found." }, { status: 502 });
    }

    const platformMembershipId = memberships[0].membershipId;
    const dimToken = await dimClient.getAuthToken(
      tokens.accessToken,
      tokens.bungieMembershipId,
    );
    const loadout = buildDimLoadout(sheet, className);
    const { shareUrl } = await dimClient.shareLoadout(dimToken, platformMembershipId, loadout);

    return NextResponse.json({ shareUrl });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unexpected error sharing loadout";
    return NextResponse.json({ error: message }, { status: 502 });
  }
}
