import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/auth/requireUser";
import { createBungieProfileClient } from "@/lib/bungie/profile";
import { syncUserInventory, SyncInProgressError } from "@/lib/bungie/syncInventory";
import { getBungieOAuthConfig, getSessionSecret } from "@/lib/config/env";
import { getDb } from "@/lib/db/client";
import { getServices, ManifestNotReadyError } from "@/lib/services";

export const runtime = "nodejs";

const NOT_CONFIGURED = {
  error: "Bungie sign-in is not configured. Set BUNGIE_* and SESSION_SECRET in .env.local.",
};

export async function POST(request: Request): Promise<NextResponse> {
  if (!getBungieOAuthConfig() || !getSessionSecret()) {
    return NextResponse.json(NOT_CONFIGURED, { status: 503 });
  }

  const auth = await requireAuthenticatedUser(request);
  if (!auth) {
    return NextResponse.json({ error: "Not signed in" }, { status: 401 });
  }

  const profileClient = createBungieProfileClient();
  if (!profileClient) {
    return NextResponse.json(NOT_CONFIGURED, { status: 503 });
  }

  try {
    const { entityCache } = await getServices();
    const db = getDb();
    const result = await syncUserInventory(
      db,
      auth.user,
      auth.tokens.accessToken,
      profileClient,
      entityCache,
    );
    return NextResponse.json(result);
  } catch (error) {
    if (error instanceof SyncInProgressError) {
      return NextResponse.json({ error: error.message }, { status: 409 });
    }
    if (error instanceof ManifestNotReadyError) {
      return NextResponse.json({ error: error.message }, { status: 503 });
    }
    const message = error instanceof Error ? error.message : "Inventory sync failed";
    return NextResponse.json({ error: message }, { status: 502 });
  }
}
