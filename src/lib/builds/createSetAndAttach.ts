import { z } from "zod";

import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import { replaceAttachmentByType } from "@/lib/builds/replaceAttachmentByType";
import type { AppDatabase } from "@/lib/db/client";
import { getBuild } from "@/lib/db/repositories/buildRepository";
import { createSetRecord, getSet } from "@/lib/db/repositories/setRepository";
import {
  getVariant,
  listAttachments,
} from "@/lib/db/repositories/variantRepository";
import type { SetType } from "@/lib/sets/schemas";
import { allocateUniqueSetName } from "@/lib/sets/uniqueSetName";

export const createSetAndAttachBodySchema = z.object({
  variantId: z.string().min(1),
  type: z.enum(["weapon", "armor", "mod", "pair"]),
  name: z.string().trim().min(1).max(120).optional(),
  tagIds: z.array(z.string()).optional(),
  attachNow: z.boolean().optional().default(true),
});

export type CreateSetAndAttachBody = z.input<typeof createSetAndAttachBodySchema>;

const TYPE_LABEL: Record<CreateSetAndAttachBody["type"], string> = {
  armor: "Armor",
  weapon: "Weapons",
  mod: "Mods",
  pair: "Pair",
};

/**
 * Create an empty library Set and optionally live-attach it to a variant
 * with replace-by-type (finish-build path).
 */
export async function createSetAndAttach(
  db: AppDatabase,
  userId: number,
  buildId: string,
  body: CreateSetAndAttachBody,
) {
  const build = getBuild(db, userId, buildId);
  if (!build) {
    throw new ApiError(API_ERROR_CODES.INVALID_ITEM, "BUILD_NOT_FOUND", { buildId }, 404);
  }

  const variant = getVariant(db, buildId, body.variantId);
  if (!variant) {
    throw new ApiError(
      API_ERROR_CODES.INVALID_ITEM,
      "VARIANT_NOT_FOUND",
      { buildId, variantId: body.variantId },
      400,
    );
  }

  const type = body.type;
  const baseName =
    body.name?.trim() || `${build.name} ${TYPE_LABEL[type] ?? type}`;
  const name = allocateUniqueSetName(db, userId, type, baseName);
  const id = crypto.randomUUID();
  const now = new Date().toISOString();

  createSetRecord(db, userId, {
    id,
    name,
    type,
    tagIds: (body.tagIds ?? []) as never,
    now,
  });

  const set = getSet(db, userId, id)!;
  const attachNow = body.attachNow !== false;

  if (!attachNow) {
    return {
      set: { id: set.id, name: set.name, type: set.type as SetType },
      attachment: null as null,
    };
  }

  const before = listAttachments(db, variant.id);
  const priorSameType = before
    .map((a) => {
      const s = getSet(db, userId, a.setId);
      return s?.type === type ? a.setId : null;
    })
    .filter((x): x is string => x != null);

  await replaceAttachmentByType(db, userId, variant.id, type, id, now);

  return {
    set: { id: set.id, name: set.name, type: set.type as SetType },
    attachment: {
      setId: id,
      mode: "live" as const,
      variantId: variant.id,
      replacedSetIds: priorSameType,
    },
  };
}
