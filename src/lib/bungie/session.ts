import { getIronSession, type IronSession } from "iron-session";
import { cookies } from "next/headers";

import { getSessionSecret } from "@/lib/config/env";
import type { BungieAuthClient, BungieTokens, SessionData } from "./types";
import { needsRefresh, isSessionExpired } from "./oauth";

const COOKIE_NAME = "d2bc_session";

function buildSessionOptions(secret: string) {
  return {
    cookieName: COOKIE_NAME,
    password: secret,
    cookieOptions: {
      httpOnly: true,
      sameSite: "lax" as const,
      secure: true,
    },
  };
}

export async function getSession(): Promise<IronSession<SessionData>> {
  const secret = getSessionSecret();
  if (!secret) {
    throw new Error(
      "SESSION_SECRET is not configured or is too short (minimum 32 characters)",
    );
  }
  const cookieStore = await cookies();
  return getIronSession<SessionData>(cookieStore, buildSessionOptions(secret));
}

export async function getValidTokens(
  session: IronSession<SessionData>,
  authClient: BungieAuthClient,
): Promise<BungieTokens | null> {
  const { tokens } = session;
  if (!tokens) return null;
  if (isSessionExpired(tokens)) return null;
  if (!needsRefresh(tokens)) return tokens;

  const refreshed = await authClient.refreshTokens(tokens);
  session.tokens = refreshed;
  await session.save();
  return refreshed;
}
