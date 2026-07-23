import { z } from "zod";

import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import type { AppDatabase } from "@/lib/db/client";
import { getBuild } from "@/lib/db/repositories/buildRepository";
import { getVariant, listAttachments } from "@/lib/db/repositories/variantRepository";
import { createSetRecord, getSet, updateSetRecord } from "@/lib/db/repositories/setRepository";
import { replaceAttachmentByType } from "@/lib/builds/replaceAttachmentByType";
import { allocateUniqueSetName } from "@/lib/sets/uniqueSetName";
import { upsertSetItem } from "@/lib/sets/setItemService";
import { armorSetOptimizerConstraintsSchema } from "@/lib/optimizer/constraintsSchema";
import {
  serializeOptimizerConstraints,
  type ArmorSetOptimizerConstraints,
} from "@/lib/optimizer/types";
import type { SetType } from "@/lib/sets/schemas";

const armorSlotSchema = z.enum(["helmet", "arms", "chest", "legs", "class_item"]);

export const materializeCombinationBodySchema = z.object({
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
  constraints: armorSetOptimizerConstraintsSchema,
  armorSetName: z.string().trim().min(1).max(120),
  createModSet: z.boolean().optional(),
  modSetName: z.string().trim().min(1).max(120).optional(),
  attachNow: z.boolean().optional(),
  buildId: z.string().min(1).optional(),
  variantId: z.string().min(1).optional(),
});

export type MaterializeCombinationBody = z.infer<typeof materializeCombinationBodySchema>;

/** instanceId → owned identity, used to validate ownership + exotic count. */
export type MaterializeOwnership = {
  byInstanceId: Map<string, { itemHash: number; isExotic: boolean }>;
};

export type MaterializeAttachment = {
  setId: string;
  mode: "live";
  variantId: string;
  replacedSetIds?: string[];
};

export type MaterializeCombinationResponse = {
  armorSet: {
    id: string;
    name: string;
    type: "armor";
    optimizerConstraints: ArmorSetOptimizerConstraints;
    linkedModSetId?: string;
  };
  modSet?: { id: string; name: string; type: "mod" };
  attachments: MaterializeAttachment[];
};

const ARMOR_SLOT_COUNT = 5;

/** Pieces shared by materialize + apply-in-place (five distinct armor slots). */
export type CombinationPiece = { slot: string; itemHash: number; instanceId: string };

export function validateCombinationPieces(pieces: CombinationPiece[]): void {
  const slots = new Set(pieces.map((piece) => piece.slot));
  if (pieces.length !== ARMOR_SLOT_COUNT || slots.size !== ARMOR_SLOT_COUNT) {
    throw new ApiError(
      API_ERROR_CODES.INVALID_ITEM,
      "Combination must fill all five distinct armor slots",
      { slots: [...slots] },
      400,
    );
  }
}

export function validateOwnership(
  pieces: CombinationPiece[],
  ownership: MaterializeOwnership | undefined,
): void {
  if (!ownership) return;
  let exotics = 0;
  for (const piece of pieces) {
    const owned = ownership.byInstanceId.get(piece.instanceId);
    if (!owned || owned.itemHash !== piece.itemHash) {
      throw new ApiError(
        API_ERROR_CODES.INSTANCE_NOT_OWNED,
        `Instance ${piece.instanceId} is not owned`,
        { instanceId: piece.instanceId },
        400,
      );
    }
    if (owned.isExotic) exotics += 1;
  }
  if (exotics > 1) {
    throw new ApiError(API_ERROR_CODES.EXOTIC_LIMIT, "A kit may hold at most one exotic", undefined, 400);
  }
}

function requireAttachVariant(
  db: AppDatabase,
  userId: number,
  body: MaterializeCombinationBody,
): string {
  if (!body.buildId || !body.variantId) {
    throw new ApiError(
      API_ERROR_CODES.ATTACH_REQUIRES_BUILD,
      "attachNow requires buildId and variantId",
      undefined,
      400,
    );
  }
  const build = getBuild(db, userId, body.buildId);
  const variant = build ? getVariant(db, body.buildId, body.variantId) : null;
  if (!build || !variant) {
    throw new ApiError(API_ERROR_CODES.BUILD_NOT_FOUND, "Build or variant not found", undefined, 404);
  }
  return variant.id;
}

async function persistArmorSet(
  db: AppDatabase,
  userId: number,
  body: MaterializeCombinationBody,
  now: string,
): Promise<{ id: string; name: string }> {
  const name = allocateUniqueSetName(db, userId, "armor", body.armorSetName);
  const id = crypto.randomUUID();
  createSetRecord(db, userId, {
    id,
    name,
    type: "armor",
    tagIds: [],
    now,
    optimizerConstraints: serializeOptimizerConstraints(body.constraints),
  });
  for (const piece of body.pieces) {
    await upsertSetItem(db, id, "armor", {
      slot: piece.slot,
      itemHash: piece.itemHash,
      itemName: `Armor ${piece.itemHash}`,
      instanceId: piece.instanceId,
      confirmReplace: true,
    });
  }
  return { id, name };
}

async function persistModSet(
  db: AppDatabase,
  userId: number,
  body: MaterializeCombinationBody,
  now: string,
): Promise<{ id: string; name: string } | null> {
  const mods = body.assumedMods ?? [];
  const shouldCreate = body.createModSet ?? mods.length > 0;
  if (!shouldCreate || mods.length === 0) return null;

  const name = allocateUniqueSetName(db, userId, "mod", body.modSetName ?? `${body.armorSetName} Mods`);
  const id = crypto.randomUUID();
  createSetRecord(db, userId, { id, name, type: "mod", tagIds: [], now });
  for (const mod of mods) {
    await upsertSetItem(db, id, "mod", {
      slot: mod.armorSlot,
      itemHash: mod.itemHash,
      itemName: `Mod ${mod.itemHash}`,
      confirmReplace: true,
    });
  }
  return { id, name };
}

async function attachReplacing(
  db: AppDatabase,
  userId: number,
  variantId: string,
  type: SetType,
  setId: string,
  now: string,
): Promise<MaterializeAttachment> {
  const replaced = listAttachments(db, variantId)
    .filter((att) => att.setId !== setId && getSet(db, userId, att.setId)?.type === type)
    .map((att) => att.setId);
  await replaceAttachmentByType(db, userId, variantId, type, setId, now);
  return { setId, mode: "live", variantId, ...(replaced.length ? { replacedSetIds: replaced } : {}) };
}

/**
 * First-time materialize (US5): create a new Armor Set from an optimizer
 * combination, persist its constraints, optionally create + link a Mod Set,
 * and optionally replace-by-type attach both to a build variant. Never
 * overwrites an existing Set's items — see applyCombinationInPlace (US5b).
 */
export async function materializeCombination(
  db: AppDatabase,
  userId: number,
  body: MaterializeCombinationBody,
  ownership?: MaterializeOwnership,
): Promise<MaterializeCombinationResponse> {
  validateCombinationPieces(body.pieces);
  validateOwnership(body.pieces, ownership);
  const variantId = body.attachNow ? requireAttachVariant(db, userId, body) : null;

  const now = new Date().toISOString();
  const armor = await persistArmorSet(db, userId, body, now);
  const modSet = await persistModSet(db, userId, body, now);
  if (modSet) updateSetRecord(db, userId, armor.id, { linkedModSetId: modSet.id, now });

  const attachments: MaterializeAttachment[] = [];
  if (variantId) {
    attachments.push(await attachReplacing(db, userId, variantId, "armor", armor.id, now));
    if (modSet) {
      attachments.push(await attachReplacing(db, userId, variantId, "mod", modSet.id, now));
    }
  }

  return {
    armorSet: {
      id: armor.id,
      name: armor.name,
      type: "armor",
      optimizerConstraints: body.constraints,
      ...(modSet ? { linkedModSetId: modSet.id } : {}),
    },
    ...(modSet ? { modSet: { id: modSet.id, name: modSet.name, type: "mod" as const } } : {}),
    attachments,
  };
}
