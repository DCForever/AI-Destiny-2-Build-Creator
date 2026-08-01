import { and, eq, isNull } from "drizzle-orm";

import type { AppDatabase } from "@/lib/db/client";
import { setItems } from "@/lib/db/schema";
import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import {
  assertSetCompositionAllowed,
  type SetOccupant,
} from "@/lib/sets/destinySetConstraints";
import {
  costsFromOccupants,
  evaluateModSetPieceEnergy,
} from "@/lib/sets/modSetEnergy";
import type { SetItemInput } from "@/lib/sets/schemas";
import {
  isArmorSetSlot,
  isSlotValidForSetType,
  modSetArmorSlotOf,
  modSetSlotKey,
  type SetType,
} from "@/lib/sets/schemas";
import { resolveSetItemMeta } from "@/lib/sets/resolveSetItemMeta";
import { resolveItemDisplayName } from "@/lib/sets/validateItem";

export type SetItemRecord = {
  id: string;
  setId: string;
  slot: string;
  itemHash: number;
  itemName: string;
  /** Bungie relative icon path when resolvable from the entity cache. */
  icon: string | null;
  /** Catalog / intrinsic description when resolvable. */
  description: string;
  /** Damage type / element when known. */
  element: string | null;
  instanceId: string | null;
  selectedPerks: number[];
  masterworkHash: number | null;
  modHashes: number[] | null;
  sortOrder: number;
  removedAt: string | null;
  stale: boolean;
};

function parseJsonArray(raw: string): number[] {
  try {
    const parsed = JSON.parse(raw) as unknown;
    return Array.isArray(parsed) ? parsed.filter((n): n is number => typeof n === "number") : [];
  } catch {
    return [];
  }
}

async function rowToItem(row: typeof setItems.$inferSelect): Promise<SetItemRecord> {
  const resolved = await resolveItemDisplayName(row.itemHash, row.itemName);
  return {
    id: row.id,
    setId: row.setId,
    slot: row.slot,
    itemHash: row.itemHash,
    itemName: resolved.name,
    icon: resolved.icon,
    description: resolved.description,
    element: resolved.element,
    instanceId: row.instanceId,
    selectedPerks: parseJsonArray(row.selectedPerks),
    masterworkHash: row.masterworkHash,
    modHashes: row.modHashes ? parseJsonArray(row.modHashes) : null,
    sortOrder: row.sortOrder,
    removedAt: row.removedAt,
    stale: resolved.stale,
  };
}

export async function listSetItems(db: AppDatabase, setId: string): Promise<SetItemRecord[]> {
  const rows = db.select().from(setItems).where(eq(setItems.setId, setId)).all();
  return Promise.all(rows.map(rowToItem));
}

export async function listActiveSetItems(db: AppDatabase, setId: string): Promise<SetItemRecord[]> {
  const rows = db
    .select()
    .from(setItems)
    .where(and(eq(setItems.setId, setId), isNull(setItems.removedAt)))
    .all();
  return Promise.all(rows.map(rowToItem));
}

export async function upsertSetItem(
  db: AppDatabase,
  setId: string,
  setType: SetType,
  input: SetItemInput,
): Promise<SetItemRecord> {
  // Normalize bare armor-piece fill targets to unique multi-mod keys.
  let writeSlot = input.slot;
  if (setType === "mod" && isArmorSetSlot(input.slot)) {
    writeSlot = modSetSlotKey(input.slot, input.itemHash);
  } else if (setType === "mod") {
    const armor = modSetArmorSlotOf(input.slot);
    if (armor && !input.slot.includes(":")) {
      writeSlot = modSetSlotKey(armor, input.itemHash);
    }
  }

  if (!isSlotValidForSetType(setType, writeSlot)) {
    throw new ApiError(
      API_ERROR_CODES.INVALID_ITEM,
      `Invalid slot ${writeSlot} for set type ${setType}`,
    );
  }

  const meta = await resolveSetItemMeta(input.itemHash);
  const validation = await resolveItemDisplayName(input.itemHash, input.itemName);
  if (validation.stale && !input.itemName) {
    throw new ApiError(API_ERROR_CODES.INVALID_ITEM, `Unknown item hash ${input.itemHash}`);
  }
  meta.name = validation.name;

  // Active rows in other slots (slot being replaced is excluded for exotic count).
  const otherActive = db
    .select()
    .from(setItems)
    .where(
      and(
        eq(setItems.setId, setId),
        isNull(setItems.removedAt),
      ),
    )
    .all()
    .filter((row) => row.slot !== writeSlot);

  const otherItems: SetOccupant[] = await Promise.all(
    otherActive.map(async (row) => {
      const m = await resolveSetItemMeta(row.itemHash);
      m.name = row.itemName;
      return { slot: row.slot, meta: m };
    }),
  );

  const fit = assertSetCompositionAllowed(setType, writeSlot, meta, otherItems);
  if (!fit.ok) {
    throw new ApiError(
      API_ERROR_CODES.INVALID_ITEM,
      fit.reasons[0] ?? "Item does not fit this set",
      { reasons: fit.reasons },
    );
  }

  if (setType === "mod") {
    const armorSlot = modSetArmorSlotOf(writeSlot);
    if (armorSlot) {
      const samePiece = otherItems.filter(
        (o) => modSetArmorSlotOf(o.slot) === armorSlot,
      );
      const energy = evaluateModSetPieceEnergy({
        armorSlot,
        existingCosts: costsFromOccupants(samePiece),
        candidateCost: meta.energyCost,
      });
      if (!energy.ok) {
        throw new ApiError(
          API_ERROR_CODES.MOD_ENERGY_EXCEEDED,
          energy.reason,
          { used: energy.used, capacity: energy.capacity, armorSlot },
        );
      }
    }
  }

  const active = db
    .select()
    .from(setItems)
    .where(and(eq(setItems.setId, setId), eq(setItems.slot, writeSlot), isNull(setItems.removedAt)))
    .get();

  if (active && !input.confirmReplace) {
    throw new ApiError(
      API_ERROR_CODES.SLOT_OCCUPIED,
      `Slot ${writeSlot} is occupied`,
      { confirmRequired: true },
      409,
    );
  }

  if (active && input.confirmReplace) {
    db.update(setItems)
      .set({ removedAt: new Date().toISOString() })
      .where(eq(setItems.id, active.id))
      .run();
  }

  const id = crypto.randomUUID();
  db.insert(setItems)
    .values({
      id,
      setId,
      slot: writeSlot,
      itemHash: input.itemHash,
      itemName: validation.name,
      instanceId: input.instanceId ?? null,
      selectedPerks: JSON.stringify(input.selectedPerks ?? []),
      masterworkHash: input.masterworkHash ?? null,
      modHashes: input.modHashes ? JSON.stringify(input.modHashes) : null,
      sortOrder: 0,
      removedAt: null,
    })
    .run();

  const row = db.select().from(setItems).where(eq(setItems.id, id)).get();
  if (!row) throw new Error("Failed to read inserted set item");
  return rowToItem(row);
}

export async function softRemoveSetItem(db: AppDatabase, setId: string, itemId: string): Promise<boolean> {
  const result = db
    .update(setItems)
    .set({ removedAt: new Date().toISOString() })
    .where(and(eq(setItems.id, itemId), eq(setItems.setId, setId), isNull(setItems.removedAt)))
    .run();
  return result.changes > 0;
}

export function hasEmptyModSlots(setType: SetType, items: SetItemRecord[]): boolean {
  if (setType === "mod") return items.filter((i) => !i.removedAt).length === 0;
  if (setType === "armor") {
    return items.some((i) => !i.removedAt && (i.modHashes?.length ?? 0) === 0);
  }
  return false;
}
