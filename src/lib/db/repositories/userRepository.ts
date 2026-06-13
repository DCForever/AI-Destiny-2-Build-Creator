import { eq } from "drizzle-orm";

import type { AppDatabase } from "../client";
import { users } from "../schema";
import type { DbUser } from "../types";

export function ensureUser(
  db: AppDatabase,
  bungieMembershipId: string,
  membershipType: number,
  displayName: string,
): DbUser {
  const existing = db.select().from(users).where(eq(users.bungieMembershipId, bungieMembershipId)).get();
  if (existing) {
    if (existing.displayName !== displayName || existing.membershipType !== membershipType) {
      db.update(users)
        .set({ displayName, membershipType })
        .where(eq(users.id, existing.id))
        .run();
    }
    return rowToUser(existing);
  }
  const inserted = db
    .insert(users)
    .values({ bungieMembershipId, membershipType, displayName })
    .returning()
    .get();
  return rowToUser(inserted);
}

export function getUserByMembershipId(
  db: AppDatabase,
  bungieMembershipId: string,
): DbUser | null {
  const row = db.select().from(users).where(eq(users.bungieMembershipId, bungieMembershipId)).get();
  return row ? rowToUser(row) : null;
}

export function getUserById(db: AppDatabase, id: number): DbUser | null {
  const row = db.select().from(users).where(eq(users.id, id)).get();
  return row ? rowToUser(row) : null;
}

function rowToUser(row: typeof users.$inferSelect): DbUser {
  return {
    id: row.id,
    bungieMembershipId: row.bungieMembershipId,
    membershipType: row.membershipType,
    displayName: row.displayName,
    lastSyncAt: row.lastSyncAt,
  };
}
