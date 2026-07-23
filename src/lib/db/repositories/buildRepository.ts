import { and, eq, inArray } from "drizzle-orm";

import type { ConceptTagId } from "@/data/conceptTags";
import type { AppDatabase } from "@/lib/db/client";
import { buildSynergyTypes, buildTags, builds, buildVariants } from "@/lib/db/schema";
import type { SynergyTypeDesignation } from "@/lib/builds/resolveDesignatedSynergies";
import {
  parseSoftStatTargets,
  serializeSoftStatTargets,
  type SoftStatTargets,
} from "@/lib/builds/softStatTargets";
import type { SynergyType } from "@/lib/synergies/schemas";

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
  synergyTypes: SynergyTypeDesignation[];
  createdAt: string;
  updatedAt: string;
};

function mapBuildSynergyTypeRow(r: {
  type: string;
  subType: string | null;
}): SynergyTypeDesignation {
  return {
    type: r.type as SynergyType,
    // Empty string stored for UNIQUE null-safety; expose as null
    subType: r.subType?.trim() ? r.subType : null,
  };
}

function loadBuildTags(db: AppDatabase, buildId: string): ConceptTagId[] {
  return db
    .select({ tagId: buildTags.tagId })
    .from(buildTags)
    .where(eq(buildTags.buildId, buildId))
    .all()
    .map((r) => r.tagId as ConceptTagId)
    .sort();
}

function loadBuildSynergyTypes(db: AppDatabase, buildId: string): SynergyTypeDesignation[] {
  return db
    .select({
      type: buildSynergyTypes.type,
      subType: buildSynergyTypes.subType,
    })
    .from(buildSynergyTypes)
    .where(eq(buildSynergyTypes.buildId, buildId))
    .all()
    .map(mapBuildSynergyTypeRow);
}

/** Batch-load tags for many builds (one query). Tag ids sorted per build. */
function loadBuildTagsForIds(db: AppDatabase, buildIds: string[]): Map<string, ConceptTagId[]> {
  const map = new Map<string, ConceptTagId[]>();
  for (const id of buildIds) map.set(id, []);
  if (buildIds.length === 0) return map;

  const rows = db
    .select({ buildId: buildTags.buildId, tagId: buildTags.tagId })
    .from(buildTags)
    .where(inArray(buildTags.buildId, buildIds))
    .all();

  for (const row of rows) {
    const list = map.get(row.buildId);
    if (list) list.push(row.tagId as ConceptTagId);
    else map.set(row.buildId, [row.tagId as ConceptTagId]);
  }
  for (const [id, tags] of map) {
    map.set(id, tags.sort());
  }
  return map;
}

/** Batch-load synergy type designations for many builds (one query). */
function loadBuildSynergyTypesForIds(
  db: AppDatabase,
  buildIds: string[],
): Map<string, SynergyTypeDesignation[]> {
  const map = new Map<string, SynergyTypeDesignation[]>();
  for (const id of buildIds) map.set(id, []);
  if (buildIds.length === 0) return map;

  const rows = db
    .select({
      buildId: buildSynergyTypes.buildId,
      type: buildSynergyTypes.type,
      subType: buildSynergyTypes.subType,
    })
    .from(buildSynergyTypes)
    .where(inArray(buildSynergyTypes.buildId, buildIds))
    .all();

  for (const row of rows) {
    const designation = mapBuildSynergyTypeRow(row);
    const list = map.get(row.buildId);
    if (list) list.push(designation);
    else map.set(row.buildId, [designation]);
  }
  return map;
}

function rowToBuildCore(
  row: typeof builds.$inferSelect,
  tagIds: ConceptTagId[],
  synergyTypes: SynergyTypeDesignation[],
): BuildRecord {
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
    tagIds,
    synergyTypes,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

function rowToBuild(db: AppDatabase, row: typeof builds.$inferSelect): BuildRecord {
  return rowToBuildCore(row, loadBuildTags(db, row.id), loadBuildSynergyTypes(db, row.id));
}

/** Hydrate many build rows with two child queries total. */
function rowsToBuilds(db: AppDatabase, rows: (typeof builds.$inferSelect)[]): BuildRecord[] {
  if (rows.length === 0) return [];
  const ids = rows.map((r) => r.id);
  const tagsByBuild = loadBuildTagsForIds(db, ids);
  const synergyByBuild = loadBuildSynergyTypesForIds(db, ids);
  return rows.map((row) =>
    rowToBuildCore(row, tagsByBuild.get(row.id) ?? [], synergyByBuild.get(row.id) ?? []),
  );
}

export function listBuilds(db: AppDatabase, userId: number): BuildRecord[] {
  const rows = db.select().from(builds).where(eq(builds.userId, userId)).all();
  return rowsToBuilds(db, rows);
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

  const rows = db
    .select()
    .from(builds)
    .where(and(eq(builds.userId, userId), inArray(builds.id, matching)))
    .all();
  return rowsToBuilds(db, rows);
}

export function listBuildsFiltered(
  db: AppDatabase,
  userId: number,
  filters: {
    tags?: ConceptTagId[];
    exoticArmorHash?: number;
    exoticWeaponHash?: number;
    synergyType?: string;
    synergySubType?: string | null;
  },
): BuildRecord[] {
  let results = filters.tags?.length
    ? listBuildsByTags(db, userId, filters.tags)
    : listBuilds(db, userId);

  if (filters.exoticArmorHash !== undefined) {
    results = results.filter((b) => b.exoticArmorHash === filters.exoticArmorHash);
  }

  if (filters.synergyType) {
    const type = filters.synergyType;
    const sub =
      filters.synergySubType === undefined
        ? undefined
        : filters.synergySubType?.trim() || null;
    results = results.filter((b) =>
      b.synergyTypes.some((d) => {
        if (d.type !== type) return false;
        if (sub === undefined) return true;
        return (d.subType ?? null) === sub;
      }),
    );
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

function insertSynergyTypes(
  db: AppDatabase,
  buildId: string,
  designations: SynergyTypeDesignation[],
  now: string,
): void {
  for (const d of designations) {
    db.insert(buildSynergyTypes)
      .values({
        buildId,
        type: d.type,
        // SQLite UNIQUE treats NULLs as distinct — use "" for no subType
        subType: d.subType?.trim() || "",
        attachedAt: now,
      })
      .run();
  }
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
    synergyTypes: SynergyTypeDesignation[];
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
  insertSynergyTypes(db, input.id, input.synergyTypes, input.now);

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
    synergyTypes?: SynergyTypeDesignation[];
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

  if (patch.synergyTypes) {
    db.delete(buildSynergyTypes).where(eq(buildSynergyTypes.buildId, id)).run();
    insertSynergyTypes(db, id, patch.synergyTypes, patch.now);
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
