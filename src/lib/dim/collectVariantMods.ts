import type { AppDatabase } from "@/lib/db/client";
import { getSet } from "@/lib/db/repositories/setRepository";
import { listAttachments } from "@/lib/db/repositories/variantRepository";
import { listActiveSetItems } from "@/lib/sets/setItemService";

/** Collect unique armor/mod plug hashes attached to a variant. */
export async function collectVariantMods(
  db: AppDatabase,
  userId: number,
  variantId: string,
): Promise<number[]> {
  const attachments = listAttachments(db, variantId);
  const hashes = new Set<number>();

  for (const attachment of attachments) {
    const set = getSet(db, userId, attachment.setId);

    if (attachment.mode === "snapshot" && attachment.snapshotConfigs?.length) {
      for (const cfg of attachment.snapshotConfigs) {
        for (const h of cfg.modHashes ?? []) hashes.add(h);
        if (set?.type === "mod") hashes.add(cfg.itemHash);
      }
      continue;
    }

    const items = await listActiveSetItems(db, attachment.setId);
    for (const item of items) {
      for (const h of item.modHashes ?? []) hashes.add(h);
      if (set?.type === "mod") hashes.add(item.itemHash);
    }
  }

  return [...hashes];
}
