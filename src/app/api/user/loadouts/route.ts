import { NextResponse } from "next/server";
import { z } from "zod";

import { requireAuthenticatedUser } from "@/lib/auth/requireUser";
import { getDb } from "@/lib/db/client";
import { createLoadout, listLoadouts } from "@/lib/db/repositories/loadoutRepository";
import type { SavedLoadout } from "@/lib/db/types";
import { buildRequestSchema, generatedBuildSchema } from "@/lib/llm/buildSchema";
import { getManifestStatus } from "@/lib/services";

export const runtime = "nodejs";

function unauthorized() {
  return NextResponse.json({ error: "Not signed in" }, { status: 401 });
}

const createLoadoutSchema = z.object({
  name: z.string().trim().min(1).max(120),
  source: z.enum(["generator", "analyzer", "manual-edit"]),
  buildRequest: buildRequestSchema.optional(),
  generatedBuild: generatedBuildSchema,
  resolvedSheet: z.unknown(),
  manifestVersion: z.string().trim().min(1).optional(),
});

function toSummary(loadout: SavedLoadout) {
  return {
    id: loadout.id,
    name: loadout.name,
    source: loadout.source,
    className: loadout.buildRequest?.className,
    createdAt: loadout.createdAt,
    updatedAt: loadout.updatedAt,
    manifestVersion: loadout.manifestVersion,
  };
}

export async function GET(request: Request): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorized();

  const db = getDb();
  const loadouts = listLoadouts(db, auth.user.id);
  return NextResponse.json({ loadouts: loadouts.map(toSummary) });
}

export async function POST(request: Request): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorized();

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Request body must be JSON" }, { status: 400 });
  }

  const parsed = createLoadoutSchema.safeParse(body);
  if (!parsed.success) {
    const issues = parsed.error.issues
      .map((issue) => `${issue.path.join(".")}: ${issue.message}`)
      .join("; ");
    return NextResponse.json({ error: `Invalid loadout: ${issues}` }, { status: 400 });
  }

  let manifestVersion = parsed.data.manifestVersion;
  if (!manifestVersion) {
    const status = await getManifestStatus();
    manifestVersion = status.cachedVersion ?? "unknown";
  }

  const now = new Date().toISOString();
  const loadout: SavedLoadout = {
    id: crypto.randomUUID(),
    name: parsed.data.name,
    source: parsed.data.source,
    manifestVersion,
    buildRequest: parsed.data.buildRequest,
    generatedBuild: parsed.data.generatedBuild,
    resolvedSheet: parsed.data.resolvedSheet as SavedLoadout["resolvedSheet"],
    createdAt: now,
    updatedAt: now,
  };

  const db = getDb();
  createLoadout(db, auth.user.id, loadout);
  return NextResponse.json({ loadout }, { status: 201 });
}
