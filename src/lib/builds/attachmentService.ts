import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import type { AppDatabase } from "@/lib/db/client";
import {
  listAttachments,
  replaceAttachments,
  type AttachmentRecord,
  type SnapshotConfig,
} from "@/lib/db/repositories/variantRepository";
import { getSet } from "@/lib/db/repositories/setRepository";
import { assertArmorSetBonusConstraint, parseArmorSetBonusConstraint } from "@/lib/sets/armorSetBonusConstraint";
import { loadSetBonusMembershipIndex, toConstrainedArmorPieces } from "@/lib/sets/armorSetBonusConstraint.server";
import { assertSetMinimumOccupancy } from "@/lib/sets/setMinimumOccupancy";
import { listActiveSetItems } from "@/lib/sets/setItemService";
import type { SetType } from "@/lib/sets/schemas";

export type SetAttachmentInput = {
  setId: string;
  mode: "live" | "snapshot";
  /**
   * When mode is snapshot and provided, freeze these configs (including modHashes)
   * instead of re-reading live set items. Used by the variant Mods tab.
   */
  snapshotConfigs?: SnapshotConfig[] | null;
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
  let fashionCount = 0;

  for (const input of inputs) {
    const set = getSet(db, userId, input.setId);
    if (!set) continue;

    if (set.type === "fashion") {
      fashionCount += 1;
      if (fashionCount > 1) {
        throw new ApiError(
          API_ERROR_CODES.INVALID_ITEM,
          "Variant may attach at most one fashion set",
        );
      }
    }

    // DBR-CMP-008–010: empty scaffold OK (finish create+attach); partial packages blocked.
    const activeItems = await listActiveSetItems(db, input.setId);
    assertSetMinimumOccupancy(set.type as SetType, activeItems, {
      context: "attach",
    });

    // DBR-SETB-004: constrained Armor Sets must meet family + tier on attach.
    if (set.type === "armor") {
      const constraint = parseArmorSetBonusConstraint(set.setBonusConstraint);
      if (constraint) {
        const pieces = await toConstrainedArmorPieces(activeItems);
        const membership = await loadSetBonusMembershipIndex();
        assertArmorSetBonusConstraint(constraint, pieces, membership, {
          setType: "armor",
          requireTier: true,
          context: "attach",
        });
      }
    }

    let snapshotConfigs: SnapshotConfig[] | null = null;
    if (input.mode === "snapshot") {
      snapshotConfigs =
        input.snapshotConfigs != null
          ? input.snapshotConfigs
          : await buildSnapshotConfigs(db, input.setId);
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
