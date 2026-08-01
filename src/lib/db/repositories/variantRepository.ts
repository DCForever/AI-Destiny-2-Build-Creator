import { and, eq } from "drizzle-orm";

import type { AppDatabase } from "@/lib/db/client";
import { buildVariants, variantSetAttachments } from "@/lib/db/schema";
import {
  parseSubclassKitJson,
  serializeSubclassKit,
  type SubclassKitFields,
} from "@/lib/builds/subclassKit";

export type VariantRecord = {
  id: string;
  buildId: string;
  name: string;
  isDefault: boolean;
  exoticWeaponHash: number | null;
  exoticWeaponName: string | null;
  artifactHash: number | null;
  artifactName: string | null;
  artifactConfig: number[];
  /** Null = legacy: fall back to kit fields on build.subclass. */
  subclassKit: SubclassKitFields | null;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
};

function parseArtifactConfig(raw: string | null | undefined): number[] {
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw) as unknown;
    return Array.isArray(parsed) ? parsed.filter((n): n is number => typeof n === "number") : [];
  } catch {
    return [];
  }
}

export type AttachmentRecord = {
  id: string;
  variantId: string;
  setId: string;
  mode: "live" | "snapshot";
  snapshotConfigs: SnapshotConfig[] | null;
  attachedAt: string;
};

export type SnapshotConfig = {
  slot: string;
  itemHash: number;
  itemName: string;
  selectedPerks?: number[];
  masterworkHash?: number | null;
  modHashes?: number[] | null;
  instanceId?: string | null;
};

function rowToVariant(row: typeof buildVariants.$inferSelect): VariantRecord {
  return {
    id: row.id,
    buildId: row.buildId,
    name: row.name,
    isDefault: row.isDefault === 1,
    exoticWeaponHash: row.exoticWeaponHash,
    exoticWeaponName: row.exoticWeaponName,
    artifactHash: row.artifactHash ?? null,
    artifactName: row.artifactName ?? null,
    artifactConfig: parseArtifactConfig(row.artifactConfig),
    subclassKit: parseSubclassKitJson(row.subclassKit),
    notes: row.notes,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

function rowToAttachment(row: typeof variantSetAttachments.$inferSelect): AttachmentRecord {
  return {
    id: row.id,
    variantId: row.variantId,
    setId: row.setId,
    mode: row.mode as "live" | "snapshot",
    snapshotConfigs: row.snapshotConfigs ? (JSON.parse(row.snapshotConfigs) as SnapshotConfig[]) : null,
    attachedAt: row.attachedAt,
  };
}

export function listVariants(db: AppDatabase, buildId: string): VariantRecord[] {
  return db
    .select()
    .from(buildVariants)
    .where(eq(buildVariants.buildId, buildId))
    .all()
    .map(rowToVariant);
}

export function getVariant(db: AppDatabase, buildId: string, variantId: string): VariantRecord | null {
  const row = db
    .select()
    .from(buildVariants)
    .where(and(eq(buildVariants.id, variantId), eq(buildVariants.buildId, buildId)))
    .get();
  return row ? rowToVariant(row) : null;
}

export function createVariantRecord(
  db: AppDatabase,
  input: {
    id: string;
    buildId: string;
    name: string;
    isDefault?: boolean;
    exoticWeaponHash?: number | null;
    exoticWeaponName?: string | null;
    artifactHash?: number | null;
    artifactName?: string | null;
    artifactConfig?: number[];
    subclassKit?: SubclassKitFields | null;
    notes?: string | null;
    now: string;
  },
): VariantRecord {
  db.insert(buildVariants)
    .values({
      id: input.id,
      buildId: input.buildId,
      name: input.name,
      isDefault: input.isDefault ? 1 : 0,
      exoticWeaponHash: input.exoticWeaponHash ?? null,
      exoticWeaponName: input.exoticWeaponName ?? null,
      artifactHash: input.artifactHash ?? null,
      artifactName: input.artifactName ?? null,
      artifactConfig: JSON.stringify(input.artifactConfig ?? []),
      subclassKit:
        input.subclassKit != null ? serializeSubclassKit(input.subclassKit) : null,
      notes: input.notes ?? null,
      createdAt: input.now,
      updatedAt: input.now,
    })
    .run();
  return getVariant(db, input.buildId, input.id)!;
}

export function updateVariantRecord(
  db: AppDatabase,
  buildId: string,
  variantId: string,
  patch: {
    name?: string;
    exoticWeaponHash?: number | null;
    exoticWeaponName?: string | null;
    artifactHash?: number | null;
    artifactName?: string | null;
    artifactConfig?: number[];
    subclassKit?: SubclassKitFields | null;
    notes?: string | null;
    now: string;
  },
): VariantRecord | null {
  const existing = getVariant(db, buildId, variantId);
  if (!existing) return null;

  db.update(buildVariants)
    .set({
      name: patch.name ?? existing.name,
      exoticWeaponHash: patch.exoticWeaponHash !== undefined ? patch.exoticWeaponHash : existing.exoticWeaponHash,
      exoticWeaponName:
        patch.exoticWeaponName !== undefined ? patch.exoticWeaponName : existing.exoticWeaponName,
      artifactHash: patch.artifactHash !== undefined ? patch.artifactHash : existing.artifactHash,
      artifactName: patch.artifactName !== undefined ? patch.artifactName : existing.artifactName,
      artifactConfig:
        patch.artifactConfig !== undefined
          ? JSON.stringify(patch.artifactConfig)
          : JSON.stringify(existing.artifactConfig),
      subclassKit:
        patch.subclassKit !== undefined
          ? patch.subclassKit == null
            ? null
            : serializeSubclassKit(patch.subclassKit)
          : existing.subclassKit != null
            ? serializeSubclassKit(existing.subclassKit)
            : null,
      notes: patch.notes !== undefined ? patch.notes : existing.notes,
      updatedAt: patch.now,
    })
    .where(and(eq(buildVariants.id, variantId), eq(buildVariants.buildId, buildId)))
    .run();

  return getVariant(db, buildId, variantId);
}

/** Wipe kit on every variant of a build (tree change baseline). */
export function wipeAllVariantKits(
  db: AppDatabase,
  buildId: string,
  kit: SubclassKitFields,
  now: string,
): void {
  const variants = listVariants(db, buildId);
  for (const v of variants) {
    updateVariantRecord(db, buildId, v.id, { subclassKit: kit, now });
  }
}

export function deleteVariantRecord(db: AppDatabase, buildId: string, variantId: string): boolean {
  const result = db
    .delete(buildVariants)
    .where(and(eq(buildVariants.id, variantId), eq(buildVariants.buildId, buildId)))
    .run();
  return result.changes > 0;
}

export function listAttachments(db: AppDatabase, variantId: string): AttachmentRecord[] {
  return db
    .select()
    .from(variantSetAttachments)
    .where(eq(variantSetAttachments.variantId, variantId))
    .all()
    .map(rowToAttachment);
}

export function replaceAttachments(
  db: AppDatabase,
  variantId: string,
  attachments: Array<Omit<AttachmentRecord, "id" | "variantId" | "attachedAt"> & { id?: string }>,
  now: string,
): AttachmentRecord[] {
  db.delete(variantSetAttachments).where(eq(variantSetAttachments.variantId, variantId)).run();

  for (const attachment of attachments) {
    db.insert(variantSetAttachments)
      .values({
        id: attachment.id ?? crypto.randomUUID(),
        variantId,
        setId: attachment.setId,
        mode: attachment.mode,
        snapshotConfigs: attachment.snapshotConfigs ? JSON.stringify(attachment.snapshotConfigs) : null,
        attachedAt: now,
      })
      .run();
  }

  return listAttachments(db, variantId);
}
