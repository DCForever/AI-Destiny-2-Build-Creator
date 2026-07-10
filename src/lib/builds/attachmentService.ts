import type { AppDatabase } from "@/lib/db/client";
import {
  listAttachments,
  replaceAttachments,
  type AttachmentRecord,
  type SnapshotConfig,
} from "@/lib/db/repositories/variantRepository";
import { getSet } from "@/lib/db/repositories/setRepository";
import { listActiveSetItems } from "@/lib/sets/setItemService";

export type SetAttachmentInput = {
  setId: string;
  mode: "live" | "snapshot";
};

async function buildSnapshotConfigs(db: AppDatabase, setId: string): Promise<SnapshotConfig[]> {
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

export async function prepareAttachments(
  db: AppDatabase,
  userId: number,
  variantId: string,
  inputs: SetAttachmentInput[],
  now: string,
): Promise<AttachmentRecord[]> {
  const prepared: Array<Omit<AttachmentRecord, "id" | "variantId" | "attachedAt">> = [];

  for (const input of inputs) {
    const set = getSet(db, userId, input.setId);
    if (!set) continue;

    let snapshotConfigs: SnapshotConfig[] | null = null;
    if (input.mode === "snapshot") {
      snapshotConfigs = await buildSnapshotConfigs(db, input.setId);
    }

    prepared.push({
      setId: input.setId,
      mode: input.mode,
      snapshotConfigs,
    });
  }

  return replaceAttachments(db, variantId, prepared, now);
}

export function getAttachments(db: AppDatabase, variantId: string): AttachmentRecord[] {
  return listAttachments(db, variantId);
}
