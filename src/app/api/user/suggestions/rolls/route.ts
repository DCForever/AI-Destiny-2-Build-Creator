import { NextResponse } from "next/server";
import { z } from "zod";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { unauthorizedResponse } from "@/lib/api/response";
import { getDb } from "@/lib/db/client";
import { suggestRollsForUser } from "@/lib/suggestions/suggestRollsService";

export const runtime = "nodejs";

const bodySchema = z.object({
  setId: z.string().min(1).optional(),
  synergyIds: z.array(z.string().min(1)).optional(),
  buildId: z.string().min(1).optional(),
  limit: z.number().int().positive().max(20).optional(),
});

export async function POST(request: Request): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = bodySchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.issues.map((i) => i.message).join("; ") }, { status: 400 });
  }

  const db = getDb();
  const result = await suggestRollsForUser(db, auth.user.id, parsed.data);
  if (!result) return NextResponse.json({ error: "Not found" }, { status: 404 });

  return NextResponse.json(result);
}
