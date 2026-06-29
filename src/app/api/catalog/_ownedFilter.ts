import { eq } from "drizzle-orm";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import type { AppDatabase } from "@/lib/db/client";
import { inventoryItems } from "@/lib/db/schema";
import { getInventoryStatus } from "@/lib/db/repositories/inventoryRepository";
import {
  ownedHashesFromInventory,
  type InventoryBucketRow,
} from "@/lib/catalog/filterItems";

export type OwnedCatalogContext = {
  userId: number;
  ownedHashes: Map<number, number>;
  syncPrompt: boolean;
};

export async function resolveOwnedCatalogContext(
  request: Request,
  db: AppDatabase,
  kind: "weapons" | "armor",
): Promise<OwnedCatalogContext | null> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return null;

  const status = getInventoryStatus(db, auth.user.id);
  const rows = db
    .select({ itemHash: inventoryItems.itemHash, bucket: inventoryItems.bucket })
    .from(inventoryItems)
    .where(eq(inventoryItems.userId, auth.user.id))
    .all() as InventoryBucketRow[];

  const ownedHashes = ownedHashesFromInventory(rows, kind);
  const syncPrompt = !status || status.itemCount === 0;

  return {
    userId: auth.user.id,
    ownedHashes,
    syncPrompt,
  };
}
