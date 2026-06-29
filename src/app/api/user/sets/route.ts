import { NextResponse } from "next/server";
import { z } from "zod";

import { isConceptTagId } from "@/data/conceptTags";
import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { apiErrorResponse, unauthorizedResponse } from "@/lib/api/response";
import { getDb } from "@/lib/db/client";
import { createSetSchema, setTypeSchema } from "@/lib/sets/schemas";
import { createUserSet, listUserSets } from "@/lib/sets/setService";

export const runtime = "nodejs";

export async function GET(request: Request): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const url = new URL(request.url);
  const typeRaw = url.searchParams.get("type");
  const tagsRaw = url.searchParams.get("tags");

  let type: z.infer<typeof setTypeSchema> | undefined;
  if (typeRaw) {
    const parsed = setTypeSchema.safeParse(typeRaw);
    if (!parsed.success) {
      return NextResponse.json({ error: "Invalid type" }, { status: 400 });
    }
    type = parsed.data;
  }

  const tags = tagsRaw
    ? tagsRaw.split(",").map((t) => t.trim()).filter(Boolean)
    : undefined;
  if (tags?.some((t) => !isConceptTagId(t))) {
    return NextResponse.json({ error: "Invalid tag in filter" }, { status: 400 });
  }

  const db = getDb();
  const sets = listUserSets(db, auth.user.id, { type, tags: tags as typeof tags & undefined });
  return NextResponse.json({ sets });
}

export async function POST(request: Request): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Request body must be JSON" }, { status: 400 });
  }

  const parsed = createSetSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues.map((i) => i.message).join("; ") },
      { status: 400 },
    );
  }

  try {
    const db = getDb();
    const set = await createUserSet(db, auth.user.id, parsed.data);
    return NextResponse.json({ set }, { status: 201 });
  } catch (error) {
    return apiErrorResponse(error);
  }
}
