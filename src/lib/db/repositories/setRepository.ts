import { and, eq, inArray, isNull, sql } from "drizzle-orm";

import type { ConceptTagId } from "@/data/conceptTags";
import type { AppDatabase } from "@/lib/db/client";
import {
  setItems,
  setTags,
  sets,
  variantSetAttachments,
  buildVariants,
  builds,
} from "@/lib/db/schema";
import type { SetType } from "@/lib/sets/schemas";

export type SetRecord = {
  id: string;
  userId: number;
  name: string;
  type: SetType;
  tagIds: ConceptTagId[];
  createdAt: string;
  updatedAt: string;
};

export type SetAttachmentRef = {
  buildId: string;
  buildName: string;
  variantId: string;
  variantName: string;
};

function rowToSet(row: typeof sets.$inferSelect, tagIds: ConceptTagId[]): SetRecord {
  return {
    id: row.id,
    userId: row.userId,
    name: row.name,
    type: row.type as SetType,
    tagIds,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

function loadTagsForSet(db: AppDatabase, setId: string): ConceptTagId[] {
  return db
    .select({ tagId: setTags.tagId })
    .from(setTags)
    .where(eq(setTags.setId, setId))
    .all()
    .map((r) => r.tagId as ConceptTagId)
    .sort();
}

export function listSets(db: AppDatabase, userId: number, type?: SetType): SetRecord[] {
  const rows = db
    .select()
    .from(sets)
    .where(
      type
        ? and(eq(sets.userId, userId), eq(sets.type, type))
        : eq(sets.userId, userId),
    )
    .all();

  return rows.map((row) => rowToSet(row, loadTagsForSet(db, row.id)));
}

export function listSetsByTags(
  db: AppDatabase,
  userId: number,
  tagIds: ConceptTagId[],
  type?: SetType,
): SetRecord[] {
  if (tagIds.length === 0) return listSets(db, userId, type);

  let matching: string[] | null = null;
  for (const tagId of tagIds) {
    const ids = db
      .select({ setId: setTags.setId })
      .from(setTags)
      .innerJoin(sets, eq(setTags.setId, sets.id))
      .where(and(eq(setTags.tagId, tagId), eq(sets.userId, userId)))
      .all()
      .map((r) => r.setId);

    matching = matching === null ? ids : matching.filter((id) => ids.includes(id));
  }

  if (!matching || matching.length === 0) return [];

  const rows = db
    .select()
    .from(sets)
    .where(
      type
        ? and(eq(sets.userId, userId), eq(sets.type, type), inArray(sets.id, matching))
        : and(eq(sets.userId, userId), inArray(sets.id, matching)),
    )
    .all();

  return rows.map((row) => rowToSet(row, loadTagsForSet(db, row.id)));
}

export function getSet(db: AppDatabase, userId: number, id: string): SetRecord | null {
  const row = db
    .select()
    .from(sets)
    .where(and(eq(sets.id, id), eq(sets.userId, userId)))
    .get();
  if (!row) return null;
  return rowToSet(row, loadTagsForSet(db, row.id));
}

export function createSetRecord(
  db: AppDatabase,
  userId: number,
  input: { id: string; name: string; type: SetType; tagIds: ConceptTagId[]; now: string },
): SetRecord {
  db.insert(sets)
    .values({
      id: input.id,
      userId,
      name: input.name,
      type: input.type,
      createdAt: input.now,
      updatedAt: input.now,
    })
    .run();

  for (const tagId of input.tagIds) {
    db.insert(setTags).values({ setId: input.id, tagId }).run();
  }

  return {
    id: input.id,
    userId,
    name: input.name,
    type: input.type,
    tagIds: input.tagIds,
    createdAt: input.now,
    updatedAt: input.now,
  };
}

export function updateSetRecord(
  db: AppDatabase,
  userId: number,
  id: string,
  patch: { name?: string; type?: SetType; tagIds?: ConceptTagId[]; now: string },
): SetRecord | null {
  const existing = getSet(db, userId, id);
  if (!existing) return null;

  db.update(sets)
    .set({
      name: patch.name ?? existing.name,
      type: patch.type ?? existing.type,
      updatedAt: patch.now,
    })
    .where(and(eq(sets.id, id), eq(sets.userId, userId)))
    .run();

  if (patch.tagIds) {
    db.delete(setTags).where(eq(setTags.setId, id)).run();
    for (const tagId of patch.tagIds) {
      db.insert(setTags).values({ setId: id, tagId }).run();
    }
  }

  return getSet(db, userId, id);
}

export function deleteSetRecord(db: AppDatabase, userId: number, id: string): boolean {
  const result = db
    .delete(sets)
    .where(and(eq(sets.id, id), eq(sets.userId, userId)))
    .run();
  return result.changes > 0;
}

export function findDuplicateName(
  db: AppDatabase,
  userId: number,
  type: SetType,
  name: string,
  excludeId?: string,
): boolean {
  const row = db
    .select({ id: sets.id })
    .from(sets)
    .where(and(eq(sets.userId, userId), eq(sets.type, type), eq(sets.name, name)))
    .get();
  if (!row) return false;
  if (excludeId && row.id === excludeId) return false;
  return true;
}

export function findAttachmentsBySetId(db: AppDatabase, setId: string): SetAttachmentRef[] {
  return db
    .select({
      buildId: builds.id,
      buildName: builds.name,
      variantId: buildVariants.id,
      variantName: buildVariants.name,
    })
    .from(variantSetAttachments)
    .innerJoin(buildVariants, eq(variantSetAttachments.variantId, buildVariants.id))
    .innerJoin(builds, eq(buildVariants.buildId, builds.id))
    .where(eq(variantSetAttachments.setId, setId))
    .all();
}

export function countActiveItemsInSet(db: AppDatabase, setId: string): number {
  const row = db
    .select({ count: sql<number>`count(*)` })
    .from(setItems)
    .where(and(eq(setItems.setId, setId), isNull(setItems.removedAt)))
    .get();
  return row?.count ?? 0;
}
