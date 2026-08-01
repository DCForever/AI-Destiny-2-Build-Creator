import { NextResponse } from "next/server";
import { z } from "zod";

import { requireAuthenticatedUser } from "@/lib/auth/requireUser";
import { getDb } from "@/lib/db/client";
import { createLoadout, listLoadouts } from "@/lib/db/repositories/loadoutRepository";
import type { SavedLoadout } from "@/lib/db/types";
import { buildRequestSchema, generatedBuildSchema } from "@/lib/llm/buildSchema";
import { buildFilteredLoadoutList } from "@/lib/loadouts/loadoutListApi";
import {
  InvalidLoadoutFilterError,
  parseLoadoutFilterQuery,
} from "@/lib/loadouts/parseFilterQuery";
import { getServices } from "@/lib/services";
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

async function loadManifestStores() {
  const { entityCache } = await getServices();
  const [exoticArmor, exoticWeapons] = await Promise.all([
    entityCache.getStore("exotic-armor"),
    entityCache.getStore("exotic-weapons"),
  ]);
  return { exoticArmor, exoticWeapons };
}

export async function GET(request: Request): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorized();

  let criteria;
  try {
    criteria = parseLoadoutFilterQuery(new URL(request.url).searchParams);
  } catch (error) {
    if (error instanceof InvalidLoadoutFilterError) {
      return NextResponse.json({ error: "INVALID_FILTER" }, { status: 400 });
    }
    throw error;
  }

  const db = getDb();
  const loadouts = listLoadouts(db, auth.user.id);
  const manifest = await loadManifestStores();
  const body = buildFilteredLoadoutList(loadouts, criteria, manifest);
  return NextResponse.json(body);
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
