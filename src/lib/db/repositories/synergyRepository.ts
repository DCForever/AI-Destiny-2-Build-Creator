import { and, eq, inArray, sql } from "drizzle-orm";

import type { AppDatabase } from "@/lib/db/client";
import { synergies, synergyLinks } from "@/lib/db/schema";
import type { SynergyLinkInput } from "@/lib/synergies/schemas";
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

export type SynergyTargetQuery = {
  kind: string;
  name?: string;
  itemHash?: number;
  perkHash?: number;
  originTraitHash?: number;
  armorSetName?: string;
  bonusPieces?: number;
  bonusName?: string;
};

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

function listSynergyLinks(db: AppDatabase, synergyId: string): SynergyLinkRecord[] {
  return db.select().from(synergyLinks).where(eq(synergyLinks.synergyId, synergyId)).all();
}

function insertLinks(db: AppDatabase, synergyId: string, links: SynergyLinkInput[]): void {
  for (const link of links) {
    db.insert(synergyLinks)
      .values({
        id: crypto.randomUUID(),
        synergyId,
        kind: link.kind,
        displayName: link.displayName,
        itemHash: link.itemHash ?? null,
        perkHash: link.perkHash ?? null,
        parentItemHash: link.parentItemHash ?? null,
        originTraitName: link.originTraitName ?? null,
        originTraitHash: link.originTraitHash ?? null,
        armorSetName: link.armorSetName ?? null,
        bonusPieces: link.bonusPieces ?? null,
        bonusName: link.bonusName ?? null,
        armorSetHash: link.armorSetHash ?? null,
      })
      .run();
  }
}

export function listSynergies(db: AppDatabase, userId: number, type?: SynergyType): SynergyWithLinks[] {
  const rows = db
    .select()
    .from(synergies)
    .where(type ? and(eq(synergies.userId, userId), eq(synergies.type, type)) : eq(synergies.userId, userId))
    .all();
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

export function createSynergyRecord(
  db: AppDatabase,
  userId: number,
  input: {
    id: string;
    name: string;
    type: SynergyType;
    description: string;
    links: SynergyLinkInput[];
    now: string;
  },
): SynergyWithLinks {
  db.insert(synergies)
    .values({
      id: input.id,
      userId,
      name: input.name,
      type: input.type,
      description: input.description,
      createdAt: input.now,
      updatedAt: input.now,
    })
    .run();

  insertLinks(db, input.id, input.links);
  return getSynergy(db, userId, input.id)!;
}

export function updateSynergyRecord(
  db: AppDatabase,
  userId: number,
  id: string,
  patch: {
    name?: string;
    type?: SynergyType;
    description?: string;
    links?: SynergyLinkInput[];
    now: string;
  },
): SynergyWithLinks | null {
  const existing = getSynergy(db, userId, id);
  if (!existing) return null;

  db.update(synergies)
    .set({
      name: patch.name ?? existing.name,
      type: patch.type ?? existing.type,
      description: patch.description ?? existing.description,
      updatedAt: patch.now,
    })
    .where(and(eq(synergies.id, id), eq(synergies.userId, userId)))
    .run();

  if (patch.links) {
    db.delete(synergyLinks).where(eq(synergyLinks.synergyId, id)).run();
    insertLinks(db, id, patch.links);
  }

  return getSynergy(db, userId, id);
}

export function deleteSynergyRecord(db: AppDatabase, userId: number, id: string): boolean {
  const result = db
    .delete(synergies)
    .where(and(eq(synergies.id, id), eq(synergies.userId, userId)))
    .run();
  return result.changes > 0;
}

export function findSynergiesByTarget(
  db: AppDatabase,
  userId: number,
  query: SynergyTargetQuery,
): SynergyWithLinks[] {
  const conditions = [eq(synergies.userId, userId), eq(synergyLinks.kind, query.kind)];

  if (query.itemHash !== undefined) {
    conditions.push(eq(synergyLinks.itemHash, query.itemHash));
  }
  if (query.perkHash !== undefined) {
    conditions.push(eq(synergyLinks.perkHash, query.perkHash));
  }
  if (query.originTraitHash !== undefined) {
    conditions.push(eq(synergyLinks.originTraitHash, query.originTraitHash));
  }
  if (query.name) {
    conditions.push(
      sql`lower(${synergyLinks.originTraitName}) = lower(${query.name})`,
    );
  }
  if (query.armorSetName) {
    conditions.push(
      sql`lower(${synergyLinks.armorSetName}) = lower(${query.armorSetName})`,
    );
  }
  if (query.bonusPieces !== undefined) {
    conditions.push(eq(synergyLinks.bonusPieces, query.bonusPieces));
  }
  if (query.bonusName) {
    conditions.push(sql`lower(${synergyLinks.bonusName}) = lower(${query.bonusName})`);
  }

  const synergyIds = db
    .select({ synergyId: synergyLinks.synergyId })
    .from(synergyLinks)
    .innerJoin(synergies, eq(synergyLinks.synergyId, synergies.id))
    .where(and(...conditions))
    .all()
    .map((r) => r.synergyId);

  const unique = [...new Set(synergyIds)];
  return getSynergiesByIds(db, userId, unique);
}

export function seedDefaultSynergies(db: AppDatabase, userId: number): SynergyWithLinks[] {
  const existing = listSynergies(db, userId);
  if (existing.length > 0) return existing;

  const now = new Date().toISOString();
  createSynergyRecord(db, userId, {
    id: crypto.randomUUID(),
    name: "Melee Combo",
    type: "melee",
    description: "Default melee synergy for dev/testing",
    links: [],
    now,
  });

  return listSynergies(db, userId);
}
