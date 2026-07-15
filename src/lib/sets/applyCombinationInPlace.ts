import { z } from "zod";

import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import type { AppDatabase } from "@/lib/db/client";
import { createSetRecord, getSet, updateSetRecord, type SetRecord } from "@/lib/db/repositories/setRepository";
import { allocateUniqueSetName } from "@/lib/sets/uniqueSetName";
import {
  listActiveSetItems,
  softRemoveSetItem,
  upsertSetItem,
} from "@/lib/sets/setItemService";
import { parseOptimizerConstraints, type ArmorSetOptimizerConstraints } from "@/lib/optimizer/types";
import {
  validateCombinationPieces,
  validateOwnership,
  type CombinationPiece,
  type MaterializeOwnership,
} from "@/lib/sets/materializeCombination";

const armorSlotSchema = z.enum(["helmet", "arms", "chest", "legs", "class_item"]);

export const applyCombinationBodySchema = z.object({
  pieces: z
    .array(
      z.object({
        slot: armorSlotSchema,
        itemHash: z.number().int().positive(),
        instanceId: z.string().min(1),
      }),
    )
    .min(1),
  assumedMods: z
    .array(z.object({ armorSlot: armorSlotSchema, itemHash: z.number().int().positive() }))
    .optional(),
  updateLinkedModSet: z.boolean().optional(),
});

export type ApplyCombinationBody = z.infer<typeof applyCombinationBodySchema>;

export type ApplyModSetResult = { id: string; name: string; type: "mod"; updated: boolean };

export type ApplyCombinationResponse = {
  armorSet: {
    id: string;
    name: string;
    type: "armor";
    optimizerConstraints: ArmorSetOptimizerConstraints | null;
    linkedModSetId?: string;
  };
  modSet?: ApplyModSetResult;
  itemsUpdated: boolean;
};

/** Rewrite the Set's five armor items in place; returns false when unchanged. */
async function applyArmorItems(
  db: AppDatabase,
  setId: string,
  pieces: CombinationPiece[],
): Promise<boolean> {
  const current = await listActiveSetItems(db, setId);
  const bySlot = new Map(current.map((item) => [item.slot, item.instanceId]));
  const unchanged =
    current.length === pieces.length &&
    pieces.every((piece) => bySlot.get(piece.slot) === piece.instanceId);
  if (unchanged) return false;

  for (const piece of pieces) {
    await upsertSetItem(db, setId, "armor", {
      slot: piece.slot,
      itemHash: piece.itemHash,
      itemName: `Armor ${piece.itemHash}`,
      instanceId: piece.instanceId,
      confirmReplace: true,
    });
  }
  return true;
}

async function clearModItems(db: AppDatabase, modSetId: string): Promise<void> {
  for (const item of await listActiveSetItems(db, modSetId)) {
    await softRemoveSetItem(db, modSetId, item.id);
  }
}

async function writeModItems(
  db: AppDatabase,
  modSetId: string,
  mods: NonNullable<ApplyCombinationBody["assumedMods"]>,
): Promise<void> {
  for (const mod of mods) {
    await upsertSetItem(db, modSetId, "mod", {
      slot: mod.armorSlot,
      itemHash: mod.itemHash,
      itemName: `Mod ${mod.itemHash}`,
      confirmReplace: true,
    });
  }
}

/** Update the linked Mod Set in place, or create + link one when opted in. */
async function applyLinkedModSet(
  db: AppDatabase,
  userId: number,
  set: SetRecord,
  body: ApplyCombinationBody,
): Promise<ApplyModSetResult | null> {
  const mods = body.assumedMods ?? [];
  const shouldUpdate = body.updateLinkedModSet ?? mods.length > 0;
  if (!shouldUpdate || mods.length === 0) return null;

  const now = new Date().toISOString();
  const existing = set.linkedModSetId ? getSet(db, userId, set.linkedModSetId) : null;
  if (existing) {
    await clearModItems(db, existing.id);
    await writeModItems(db, existing.id, mods);
    return { id: existing.id, name: existing.name, type: "mod", updated: true };
  }

  const id = crypto.randomUUID();
  const name = allocateUniqueSetName(db, userId, "mod", `${set.name} Mods`);
  createSetRecord(db, userId, { id, name, type: "mod", tagIds: [], now });
  updateSetRecord(db, userId, set.id, { linkedModSetId: id, now });
  await writeModItems(db, id, mods);
  return { id, name, type: "mod", updated: false };
}

/**
 * Apply an optimizer combination to an existing constrained Armor Set in place
 * (US5b): replace slot items on the same Set id, leave stored constraints
 * untouched, and optionally update/create the linked Mod Set.
 */
export async function applyCombinationInPlace(
  db: AppDatabase,
  userId: number,
  setId: string,
  body: ApplyCombinationBody,
  ownership?: MaterializeOwnership,
): Promise<ApplyCombinationResponse> {
  const set = getSet(db, userId, setId);
  if (!set || set.type !== "armor") {
    throw new ApiError(API_ERROR_CODES.SET_NOT_FOUND, "Armor set not found", { setId }, 404);
  }
  validateCombinationPieces(body.pieces);
  validateOwnership(body.pieces, ownership);

  const itemsUpdated = await applyArmorItems(db, setId, body.pieces);
  const modSet = await applyLinkedModSet(db, userId, set, body);
  const linkedModSetId = modSet?.id ?? set.linkedModSetId ?? undefined;

  return {
    armorSet: {
      id: set.id,
      name: set.name,
      type: "armor",
      optimizerConstraints: parseOptimizerConstraints(set.optimizerConstraints),
      ...(linkedModSetId ? { linkedModSetId } : {}),
    },
    ...(modSet ? { modSet } : {}),
    itemsUpdated,
  };
}
