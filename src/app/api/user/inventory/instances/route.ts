import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/auth/requireUser";
import { getDb } from "@/lib/db/client";
import { loadInstanceListContext } from "@/lib/inventory/instances/loadInstanceContext";
import { listUserInstances } from "@/lib/inventory/instances/listUserInstances";
import {
  InvalidInstanceFilterError,
  parseInstanceFilterQuery,
} from "@/lib/inventory/instances/parseFilterQuery";

export const runtime = "nodejs";

function unauthorized() {
  return NextResponse.json({ error: "Not signed in" }, { status: 401 });
}

export async function GET(request: Request): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorized();

  let criteria;
  try {
    criteria = parseInstanceFilterQuery(new URL(request.url).searchParams);
  } catch (error) {
    if (error instanceof InvalidInstanceFilterError) {
      return NextResponse.json({ error: "INVALID_FILTER" }, { status: 400 });
    }
    throw error;
  }

  const context = await loadInstanceListContext(auth);
  const db = getDb();
  const body = listUserInstances({
    db,
    userId: auth.user.id,
    criteria,
    plugMap: context.plugMap,
    characterLabels: context.characterLabels,
    membershipDisplayName: context.membershipDisplayName,
  });

  return NextResponse.json(body);
}
