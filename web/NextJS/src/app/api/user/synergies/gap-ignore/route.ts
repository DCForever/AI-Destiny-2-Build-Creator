import { NextResponse } from "next/server";
import { z } from "zod";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { unauthorizedResponse } from "@/lib/api/response";
import {
  addIgnoredSynergyTypeKeys,
  readUserPreferences,
  removeIgnoredSynergyTypeKeys,
  writeUserPreferences,
} from "@/lib/preferences/store";

export const runtime = "nodejs";

const bodySchema = z.object({
  action: z.enum(["add", "remove", "clear"]),
  /** Coverage keys (e.g. verb::Sliding). Required for add/remove. */
  keys: z.array(z.string().trim().min(1).max(160)).max(500).optional(),
});

/**
 * Persist ignore list for missing-type gaps so they stay hidden on future scans.
 */
export async function GET(request: Request): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const prefs = await readUserPreferences(auth.user.bungieMembershipId);
  const keys = prefs.ignoredSynergyTypeKeys ?? [];
  return NextResponse.json({ keys, count: keys.length });
}

export async function POST(request: Request): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const parsed = bodySchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues.map((i) => i.message).join("; ") },
      { status: 400 },
    );
  }

  const existing = await readUserPreferences(auth.user.bungieMembershipId);
  let next = existing;

  if (parsed.data.action === "clear") {
    next = { ...existing, ignoredSynergyTypeKeys: [] };
  } else if (parsed.data.action === "add") {
    const keys = parsed.data.keys ?? [];
    if (keys.length === 0) {
      return NextResponse.json({ error: "keys required for add" }, { status: 400 });
    }
    next = addIgnoredSynergyTypeKeys(existing, keys);
  } else {
    const keys = parsed.data.keys ?? [];
    if (keys.length === 0) {
      return NextResponse.json(
        { error: "keys required for remove" },
        { status: 400 },
      );
    }
    next = removeIgnoredSynergyTypeKeys(existing, keys);
  }

  await writeUserPreferences(auth.user.bungieMembershipId, next);
  const keys = next.ignoredSynergyTypeKeys ?? [];
  return NextResponse.json({ keys, count: keys.length });
}
