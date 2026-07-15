import type { AppDatabase } from "@/lib/db/client";
import { getSet } from "@/lib/db/repositories/setRepository";
import {
  listAttachments,
  replaceAttachments,
  type AttachmentRecord,
} from "@/lib/db/repositories/variantRepository";
import type { SetType } from "@/lib/sets/schemas";

/**
 * Detach any live/snapshot attachments whose set type matches `type`, then
 * attach `newSetId` as live. Other set types on the variant are preserved.
 */
export async function replaceAttachmentByType(
  db: AppDatabase,
  userId: number,
  variantId: string,
  type: SetType,
  newSetId: string,
  now: string,
): Promise<AttachmentRecord[]> {
  const newSet = getSet(db, userId, newSetId);
  if (!newSet || newSet.type !== type) {
    throw new Error(`Set ${newSetId} is not a ${type} set for this user`);
  }

  const existing = listAttachments(db, variantId);
  const kept: Array<Omit<AttachmentRecord, "id" | "variantId" | "attachedAt">> = [];

  for (const att of existing) {
    const set = getSet(db, userId, att.setId);
    if (!set) continue;
    if (set.type === type) continue;
    kept.push({
      setId: att.setId,
      mode: att.mode,
      snapshotConfigs: att.snapshotConfigs,
    });
  }

  kept.push({ setId: newSetId, mode: "live", snapshotConfigs: null });
  return replaceAttachments(db, variantId, kept, now);
}
