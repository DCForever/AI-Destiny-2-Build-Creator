import { and, eq, inArray } from "drizzle-orm";

import type { ConceptTagId } from "@/data/conceptTags";
import type { AppDatabase } from "@/lib/db/client";
import { buildSynergies, buildTags, builds, buildVariants } from "@/lib/db/schema";
import {
  parseSoftStatTargets,
  serializeSoftStatTargets,
  type SoftStatTargets,
} from "@/lib/builds/softStatTargets";

export type BuildRecord = {
  id: string;
  userId: number;
  name: string;
  className: string;
  subclass: unknown;
  exoticArmorHash: number | null;
  exoticArmorName: string | null;
  exoticWeaponHash: number | null;
  exoticWeaponName: string | null;
  pinnedSuper: string | null;
  softStatTargets: SoftStatTargets;
  tagIds: ConceptTagId[];
  synergyIds: string[];
  createdAt: string;
  updatedAt: string;
};

function loadBuildTags(db: AppDatabase, buildId: string): ConceptTagId[] {
  return db
    .select({ tagId: buildTags.tagId })
    .from(buildTags)
    .where(eq(buildTags.buildId, buildId))
    .all()
    .map((r) => r.tagId as ConceptTagId)
    .sort();
}

function loadBuildSynergies(db: AppDatabase, buildId: string): string[] {
  return db
    .select({ synergyId: buildSynergies.synergyId })
    .from(buildSynergies)
    .where(eq(buildSynergies.buildId, buildId))
    .all()
    .map((r) => r.synergyId);
}

function rowToBuild(db: AppDatabase, row: typeof builds.$inferSelect): BuildRecord {
  return {
    id: row.id,
    userId: row.userId,
    name: row.name,
    className: row.className,
    subclass: JSON.parse(row.subclass) as unknown,
    exoticArmorHash: row.exoticArmorHash ?? null,
    exoticArmorName: row.exoticArmorName ?? null,
    exoticWeaponHash: row.exoticWeaponHash ?? null,
    exoticWeaponName: row.exoticWeaponName ?? null,
    pinnedSuper: row.pinnedSuper ?? null,
    softStatTargets: parseSoftStatTargets(row.softStatTargets),
    tagIds: loadBuildTags(db, row.id),
    synergyIds: loadBuildSynergies(db, row.id),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

export function listBuilds(db: AppDatabase, userId: number): BuildRecord[] {
  return db
    .select()
    .from(builds)
    .where(eq(builds.userId, userId))
    .all()
    .map((row) => rowToBuild(db, row));
}

export function listBuildsByTags(
  db: AppDatabase,
  userId: number,
  tagIds: ConceptTagId[],
): BuildRecord[] {
  if (tagIds.length === 0) return listBuilds(db, userId);

  let matching: string[] | null = null;
  for (const tagId of tagIds) {
    const ids = db
      .select({ buildId: buildTags.buildId })
      .from(buildTags)
      .innerJoin(builds, eq(buildTags.buildId, builds.id))
      .where(and(eq(buildTags.tagId, tagId), eq(builds.userId, userId)))
      .all()
      .map((r) => r.buildId);
    matching = matching === null ? ids : matching.filter((id) => ids.includes(id));
  }
  if (!matching || matching.length === 0) return [];

  return db
    .select()
    .from(builds)
    .where(and(eq(builds.userId, userId), inArray(builds.id, matching)))
    .all()
    .map((row) => rowToBuild(db, row));
}

export function listBuildsFiltered(
  db: AppDatabase,
  userId: number,
  filters: {
    tags?: ConceptTagId[];
    exoticArmorHash?: number;
    exoticWeaponHash?: number;
    synergyId?: string;
  },
): BuildRecord[] {
  let results = filters.tags?.length
    ? listBuildsByTags(db, userId, filters.tags)
    : listBuilds(db, userId);

  if (filters.exoticArmorHash !== undefined) {
    results = results.filter((b) => b.exoticArmorHash === filters.exoticArmorHash);
  }

  if (filters.synergyId) {
    results = results.filter((b) => b.synergyIds.includes(filters.synergyId!));
  }

  if (filters.exoticWeaponHash !== undefined) {
    const weaponHash = filters.exoticWeaponHash;
    const buildIds = results.map((b) => b.id);
    if (buildIds.length === 0) return [];
    const variantRows = db
      .select({ buildId: buildVariants.buildId })
      .from(buildVariants)
      .where(
        and(
          inArray(buildVariants.buildId, buildIds),
          eq(buildVariants.exoticWeaponHash, weaponHash),
        ),
      )
      .all();
    const allowed = new Set(variantRows.map((r) => r.buildId));
    results = results.filter(
      (b) => b.exoticWeaponHash === weaponHash || allowed.has(b.id),
    );
  }

  return results;
}

export function findBuildByNameClass(
  db: AppDatabase,
  userId: number,
  className: string,
  name: string,
  excludeId?: string,
): BuildRecord | null {
  const rows = db
    .select()
    .from(builds)
    .where(and(eq(builds.userId, userId), eq(builds.className, className), eq(builds.name, name)))
    .all()
    .map((row) => rowToBuild(db, row));
  return rows.find((b) => b.id !== excludeId) ?? null;
}

export function getBuild(db: AppDatabase, userId: number, id: string): BuildRecord | null {
  const row = db
    .select()
    .from(builds)
    .where(and(eq(builds.id, id), eq(builds.userId, userId)))
    .get();
  return row ? rowToBuild(db, row) : null;
}

export function createBuildRecord(
  db: AppDatabase,
  userId: number,
  input: {
    id: string;
    name: string;
    className: string;
    subclass: unknown;
    exoticArmorHash: number | null;
    exoticArmorName: string | null;
    exoticWeaponHash: number | null;
    exoticWeaponName: string | null;
    pinnedSuper: string | null;
    softStatTargets?: SoftStatTargets;
    tagIds: ConceptTagId[];
    synergyIds: string[];
    now: string;
  },
): BuildRecord {
  db.insert(builds)
    .values({
      id: input.id,
      userId,
      name: input.name,
      className: input.className,
      subclass: JSON.stringify(input.subclass),
      exoticArmorHash: input.exoticArmorHash,
      exoticArmorName: input.exoticArmorName,
      exoticWeaponHash: input.exoticWeaponHash,
      exoticWeaponName: input.exoticWeaponName,
      pinnedSuper: input.pinnedSuper,
      softStatTargets: serializeSoftStatTargets(input.softStatTargets ?? {}),
      createdAt: input.now,
      updatedAt: input.now,
    })
    .run();

  for (const tagId of input.tagIds) {
    db.insert(buildTags).values({ buildId: input.id, tagId }).run();
  }
  for (const synergyId of input.synergyIds) {
    db.insert(buildSynergies)
      .values({ buildId: input.id, synergyId, attachedAt: input.now })
      .run();
  }

  return getBuild(db, userId, input.id)!;
}

export function updateBuildRecord(
  db: AppDatabase,
  userId: number,
  id: string,
  patch: {
    name?: string;
    className?: string;
    subclass?: unknown;
    exoticArmorHash?: number | null;
    exoticArmorName?: string | null;
    exoticWeaponHash?: number | null;
    exoticWeaponName?: string | null;
    pinnedSuper?: string | null;
    softStatTargets?: SoftStatTargets;
    tagIds?: ConceptTagId[];
    synergyIds?: string[];
    now: string;
  },
): BuildRecord | null {
  const existing = getBuild(db, userId, id);
  if (!existing) return null;

  db.update(builds)
    .set({
      name: patch.name ?? existing.name,
      className: patch.className ?? existing.className,
      subclass: patch.subclass ? JSON.stringify(patch.subclass) : JSON.stringify(existing.subclass),
      exoticArmorHash:
        patch.exoticArmorHash !== undefined ? patch.exoticArmorHash : existing.exoticArmorHash,
      exoticArmorName:
        patch.exoticArmorName !== undefined ? patch.exoticArmorName : existing.exoticArmorName,
      exoticWeaponHash:
        patch.exoticWeaponHash !== undefined ? patch.exoticWeaponHash : existing.exoticWeaponHash,
      exoticWeaponName:
        patch.exoticWeaponName !== undefined ? patch.exoticWeaponName : existing.exoticWeaponName,
      pinnedSuper: patch.pinnedSuper !== undefined ? patch.pinnedSuper : existing.pinnedSuper,
      softStatTargets:
        patch.softStatTargets !== undefined
          ? serializeSoftStatTargets(patch.softStatTargets)
          : serializeSoftStatTargets(existing.softStatTargets),
      updatedAt: patch.now,
    })
    .where(and(eq(builds.id, id), eq(builds.userId, userId)))
    .run();

  if (patch.tagIds) {
    db.delete(buildTags).where(eq(buildTags.buildId, id)).run();
    for (const tagId of patch.tagIds) {
      db.insert(buildTags).values({ buildId: id, tagId }).run();
    }
  }

  if (patch.synergyIds) {
    db.delete(buildSynergies).where(eq(buildSynergies.buildId, id)).run();
    for (const synergyId of patch.synergyIds) {
      db.insert(buildSynergies)
        .values({ buildId: id, synergyId, attachedAt: patch.now })
        .run();
    }
  }

  return getBuild(db, userId, id);
}

export function deleteBuildRecord(db: AppDatabase, userId: number, id: string): boolean {
  const result = db
    .delete(builds)
    .where(and(eq(builds.id, id), eq(builds.userId, userId)))
    .run();
  return result.changes > 0;
}
