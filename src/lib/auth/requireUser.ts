import { getValidTokens, getSession } from "@/lib/bungie/session";
import { createBungieAuthClient } from "@/lib/bungie/oauth";
import { getDb } from "@/lib/db/client";
import { getUserByMembershipId, ensureUser } from "@/lib/db/repositories/userRepository";
import type { DbUser } from "@/lib/db/types";

export interface AuthenticatedUser {
  tokens: NonNullable<Awaited<ReturnType<typeof getValidTokens>>>;
  user: DbUser;
}

export async function requireAuthenticatedUser(request: Request): Promise<AuthenticatedUser | null> {
  const session = await getSession();
  const redirectUri = new URL("/api/auth/callback", request.url).toString();
  const authClient = createBungieAuthClient(redirectUri);
  if (!authClient) return null;

  const tokens = await getValidTokens(session, authClient);
  if (!tokens) return null;

  const db = getDb();
  let user = getUserByMembershipId(db, tokens.bungieMembershipId);
  if (!user) {
    user = ensureUser(db, tokens.bungieMembershipId, 0, "");
  }

  return { tokens, user };
}
