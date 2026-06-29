import { and, eq, inArray } from "drizzle-orm";

import type { AppDatabase } from "@/lib/db/client";
import { synergies, synergyLinks } from "@/lib/db/schema";
import type { SynergyType } from "@/lib/synergies/schemas";

export type SynergyRecord = {
  id: string;
  userId: number;
  name: string;
  type: SynergyType;
  description: string;
  createdAt: string;
  updatedAt: string;
};

export type SynergyLinkRecord = {
  id: string;
  synergyId: string;
  kind: string;
  displayName: string;
  itemHash: number | null;
  perkHash: number | null;
  parentItemHash: number | null;
  originTraitName: string | null;
  originTraitHash: number | null;
  armorSetName: string | null;
  bonusPieces: number | null;
  bonusName: string | null;
  armorSetHash: number | null;
};

export type SynergyWithLinks = SynergyRecord & { links: SynergyLinkRecord[] };

export function listSynergies(db: AppDatabase, userId: number): SynergyWithLinks[] {
  const rows = db.select().from(synergies).where(eq(synergies.userId, userId)).all();
  return rows.map((row) => ({
    ...rowToSynergy(row),
    links: listSynergyLinks(db, row.id),
  }));
}

export function getSynergy(db: AppDatabase, userId: number, id: string): SynergyWithLinks | null {
  const row = db
    .select()
    .from(synergies)
    .where(and(eq(synergies.id, id), eq(synergies.userId, userId)))
    .get();
  if (!row) return null;
  return { ...rowToSynergy(row), links: listSynergyLinks(db, row.id) };
}

export function getSynergiesByIds(db: AppDatabase, userId: number, ids: string[]): SynergyWithLinks[] {
  if (ids.length === 0) return [];
  const rows = db
    .select()
    .from(synergies)
    .where(and(eq(synergies.userId, userId), inArray(synergies.id, ids)))
    .all();
  return rows.map((row) => ({ ...rowToSynergy(row), links: listSynergyLinks(db, row.id) }));
}

function listSynergyLinks(db: AppDatabase, synergyId: string): SynergyLinkRecord[] {
  return db.select().from(synergyLinks).where(eq(synergyLinks.synergyId, synergyId)).all();
}

export function seedDefaultSynergies(db: AppDatabase, userId: number): SynergyWithLinks[] {
  const existing = listSynergies(db, userId);
  if (existing.length > 0) return existing;

  const now = new Date().toISOString();
  const meleeId = crypto.randomUUID();
  db.insert(synergies)
    .values({
      id: meleeId,
      userId,
      name: "Melee Combo",
      type: "melee",
      description: "Default melee synergy for dev/testing",
      createdAt: now,
      updatedAt: now,
    })
    .run();

  return listSynergies(db, userId);
}

function rowToSynergy(row: typeof synergies.$inferSelect): SynergyRecord {
  return {
    id: row.id,
    userId: row.userId,
    name: row.name,
    type: row.type as SynergyType,
    description: row.description,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}
