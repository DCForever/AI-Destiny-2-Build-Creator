import type { ConceptTagId } from "@/data/conceptTags";
import { conceptTagIdsSchema } from "@/data/conceptTags";
import type { AppDatabase } from "@/lib/db/client";
import { listBuilds } from "@/lib/db/repositories/buildRepository";
import {
  createSetRecord,
  deleteSetRecord,
  findAttachmentsBySetId,
  findDuplicateName,
  getSet,
  listSets,
  listSetsByTags,
  updateSetRecord,
} from "@/lib/db/repositories/setRepository";
import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import type { CreateSetInput, SetType, UpdateSetInput } from "@/lib/sets/schemas";
import {
  parseOptimizerConstraints,
  serializeOptimizerConstraints,
} from "@/lib/optimizer/types";
import {
  hasEmptyModSlots,
  listActiveSetItems,
  listSetItems,
  softRemoveSetItem,
  upsertSetItem,
} from "@/lib/sets/setItemService";
import type { SetItemInput } from "@/lib/sets/schemas";
import { enrichSetItems } from "@/lib/sets/enrichSetItems";
import { assertSetMinimumOccupancy } from "@/lib/sets/setMinimumOccupancy";
import { assertArmorSetBonusConstraint, parseArmorSetBonusConstraint, serializeArmorSetBonusConstraint, type ArmorSetBonusConstraint } from "@/lib/sets/armorSetBonusConstraint";
import { loadSetBonusMembershipIndex, toConstrainedArmorPieces } from "@/lib/sets/armorSetBonusConstraint.server";

function parseTagIds(tagIds: unknown): ConceptTagId[] {
  const result = conceptTagIdsSchema.safeParse(tagIds ?? []);
  if (!result.success) {
    throw new ApiError(API_ERROR_CODES.INVALID_TAG, "Invalid concept tag ids", {
      issues: result.error.issues.map((i) => i.message),
    });
  }
  return result.data;
}

export type SetDetail = Awaited<ReturnType<typeof getSetDetail>>;

export async function getSetDetail(db: AppDatabase, userId: number, setId: string) {
  const set = getSet(db, userId, setId);
  if (!set) return null;
  const rawItems = await listSetItems(db, setId);
  const { items, armorStatTotals } = await enrichSetItems(db, userId, rawItems);
  const activeItems = items.filter((i) => !i.removedAt);

  const attachmentRefs = findAttachmentsBySetId(db, setId);
  const userBuildIds = new Set(listBuilds(db, userId).map((b) => b.id));
  const byBuild = new Map<
    string,
    { buildId: string; buildName: string; variantNames: string[] }
  >();
  for (const ref of attachmentRefs) {
    if (!userBuildIds.has(ref.buildId)) continue;
    const existing = byBuild.get(ref.buildId);
    if (existing) {
      if (!existing.variantNames.includes(ref.variantName)) {
        existing.variantNames.push(ref.variantName);
      }
    } else {
      byBuild.set(ref.buildId, {
        buildId: ref.buildId,
        buildName: ref.buildName,
        variantNames: [ref.variantName],
      });
    }
  }
  const usedByBuilds = [...byBuild.values()].sort((a, b) =>
    a.buildName.localeCompare(b.buildName, undefined, { sensitivity: "base" }),
  );

  return {
    ...set,
    optimizerConstraints: parseOptimizerConstraints(set.optimizerConstraints),
    setBonusConstraint: parseArmorSetBonusConstraint(set.setBonusConstraint),
    items,
    armorStatTotals:
      set.type === "armor" ? armorStatTotals : null,
    modEncourage: hasEmptyModSlots(set.type, activeItems),
    usedByBuilds,
  };
}

async function enforceArmorSetBonusConstraint(
  setType: SetType,
  constraint: ArmorSetBonusConstraint | null,
  items: Array<{ itemHash: number; slot?: string; itemName?: string }>,
  opts: { requireTier: boolean; context: string },
): Promise<void> {
  if (setType !== "armor" && !constraint) return;
  const pieces = await toConstrainedArmorPieces(items);
  const membership = constraint ? await loadSetBonusMembershipIndex() : new Map<number, number>();
  assertArmorSetBonusConstraint(constraint, pieces, membership, {
    setType,
    requireTier: opts.requireTier,
    context: opts.context,
  });
}

function normalizeSetBonusConstraintInput(
  setType: SetType,
  raw: CreateSetInput["setBonusConstraint"] | UpdateSetInput["setBonusConstraint"],
): string | null | undefined {
  if (raw === undefined) return undefined;
  if (raw === null) return null;
  if (setType !== "armor") {
    throw new ApiError(
      API_ERROR_CODES.INVALID_ITEM,
      "Armor set bonus constraint is only allowed on Armor Sets",
      { setType },
      400,
    );
  }
  return serializeArmorSetBonusConstraint(raw);
}

export function listUserSets(
  db: AppDatabase,
  userId: number,
  opts?: { type?: SetType; tags?: ConceptTagId[] },
) {
  if (opts?.tags?.length) {
    return listSetsByTags(db, userId, opts.tags, opts.type);
  }
  return listSets(db, userId, opts?.type);
}

export async function createUserSet(db: AppDatabase, userId: number, input: CreateSetInput) {
  const tags = parseTagIds(input.tagIds);
  if (findDuplicateName(db, userId, input.type, input.name)) {
    throw new ApiError(API_ERROR_CODES.DUPLICATE_SET_NAME, "Set name already in use for this type", {
      type: input.type,
      name: input.name,
    });
  }

  const now = new Date().toISOString();
  const id = crypto.randomUUID();
  const constraintsJson =
    input.optimizerConstraints === undefined
      ? null
      : input.optimizerConstraints === null
        ? null
        : serializeOptimizerConstraints(input.optimizerConstraints);
  const setBonusJson =
    input.setBonusConstraint === undefined
      ? null
      : normalizeSetBonusConstraintInput(input.type, input.setBonusConstraint) ?? null;
  createSetRecord(db, userId, {
    id,
    name: input.name,
    type: input.type,
    tagIds: tags,
    now,
    optimizerConstraints: constraintsJson,
    setBonusConstraint: setBonusJson,
    linkedModSetId: input.linkedModSetId ?? null,
  });
  return getSetDetail(db, userId, id);
}

export async function updateUserSet(
  db: AppDatabase,
  userId: number,
  setId: string,
  input: UpdateSetInput,
) {
  const existing = getSet(db, userId, setId);
  if (!existing) return null;

  if (input.name && input.type && findDuplicateName(db, userId, input.type, input.name, setId)) {
    throw new ApiError(API_ERROR_CODES.DUPLICATE_SET_NAME, "Set name already in use for this type");
  }
  if (input.name && !input.type && findDuplicateName(db, userId, existing.type, input.name, setId)) {
    throw new ApiError(API_ERROR_CODES.DUPLICATE_SET_NAME, "Set name already in use for this type");
  }

  if (input.tagIds) {
    parseTagIds(input.tagIds);
  }

  const nextType = input.type ?? existing.type;
  if (input.setBonusConstraint !== undefined) {
    const constraintJson = normalizeSetBonusConstraintInput(nextType, input.setBonusConstraint);
    const constraint =
      constraintJson == null ? null : parseArmorSetBonusConstraint(constraintJson);
    const active = await listActiveSetItems(db, setId);
    await enforceArmorSetBonusConstraint(nextType, constraint, active, {
      requireTier: true,
      context: "update_constraint",
    });
  }

  const now = new Date().toISOString();
  const constraintsJson =
    input.optimizerConstraints === undefined
      ? undefined
      : input.optimizerConstraints === null
        ? null
        : serializeOptimizerConstraints(input.optimizerConstraints);
  const setBonusJson =
    input.setBonusConstraint === undefined
      ? undefined
      : normalizeSetBonusConstraintInput(nextType, input.setBonusConstraint);
  updateSetRecord(db, userId, setId, {
    name: input.name,
    type: input.type,
    tagIds: input.tagIds,
    now,
    ...(constraintsJson !== undefined ? { optimizerConstraints: constraintsJson } : {}),
    ...(setBonusJson !== undefined ? { setBonusConstraint: setBonusJson } : {}),
    ...(input.linkedModSetId !== undefined ? { linkedModSetId: input.linkedModSetId } : {}),
  });
  return getSetDetail(db, userId, setId);
}

export function deleteUserSet(db: AppDatabase, userId: number, setId: string) {
  const existing = getSet(db, userId, setId);
  if (!existing) return { deleted: false as const };

  const attachments = findAttachmentsBySetId(db, setId);
  if (attachments.length > 0) {
    throw new ApiError(
      API_ERROR_CODES.SET_IN_USE,
      "Set is attached to build variants",
      {
        buildIds: [...new Set(attachments.map((a) => a.buildId))],
        variantIds: attachments.map((a) => a.variantId),
      },
      409,
    );
  }

  return { deleted: deleteSetRecord(db, userId, setId) };
}

export async function addSetItem(
  db: AppDatabase,
  userId: number,
  setId: string,
  input: SetItemInput,
) {
  const set = getSet(db, userId, setId);
  if (!set) return null;

  const active = await listActiveSetItems(db, setId);
  if (set.type !== "fashion" && set.type !== "mod") {
    const domainSlots =
      set.type === "weapon"
        ? ["primary", "special", "heavy"]
        : set.type === "armor"
          ? ["helmet", "arms", "chest", "legs", "class_item"]
          : ["exotic_weapon", "exotic_armor"];
    const occupied = active.filter((i) => domainSlots.includes(i.slot)).length;
    if (occupied >= domainSlots.length && !input.confirmReplace) {
      // slot-level check handled in upsertSetItem
    }
  }

  // DBR-SETB-004: reject non-family non-exotic on fill; tier checked on attach/save.
  if (set.type === "armor") {
    const constraint = parseArmorSetBonusConstraint(set.setBonusConstraint);
    if (constraint) {
      const active = await listActiveSetItems(db, setId);
      const projected = [
        ...active.filter((i) => i.slot !== input.slot),
        {
          itemHash: input.itemHash,
          slot: input.slot,
          itemName: input.itemName,
        },
      ];
      await enforceArmorSetBonusConstraint(set.type, constraint, projected, {
        requireTier: false,
        context: "fill",
      });
    }
  }

  await upsertSetItem(db, setId, set.type, input);
  return getSetDetail(db, userId, setId);
}

export async function removeSetItem(db: AppDatabase, userId: number, setId: string, itemId: string) {
  const set = getSet(db, userId, setId);
  if (!set) return null;

  const active = await listActiveSetItems(db, setId);
  const remaining = active.filter((i) => i.id !== itemId);

  // Attached packages may not become partial (non-empty below min). Empty OK.
  const attachments = findAttachmentsBySetId(db, setId);
  if (attachments.length > 0) {
    assertSetMinimumOccupancy(set.type, remaining, { context: "remove_while_attached" });
    if (set.type === "armor") {
      const constraint = parseArmorSetBonusConstraint(set.setBonusConstraint);
      if (constraint) {
        await enforceArmorSetBonusConstraint(set.type, constraint, remaining, {
          requireTier: true,
          context: "remove_while_attached",
        });
      }
    }
  }

  softRemoveSetItem(db, setId, itemId);
  return getSetDetail(db, userId, setId);
}

/** Stub — returns empty until manifest perk index wired (T018). */
export function suggestRollAlternatives(
  ..._args: [number, number[]]
): Array<{ itemHash: number; name: string }> {
  void _args;
  return [];
}
