import { NextResponse } from "next/server";
import { z } from "zod";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { apiErrorResponse, unauthorizedResponse } from "@/lib/api/response";
import { assertEquipReady } from "@/lib/builds/equipReady";
import { getBuildDetail, getResolvedVariant } from "@/lib/builds/buildService";
import { createBungieProfileClient } from "@/lib/bungie/profile";
import { getBungieOAuthConfig, getSessionSecret } from "@/lib/config/env";
import { getDb } from "@/lib/db/client";
import { buildVariantDimLoadout } from "@/lib/dim/buildVariantDimLoadout";
import { collectVariantMods } from "@/lib/dim/collectVariantMods";
import { createDimSyncClient } from "@/lib/dim/dimSync";

export const runtime = "nodejs";

type RouteContext = { params: Promise<{ id: string; variantId: string }> };

const bodySchema = z
  .object({
    jsonOnly: z.boolean().optional(),
  })
  .optional();

export async function POST(request: Request, context: RouteContext): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const { id, variantId } = await context.params;

  let jsonOnly = false;
  try {
    const text = await request.text();
    if (text.trim()) {
      const parsed = bodySchema.parse(JSON.parse(text));
      jsonOnly = parsed?.jsonOnly === true;
    }
  } catch {
    return NextResponse.json(
      { error: "Invalid JSON body; expected optional { jsonOnly?: boolean }" },
      { status: 400 },
    );
  }

  try {
    const db = getDb();
    const detail = await getBuildDetail(db, auth.user.id, id);
    if (!detail) return NextResponse.json({ error: "Not found" }, { status: 404 });

    const resolved = await getResolvedVariant(db, auth.user.id, id, variantId);
    if (!resolved) return NextResponse.json({ error: "Not found" }, { status: 404 });

    assertEquipReady({ equipReady: resolved.equipReady, pinStatuses: resolved.pinStatuses });

    const variant = detail.variants.find((v) => v.id === variantId);
    const modHashes = await collectVariantMods(db, auth.user.id, variantId);
    const className = detail.className as "Titan" | "Hunter" | "Warlock";
    const loadout = buildVariantDimLoadout({
      buildName: detail.name,
      className,
      variantName: variant?.name,
      subclass: detail.subclass,
      softStatTargets: detail.softStatTargets,
      equipment: resolved.equipment,
      artifact: resolved.artifact,
      fashion: resolved.fashion,
      modHashes,
    });

    if (jsonOnly) {
      return NextResponse.json({ loadout });
    }

    const dimClient = createDimSyncClient();
    if (!dimClient) {
      return NextResponse.json(
        {
          error: "dim.gg sharing is not configured. Set DIM_API_KEY in .env.local.",
          code: "DIM_NOT_CONFIGURED",
        },
        { status: 503 },
      );
    }

    if (!getBungieOAuthConfig() || !getSessionSecret()) {
      return NextResponse.json(
        {
          error:
            "dim.gg sharing requires Bungie sign-in. Configure BUNGIE_* and SESSION_SECRET.",
        },
        { status: 503 },
      );
    }

    const profileClient = createBungieProfileClient();
    if (!profileClient) {
      return NextResponse.json(
        {
          error:
            "dim.gg sharing requires Bungie sign-in. Configure BUNGIE_* and SESSION_SECRET.",
        },
        { status: 503 },
      );
    }

    const memberships = await profileClient.getMemberships(auth.tokens.accessToken);
    const membership = memberships[0];
    if (!membership) {
      return NextResponse.json({ error: "No Destiny memberships found" }, { status: 404 });
    }

    const dimToken = await dimClient.getAuthToken(
      auth.tokens.accessToken,
      auth.tokens.bungieMembershipId,
    );
    const { shareUrl } = await dimClient.shareLoadout(
      dimToken,
      membership.membershipId,
      loadout,
    );

    return NextResponse.json({ loadout, shareUrl });
  } catch (error) {
    if (error instanceof Error && error.message.startsWith("DIM Sync")) {
      return NextResponse.json({ error: error.message }, { status: 502 });
    }
    return apiErrorResponse(error);
  }
}
