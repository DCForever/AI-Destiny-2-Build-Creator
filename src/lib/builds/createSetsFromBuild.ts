import { z } from "zod";

import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import type { AppDatabase } from "@/lib/db/client";
import { getBuild } from "@/lib/db/repositories/buildRepository";
import { getVariant, listAttachments, listVariants } from "@/lib/db/repositories/variantRepository";
import { seedConstraintsFromBuild } from "@/lib/optimizer/seedConstraintsFromBuild";
import { serializeOptimizerConstraints } from "@/lib/optimizer/types";
import { replaceAttachmentByType } from "@/lib/builds/replaceAttachmentByType";
import { resolveVariantEquipment, type SlotClaim } from "@/lib/builds/resolveVariant";
import {
  ARMOR_SLOTS,
  WEAPON_SLOTS,
  type ArmorSetSlot,
  type SetType,
} from "@/lib/sets/schemas";
import { createSetRecord } from "@/lib/db/repositories/setRepository";
import { upsertSetItem } from "@/lib/sets/setItemService";
import { allocateUniqueSetName } from "@/lib/sets/uniqueSetName";

export const createSetsFromBuildBodySchema = z.object({
  variantId: z.string().min(1).optional(),
  categories: z.array(z.enum(["armor", "weapon", "mod"])).optional(),
  attachNow: z.boolean().optional().default(true),
  namePrefix: z.string().trim().min(1).max(100).optional(),
});

export type CreateSetsFromBuildBody = z.infer<typeof createSetsFromBuildBodySchema>;

const ARMOR_SLOT_SET = new Set<string>(ARMOR_SLOTS);
const WEAPON_SLOT_SET = new Set<string>(WEAPON_SLOTS);

function claimsForCategory(
  equipment: Partial<Record<string, SlotClaim>>,
  category: "armor" | "weapon",
): SlotClaim[] {
  const slots = category === "armor" ? ARMOR_SLOT_SET : WEAPON_SLOT_SET;
  return Object.values(equipment).filter(
    (c): c is SlotClaim => c != null && slots.has(c.slot),
  );
}

export async function createSetsFromBuild(
  db: AppDatabase,
  userId: number,
  buildId: string,
  body: CreateSetsFromBuildBody,
) {
  const build = getBuild(db, userId, buildId);
  if (!build) {
    throw new ApiError(API_ERROR_CODES.INVALID_ITEM, "BUILD_NOT_FOUND", { buildId }, 404);
  }

  const variants = listVariants(db, buildId);
  const variant =
    (body.variantId
      ? getVariant(db, buildId, body.variantId)
      : variants.find((v) => v.isDefault) ?? variants[0]) ?? null;
  if (!variant) {
    throw new ApiError(API_ERROR_CODES.INVALID_ITEM, "VARIANT_NOT_FOUND", { buildId }, 400);
  }

  const attachments = listAttachments(db, variant.id);
  const resolved = await resolveVariantEquipment(db, userId, build, variant, attachments);
  const categories = body.categories ?? (["armor", "weapon", "mod"] as const);
  const prefix = body.namePrefix?.trim() || build.name;
  const now = new Date().toISOString();
  const attachNow = body.attachNow !== false;

  const createdSets: Array<{ id: string; type: SetType; name: string }> = [];
  const attachmentResults: Array<{ setId: string; mode: "live"; variantId: string }> = [];
  const skippedCategories: Array<"armor" | "weapon" | "mod"> = [];

  for (const category of categories) {
    if (category === "mod") {
      // Mod claims are not in resolveVariant equipment map yet for snapshot simplicity —
      // skip unless we later expand mod attachment expansion. Spec allows skipping empty.
      skippedCategories.push("mod");
      continue;
    }

    const claims = claimsForCategory(resolved.equipment, category);
    if (claims.length === 0) {
      skippedCategories.push(category);
      continue;
    }

    const type: SetType = category;
    const label = category === "armor" ? "Armor" : "Weapons";
    const name = allocateUniqueSetName(db, userId, type, `${prefix} ${label}`);
    const id = crypto.randomUUID();

    const constraintsJson =
      type === "armor"
        ? serializeOptimizerConstraints(
            seedConstraintsFromBuild({
              exoticArmorHash: build.exoticArmorHash,
              softStatTargets: build.softStatTargets,
            }),
          )
        : null;

    createSetRecord(db, userId, {
      id,
      name,
      type,
      tagIds: [],
      now,
      optimizerConstraints: constraintsJson,
    });

    for (const claim of claims) {
      await upsertSetItem(db, id, type, {
        slot: claim.slot,
        itemHash: claim.itemHash,
        itemName: claim.itemName,
        instanceId: claim.instanceId ?? undefined,
        selectedPerks: claim.selectedPerks,
        confirmReplace: true,
      });
    }

    createdSets.push({ id, type, name });

    if (attachNow) {
      await replaceAttachmentByType(db, userId, variant.id, type, id, now);
      attachmentResults.push({ setId: id, mode: "live", variantId: variant.id });
    }
  }

  if (createdSets.length === 0) {
    throw new ApiError(
      API_ERROR_CODES.INVALID_ITEM,
      "NOTHING_TO_CREATE",
      { skippedCategories },
      400,
    );
  }

  return {
    createdSets,
    attachments: attachmentResults,
    skippedCategories,
  };
}

/** @internal test helper */
export function isArmorSlot(slot: string): slot is ArmorSetSlot {
  return ARMOR_SLOT_SET.has(slot);
}
