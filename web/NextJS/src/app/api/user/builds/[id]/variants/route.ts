import { NextResponse } from "next/server";
import { z } from "zod";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { apiErrorResponse, unauthorizedResponse } from "@/lib/api/response";
import { buildVariantSchema } from "@/lib/builds/schemas";
import { createUserVariant } from "@/lib/builds/variantService";
import { getDb } from "@/lib/db/client";

export const runtime = "nodejs";

type RouteContext = { params: Promise<{ id: string }> };

const createVariantSchema = buildVariantSchema.extend({
  duplicateFromVariantId: z.string().min(1).optional(),
});

export async function POST(request: Request, context: RouteContext): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const { id } = await context.params;
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = createVariantSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.issues.map((i) => i.message).join("; ") }, { status: 400 });
  }

  try {
    const db = getDb();
    const build = await createUserVariant(db, auth.user.id, id, parsed.data);
    if (!build) return NextResponse.json({ error: "Not found" }, { status: 404 });
    return NextResponse.json({ build }, { status: 201 });
  } catch (error) {
    return apiErrorResponse(error);
  }
}
