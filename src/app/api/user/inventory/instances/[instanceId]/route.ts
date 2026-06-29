import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/auth/requireUser";
import { getDb } from "@/lib/db/client";
import { loadInstanceListContext } from "@/lib/inventory/instances/loadInstanceContext";
import { getUserInstanceById } from "@/lib/inventory/instances/listUserInstances";

export const runtime = "nodejs";

function unauthorized() {
  return NextResponse.json({ error: "Not signed in" }, { status: 401 });
}

export async function GET(
  request: Request,
  context: { params: Promise<{ instanceId: string }> },
): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorized();

  const { instanceId } = await context.params;
  const apiContext = await loadInstanceListContext(auth);
  const db = getDb();
  const result = getUserInstanceById({
    db,
    userId: auth.user.id,
    criteria: {},
    plugMap: apiContext.plugMap,
    characterLabels: apiContext.characterLabels,
    membershipDisplayName: apiContext.membershipDisplayName,
    instanceId,
  });

  if (result.syncPrompt) {
    return NextResponse.json({
      instances: [],
      count: 0,
      syncPrompt: true,
      message: result.message,
    });
  }

  if (!result.instance) {
    return NextResponse.json({ error: "Instance not found" }, { status: 404 });
  }

  return NextResponse.json(result.instance);
}
