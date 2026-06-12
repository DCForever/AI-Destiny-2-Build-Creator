import { NextResponse } from "next/server";

import { getBungieOAuthConfig, getSessionSecret } from "@/lib/config/env";
import { createBungieAuthClient } from "@/lib/bungie/oauth";
import { createBungieProfileClient } from "@/lib/bungie/profile";
import { getSession, getValidTokens } from "@/lib/bungie/session";
import { equipmentToLoadoutText } from "@/lib/bungie/loadoutText";
import { getServices } from "@/lib/services";

export const runtime = "nodejs";

const NOT_CONFIGURED = {
  error: "Bungie sign-in is not configured. Set BUNGIE_* and SESSION_SECRET in .env.local.",
};

export async function GET(request: Request): Promise<NextResponse> {
  if (!getBungieOAuthConfig() || !getSessionSecret()) {
    return NextResponse.json(NOT_CONFIGURED, { status: 503 });
  }

  const url = new URL(request.url);
  const membershipType = url.searchParams.get("membershipType");
  const membershipId = url.searchParams.get("membershipId");
  const characterId = url.searchParams.get("characterId");

  if (!membershipType || !membershipId || !characterId) {
    return NextResponse.json(
      { error: "Query params membershipType, membershipId, and characterId are required" },
      { status: 400 },
    );
  }

  const redirectUri = new URL("/api/auth/callback", request.url).toString();
  const authClient = createBungieAuthClient(redirectUri);
  const profileClient = createBungieProfileClient();
  if (!authClient || !profileClient) {
    return NextResponse.json(NOT_CONFIGURED, { status: 503 });
  }

  const session = await getSession();
  const tokens = await getValidTokens(session, authClient);
  if (!tokens) {
    return NextResponse.json({ error: "Not signed in" }, { status: 401 });
  }

  const membership = {
    membershipType: Number(membershipType),
    membershipId,
    displayName: "",
  };

  let equipment;
  try {
    equipment = await profileClient.getCharacterEquipment(
      tokens.accessToken,
      membership,
      characterId,
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to fetch equipment";
    return NextResponse.json({ error: message }, { status: 502 });
  }

  let loadoutText: string | null = null;
  try {
    const { entityCache } = await getServices();
    loadoutText = await equipmentToLoadoutText(equipment, entityCache);
  } catch {
    // entity cache not built yet — return equipment without loadout text
  }

  return NextResponse.json({ equipment, loadoutText });
}
