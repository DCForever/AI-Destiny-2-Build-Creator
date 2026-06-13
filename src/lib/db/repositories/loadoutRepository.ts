import { eq, and, desc } from "drizzle-orm";

import type { AppDatabase } from "../client";
import { loadouts } from "../schema";
import type { SavedLoadout } from "../types";

export function listLoadouts(db: AppDatabase, userId: number): SavedLoadout[] {
  const rows = db
    .select()
    .from(loadouts)
    .where(eq(loadouts.userId, userId))
    .orderBy(desc(loadouts.updatedAt))
    .all();
  return rows.map(rowToSavedLoadout);
}

export function getLoadout(db: AppDatabase, userId: number, id: string): SavedLoadout | null {
  const row = db
    .select()
    .from(loadouts)
    .where(and(eq(loadouts.id, id), eq(loadouts.userId, userId)))
    .get();
  return row ? rowToSavedLoadout(row) : null;
}

export function createLoadout(db: AppDatabase, userId: number, loadout: SavedLoadout): SavedLoadout {
  db.insert(loadouts)
    .values({
      id: loadout.id,
      userId,
      name: loadout.name,
      source: loadout.source,
      manifestVersion: loadout.manifestVersion,
      buildRequest: loadout.buildRequest ? JSON.stringify(loadout.buildRequest) : null,
      generatedBuild: JSON.stringify(loadout.generatedBuild),
      resolvedSheet: JSON.stringify(loadout.resolvedSheet),
      createdAt: loadout.createdAt,
      updatedAt: loadout.updatedAt,
    })
    .run();
  return loadout;
}

export function updateLoadout(
  db: AppDatabase,
  userId: number,
  id: string,
  patch: Partial<Pick<SavedLoadout, "name" | "generatedBuild" | "resolvedSheet" | "manifestVersion">>,
): SavedLoadout | null {
  const existing = getLoadout(db, userId, id);
  if (!existing) return null;

  const updated: SavedLoadout = {
    ...existing,
    ...patch,
    updatedAt: new Date().toISOString(),
  };

  db.update(loadouts)
    .set({
      name: updated.name,
      manifestVersion: updated.manifestVersion,
      generatedBuild: JSON.stringify(updated.generatedBuild),
      resolvedSheet: JSON.stringify(updated.resolvedSheet),
      updatedAt: updated.updatedAt,
    })
    .where(and(eq(loadouts.id, id), eq(loadouts.userId, userId)))
    .run();

  return updated;
}

export function deleteLoadout(db: AppDatabase, userId: number, id: string): boolean {
  const result = db
    .delete(loadouts)
    .where(and(eq(loadouts.id, id), eq(loadouts.userId, userId)))
    .run();
  return result.changes > 0;
}

function rowToSavedLoadout(row: typeof loadouts.$inferSelect): SavedLoadout {
  return {
    id: row.id,
    name: row.name,
    source: row.source as SavedLoadout["source"],
    manifestVersion: row.manifestVersion,
    buildRequest: row.buildRequest ? JSON.parse(row.buildRequest) : undefined,
    generatedBuild: JSON.parse(row.generatedBuild),
    resolvedSheet: JSON.parse(row.resolvedSheet),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}
