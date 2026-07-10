import { NextResponse } from "next/server";
import { z } from "zod";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import { apiErrorResponse, unauthorizedResponse } from "@/lib/api/response";
import { assertEquipReady } from "@/lib/builds/equipReady";
import { getBuildDetail, getResolvedVariant } from "@/lib/builds/buildService";
import { planEquipSteps } from "@/lib/builds/equipPlan";
import { executeEquipPlan } from "@/lib/builds/equipOrchestrator";
import { createBungieProfileClient } from "@/lib/bungie/profile";
import { createBungieWriteClient } from "@/lib/bungie/writeClient";
import { syncIfStale } from "@/lib/bungie/syncFreshness";
import { getBungieOAuthConfig, getSessionSecret } from "@/lib/config/env";
import { getDb } from "@/lib/db/client";
import { listInventoryItems } from "@/lib/db/repositories/inventoryRepository";
import { getServices, ManifestNotReadyError } from "@/lib/services";

export const runtime = "nodejs";

type RouteContext = { params: Promise<{ id: string; variantId: string }> };

const bodySchema = z.object({
  characterId: z.string().min(1),
});

const NOT_CONFIGURED = {
  error: "Bungie sign-in is not configured. Set BUNGIE_* and SESSION_SECRET in .env.local.",
};

export async function POST(request: Request, context: RouteContext): Promise<NextResponse> {
  if (!getBungieOAuthConfig() || !getSessionSecret()) {
    return NextResponse.json(NOT_CONFIGURED, { status: 503 });
  }

  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const profileClient = createBungieProfileClient();
  const writeClient = createBungieWriteClient();
  if (!profileClient || !writeClient) {
    return NextResponse.json(NOT_CONFIGURED, { status: 503 });
  }

  const { id, variantId } = await context.params;

  let parsed: z.infer<typeof bodySchema>;
  try {
    parsed = bodySchema.parse(await request.json());
  } catch {
    return NextResponse.json({ error: "Invalid JSON body; expected { characterId }" }, { status: 400 });
  }

  try {
    const db = getDb();
    const detail = await getBuildDetail(db, auth.user.id, id);
    if (!detail) return NextResponse.json({ error: "Not found" }, { status: 404 });

    const resolved = await getResolvedVariant(db, auth.user.id, id, variantId);
    if (!resolved) return NextResponse.json({ error: "Not found" }, { status: 404 });

    assertEquipReady({ equipReady: resolved.equipReady, pinStatuses: resolved.pinStatuses });

    const memberships = await profileClient.getMemberships(auth.tokens.accessToken);
    const membership = memberships[0];
    if (!membership) {
      return NextResponse.json({ error: "No Destiny memberships found" }, { status: 404 });
    }
    const characters = await profileClient.getCharacters(auth.tokens.accessToken, membership);
    const character = characters.find((c) => c.characterId === parsed.characterId);
    if (!character || character.classType !== detail.className) {
      throw new ApiError(
        API_ERROR_CODES.INVALID_CHARACTER,
        "Character does not match build class",
        { characterId: parsed.characterId, buildClass: detail.className },
        400,
      );
    }

    const { entityCache, manifest } = await getServices();
    const manifestStatus = await manifest.getStatus();
    if (!manifestStatus.cachedVersion) {
      return NextResponse.json(
        { error: "Manifest not ready. Refresh the manifest from Settings first." },
        { status: 503 },
      );
    }

    await syncIfStale(
      db,
      auth.user,
      auth.tokens.accessToken,
      profileClient,
      entityCache,
      manifest,
      manifestStatus.cachedVersion,
    );

    const inventory = listInventoryItems(db, auth.user.id);
    const plan = planEquipSteps({
      equipment: resolved.equipment,
      artifact: resolved.artifact,
      fashion: resolved.fashion,
      inventory,
      characterId: parsed.characterId,
    });

    const status = await executeEquipPlan(
      writeClient,
      { accessToken: auth.tokens.accessToken, membershipType: membership.membershipType },
      parsed.characterId,
      plan,
    );

    return NextResponse.json({ status });
  } catch (error) {
    if (error instanceof ManifestNotReadyError) {
      return NextResponse.json({ error: error.message }, { status: 503 });
    }
    return apiErrorResponse(error);
  }
}
