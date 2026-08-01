import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { apiErrorResponse, unauthorizedResponse } from "@/lib/api/response";
import { getBuildDetail, updateUserVariant } from "@/lib/builds/buildService";
import { updateVariantSchema } from "@/lib/builds/schemas";
import { deleteUserVariant } from "@/lib/builds/variantService";
import { getDb } from "@/lib/db/client";

export const runtime = "nodejs";

type RouteContext = { params: Promise<{ id: string; variantId: string }> };

export async function GET(request: Request, context: RouteContext): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const { id, variantId } = await context.params;
  const db = getDb();
  const build = await getBuildDetail(db, auth.user.id, id);
  if (!build) return NextResponse.json({ error: "Not found" }, { status: 404 });

  const variant = build.variants.find((v) => v.id === variantId);
  if (!variant) return NextResponse.json({ error: "Variant not found" }, { status: 404 });
  return NextResponse.json({ variant });
}

export async function PATCH(request: Request, context: RouteContext): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const { id, variantId } = await context.params;
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Request body must be JSON" }, { status: 400 });
  }

  const parsed = updateVariantSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues.map((i) => i.message).join("; ") },
      { status: 400 },
    );
  }

  try {
    const db = getDb();
    const build = await updateUserVariant(db, auth.user.id, id, variantId, parsed.data);
    if (!build) return NextResponse.json({ error: "Not found" }, { status: 404 });
    return NextResponse.json({ build });
  } catch (error) {
    return apiErrorResponse(error);
  }
}

export async function DELETE(request: Request, context: RouteContext): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const { id, variantId } = await context.params;

  try {
    const db = getDb();
    const deleted = deleteUserVariant(db, auth.user.id, id, variantId);
    if (!deleted) return NextResponse.json({ error: "Not found" }, { status: 404 });
    return NextResponse.json({ ok: true });
  } catch (error) {
    return apiErrorResponse(error);
  }
}
