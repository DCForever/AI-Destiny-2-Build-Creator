import { NextResponse } from "next/server";

import { isConceptTagId } from "@/data/conceptTags";
import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { apiErrorResponse, unauthorizedResponse } from "@/lib/api/response";
import { createUserBuild, listUserBuilds } from "@/lib/builds/buildService";
import { createBuildSchema } from "@/lib/builds/schemas";
import { getDb } from "@/lib/db/client";
import { seedDefaultSynergies } from "@/lib/db/repositories/synergyRepository";

export const runtime = "nodejs";

export async function GET(request: Request): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const url = new URL(request.url);
  const tagsRaw = url.searchParams.get("tags");
  const tags = tagsRaw
    ? tagsRaw.split(",").map((t) => t.trim()).filter(Boolean)
    : undefined;
  if (tags?.some((t) => !isConceptTagId(t))) {
    return NextResponse.json({ error: "Invalid tag in filter" }, { status: 400 });
  }

  const exoticArmorRaw = url.searchParams.get("exoticArmorHash");
  const exoticWeaponRaw = url.searchParams.get("exoticWeaponHash");
  const synergyId = url.searchParams.get("synergyId") ?? undefined;

  const exoticArmorHash = exoticArmorRaw ? Number(exoticArmorRaw) : undefined;
  const exoticWeaponHash = exoticWeaponRaw ? Number(exoticWeaponRaw) : undefined;
  if (exoticArmorRaw && Number.isNaN(exoticArmorHash)) {
    return NextResponse.json({ error: "Invalid exoticArmorHash" }, { status: 400 });
  }
  if (exoticWeaponRaw && Number.isNaN(exoticWeaponHash)) {
    return NextResponse.json({ error: "Invalid exoticWeaponHash" }, { status: 400 });
  }

  const db = getDb();
  const builds = listUserBuilds(db, auth.user.id, {
    tags: tags as typeof tags & undefined,
    exoticArmorHash,
    exoticWeaponHash,
    synergyId,
  });
  return NextResponse.json({ builds });
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

  const parsed = createBuildSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues.map((i) => i.message).join("; ") },
      { status: 400 },
    );
  }

  try {
    const db = getDb();
    seedDefaultSynergies(db, auth.user.id);
    const build = await createUserBuild(db, auth.user.id, parsed.data);
    return NextResponse.json({ build }, { status: 201 });
  } catch (error) {
    return apiErrorResponse(error);
  }
}
