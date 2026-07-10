import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import type { AppDatabase } from "@/lib/db/client";
import { getBuild } from "@/lib/db/repositories/buildRepository";
import {
  createVariantRecord,
  deleteVariantRecord,
  getVariant,
  listAttachments,
  listVariants,
  replaceAttachments,
  type AttachmentRecord,
} from "@/lib/db/repositories/variantRepository";
import { getBuildDetail, validateVariantSave } from "@/lib/builds/buildService";
import type { BuildVariantInput } from "@/lib/builds/schemas";
import { listActiveSetItems } from "@/lib/sets/setItemService";
import type { SnapshotConfig } from "@/lib/db/repositories/variantRepository";

async function snapshotFromSet(db: AppDatabase, setId: string): Promise<SnapshotConfig[]> {
  const items = await listActiveSetItems(db, setId);
  return items.map((item) => ({
    slot: item.slot,
    itemHash: item.itemHash,
    itemName: item.itemName,
    selectedPerks: item.selectedPerks,
    masterworkHash: item.masterworkHash,
    modHashes: item.modHashes,
    instanceId: item.instanceId,
  }));
}

function cloneAttachmentsAsSnapshots(
  attachments: AttachmentRecord[],
): Array<Omit<AttachmentRecord, "id" | "variantId" | "attachedAt">> {
  return attachments.map((a) => ({
    setId: a.setId,
    mode: "snapshot" as const,
    snapshotConfigs: a.snapshotConfigs,
  }));
}

export async function createUserVariant(
  db: AppDatabase,
  userId: number,
  buildId: string,
  input: BuildVariantInput & { duplicateFromVariantId?: string },
) {
  const build = getBuild(db, userId, buildId);
  if (!build) return null;

  const now = new Date().toISOString();
  const variantId = crypto.randomUUID();

  let exoticWeaponHash = input.exoticWeaponHash ?? null;
  let exoticWeaponName = input.exoticWeaponName ?? null;
  let notes = input.notes ?? null;
  let name = input.name ?? "Variant";
  let sourceAttachments: AttachmentRecord[] = [];

  if (input.duplicateFromVariantId) {
    const source = getVariant(db, buildId, input.duplicateFromVariantId);
    if (!source) {
      throw new ApiError(API_ERROR_CODES.INVALID_ITEM, "Source variant not found");
    }
    exoticWeaponHash = input.exoticWeaponHash ?? source.exoticWeaponHash;
    exoticWeaponName = input.exoticWeaponName ?? source.exoticWeaponName;
    notes = input.notes !== undefined ? input.notes : source.notes;
    name = input.name ?? `${source.name} Copy`;
    sourceAttachments = listAttachments(db, source.id);
  }

  const sourceVariant = input.duplicateFromVariantId
    ? getVariant(db, buildId, input.duplicateFromVariantId)
    : null;

  createVariantRecord(db, {
    id: variantId,
    buildId,
    name,
    isDefault: false,
    exoticWeaponHash,
    exoticWeaponName,
    artifactHash: input.artifactHash ?? sourceVariant?.artifactHash ?? null,
    artifactName: input.artifactName ?? sourceVariant?.artifactName ?? null,
    artifactConfig: input.artifactConfig ?? sourceVariant?.artifactConfig ?? [],
    notes,
    now,
  });

  if (sourceAttachments.length) {
    const prepared = await Promise.all(
      cloneAttachmentsAsSnapshots(sourceAttachments).map(async (attachment) => {
        if (attachment.snapshotConfigs?.length) return attachment;
        return {
          ...attachment,
          snapshotConfigs: await snapshotFromSet(db, attachment.setId),
        };
      }),
    );
    replaceAttachments(db, variantId, prepared, now);
    await validateVariantSave(db, userId, buildId, variantId);
  }

  return getBuildDetail(db, userId, buildId);
}

export function deleteUserVariant(
  db: AppDatabase,
  userId: number,
  buildId: string,
  variantId: string,
): boolean {
  const build = getBuild(db, userId, buildId);
  if (!build) return false;

  const variants = listVariants(db, buildId);
  const target = variants.find((v) => v.id === variantId);
  if (!target) return false;

  if (variants.length === 1) {
    throw new ApiError(API_ERROR_CODES.VARIANT_EMPTY, "Cannot delete the only variant on a build");
  }
  if (target.isDefault && variants.filter((v) => v.isDefault).length === 1) {
    throw new ApiError(API_ERROR_CODES.VARIANT_EMPTY, "Cannot delete the sole default variant");
  }

  return deleteVariantRecord(db, buildId, variantId);
}
