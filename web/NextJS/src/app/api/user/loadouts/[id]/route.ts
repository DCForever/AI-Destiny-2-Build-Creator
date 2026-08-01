import { NextResponse } from "next/server";
import { z } from "zod";

import { requireAuthenticatedUser } from "@/lib/auth/requireUser";
import { getDb } from "@/lib/db/client";
import {
  deleteLoadout,
  getLoadout,
  updateLoadout,
} from "@/lib/db/repositories/loadoutRepository";
import { generatedBuildSchema } from "@/lib/llm/buildSchema";

export const runtime = "nodejs";

function unauthorized() {
  return NextResponse.json({ error: "Not signed in" }, { status: 401 });
}

function notFound() {
  return NextResponse.json({ error: "Loadout not found" }, { status: 404 });
}

const updateLoadoutSchema = z.object({
  name: z.string().trim().min(1).max(120).optional(),
  generatedBuild: generatedBuildSchema.optional(),
  resolvedSheet: z.unknown().optional(),
  manifestVersion: z.string().trim().min(1).optional(),
});

type RouteContext = { params: Promise<{ id: string }> };

export async function GET(request: Request, context: RouteContext): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorized();

  const { id } = await context.params;
  const db = getDb();
  const loadout = getLoadout(db, auth.user.id, id);
  if (!loadout) return notFound();

  return NextResponse.json({ loadout });
}

export async function PUT(request: Request, context: RouteContext): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorized();

  const { id } = await context.params;

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Request body must be JSON" }, { status: 400 });
  }

  const parsed = updateLoadoutSchema.safeParse(body);
  if (!parsed.success) {
    const issues = parsed.error.issues
      .map((issue) => `${issue.path.join(".")}: ${issue.message}`)
      .join("; ");
    return NextResponse.json({ error: `Invalid loadout update: ${issues}` }, { status: 400 });
  }

  const db = getDb();
  const existing = getLoadout(db, auth.user.id, id);
  if (!existing) return notFound();

  const updated = updateLoadout(db, auth.user.id, id, {
    ...(parsed.data.name !== undefined ? { name: parsed.data.name } : {}),
    ...(parsed.data.generatedBuild !== undefined
      ? { generatedBuild: parsed.data.generatedBuild }
      : {}),
    ...(parsed.data.resolvedSheet !== undefined
      ? { resolvedSheet: parsed.data.resolvedSheet as typeof existing.resolvedSheet }
      : {}),
    ...(parsed.data.manifestVersion !== undefined
      ? { manifestVersion: parsed.data.manifestVersion }
      : {}),
  });

  if (!updated) return notFound();
  return NextResponse.json({ loadout: updated });
}

export async function DELETE(request: Request, context: RouteContext): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorized();

  const { id } = await context.params;
  const db = getDb();
  const existing = getLoadout(db, auth.user.id, id);
  if (!existing) return notFound();

  deleteLoadout(db, auth.user.id, id);
  return new NextResponse(null, { status: 204 });
}
