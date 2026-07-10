import type { AppDatabase } from "@/lib/db/client";
import { getSet } from "@/lib/db/repositories/setRepository";
import {
  listAttachments,
  type AttachmentRecord,
} from "@/lib/db/repositories/variantRepository";
import { listActiveSetItems } from "@/lib/sets/setItemService";
import { FASHION_SLOTS, type FashionSlot, isFashionSlot } from "@/lib/sets/schemas";

export type ResolvedArtifact = {
  hash: number;
  name: string;
  config: number[];
} | null;

export type ResolvedFashion = {
  setId: string;
  slots: Partial<Record<FashionSlot, { itemHash: number; itemName: string }>>;
} | null;

export function resolvedArtifactFromVariant(variant: {
  artifactHash: number | null;
  artifactName: string | null;
  artifactConfig: number[];
}): ResolvedArtifact {
  if (variant.artifactHash == null) return null;
  return {
    hash: variant.artifactHash,
    name: variant.artifactName ?? `Artifact (${variant.artifactHash})`,
    config: variant.artifactConfig,
  };
}

export async function resolveFashionLayer(
  db: AppDatabase,
  userId: number,
  variantId: string,
  attachments?: AttachmentRecord[],
): Promise<ResolvedFashion> {
  const list = attachments ?? listAttachments(db, variantId);
  const fashionAttachments = list.filter((a) => {
    const set = getSet(db, userId, a.setId);
    return set?.type === "fashion";
  });
  if (fashionAttachments.length === 0) return null;

  const attachment = fashionAttachments[0]!;
  const slots: Partial<Record<FashionSlot, { itemHash: number; itemName: string }>> = {};

  if (attachment.mode === "snapshot" && attachment.snapshotConfigs?.length) {
    for (const cfg of attachment.snapshotConfigs) {
      if (!isFashionSlot(cfg.slot)) continue;
      slots[cfg.slot] = { itemHash: cfg.itemHash, itemName: cfg.itemName };
    }
  } else {
    const items = await listActiveSetItems(db, attachment.setId);
    for (const item of items) {
      if (!isFashionSlot(item.slot)) continue;
      slots[item.slot] = { itemHash: item.itemHash, itemName: item.itemName };
    }
  }

  // Ensure we only emit known fashion slots (omit empties)
  const trimmed: typeof slots = {};
  for (const slot of FASHION_SLOTS) {
    if (slots[slot]) trimmed[slot] = slots[slot];
  }

  return { setId: attachment.setId, slots: trimmed };
}
