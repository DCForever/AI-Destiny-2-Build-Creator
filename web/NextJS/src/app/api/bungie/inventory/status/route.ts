import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/auth/requireUser";
import { getBungieOAuthConfig, getSessionSecret } from "@/lib/config/env";
import { getDb } from "@/lib/db/client";
import { getInventoryStatus } from "@/lib/db/repositories/inventoryRepository";

export const runtime = "nodejs";

const NOT_CONFIGURED = {
  error: "Bungie sign-in is not configured. Set BUNGIE_* and SESSION_SECRET in .env.local.",
};

export async function GET(request: Request): Promise<NextResponse> {
  if (!getBungieOAuthConfig() || !getSessionSecret()) {
    return NextResponse.json(NOT_CONFIGURED, { status: 503 });
  }

  const auth = await requireAuthenticatedUser(request);
  if (!auth) {
    return NextResponse.json({ error: "Not signed in" }, { status: 401 });
  }

  const db = getDb();
  const status = getInventoryStatus(db, auth.user.id);

  return NextResponse.json({
    itemCount: status?.itemCount ?? 0,
    syncVersion: status?.syncVersion ?? 0,
    lastFullSyncAt: status?.lastFullSyncAt ?? null,
    lastSyncAt: auth.user.lastSyncAt,
  });
}
