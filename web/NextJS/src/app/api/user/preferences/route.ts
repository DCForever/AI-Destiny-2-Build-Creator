import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/auth/requireUser";
import { isMultiPassEnabled } from "@/lib/config/env";
import { readUserPreferences, writeUserPreferences, mergePreferences } from "@/lib/preferences/store";
import { userPreferencesSchema } from "@/lib/preferences/types";

export const runtime = "nodejs";

function unauthorized() {
  return NextResponse.json({ error: "Not signed in" }, { status: 401 });
}

export async function GET(request: Request): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorized();

  const prefs = await readUserPreferences(auth.user.bungieMembershipId);
  return NextResponse.json({
    preferences: prefs,
    multiPassAvailable: isMultiPassEnabled(),
  });
}

export async function PUT(request: Request): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorized();

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Request body must be JSON" }, { status: 400 });
  }

  const parsed = userPreferencesSchema.safeParse(body);
  if (!parsed.success) {
    const issues = parsed.error.issues
      .map((issue) => `${issue.path.join(".")}: ${issue.message}`)
      .join("; ");
    return NextResponse.json({ error: `Invalid preferences: ${issues}` }, { status: 400 });
  }

  const existing = await readUserPreferences(auth.user.bungieMembershipId);
  const merged = mergePreferences(existing, parsed.data);
  await writeUserPreferences(auth.user.bungieMembershipId, merged);

  return NextResponse.json({
    preferences: merged,
    multiPassAvailable: isMultiPassEnabled(),
  });
}
