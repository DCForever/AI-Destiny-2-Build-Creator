import type { ConceptTagId } from "@/data/conceptTags";
import { conceptTagIdsSchema } from "@/data/conceptTags";
import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import type { AppDatabase } from "@/lib/db/client";
import {
  createBuildRecord,
  deleteBuildRecord,
  getBuild,
  listBuilds,
  listBuildsFiltered,
  updateBuildRecord,
} from "@/lib/db/repositories/buildRepository";
import {
  createVariantRecord,
  getVariant,
  listAttachments,
  listVariants,
  updateVariantRecord,
  type AttachmentRecord,
  type VariantRecord,
} from "@/lib/db/repositories/variantRepository";
import {
  getSynergiesByIds,
  listSynergies,
  seedDefaultSynergies,
} from "@/lib/db/repositories/synergyRepository";
import { prepareAttachments } from "@/lib/builds/attachmentService";
import type { CreateBuildInput, UpdateBuildInput, UpdateVariantInput } from "@/lib/builds/schemas";
import {
  assertNoSlotConflicts,
  assertVariantNotEmpty,
  armorManifestSlotToEquipment,
  resolveVariantEquipment,
  weaponManifestSlotToEquipment,
} from "@/lib/builds/resolveVariant";
import type { EquipmentSlot } from "@/lib/sets/schemas";
import { getServices } from "@/lib/services";

function parseTags(tagIds: unknown): ConceptTagId[] {
  const result = conceptTagIdsSchema.safeParse(tagIds ?? []);
  if (!result.success) {
    throw new ApiError(API_ERROR_CODES.INVALID_TAG, "Invalid concept tag ids");
  }
  return result.data;
}

function assertSynergiesPresent(synergyIds: string[]): void {
  if (synergyIds.length === 0) {
    throw new ApiError(API_ERROR_CODES.NO_SYNERGY, "Build must designate at least one synergy", {}, 400);
  }
}

async function lookupExoticSlots(
  exoticWeaponHash: number | null,
  exoticArmorHash: number,
): Promise<{ weaponSlot: EquipmentSlot | null; armorSlot: EquipmentSlot | null }> {
  try {
    const { entityCache } = await getServices();
    let weaponSlot: EquipmentSlot | null = null;
    let armorSlot: EquipmentSlot | null = null;

    if (exoticWeaponHash) {
      const exotics = await entityCache.getStore("exotic-weapons");
      const match = exotics.find((w) => w.hash === exoticWeaponHash);
      if (match) weaponSlot = weaponManifestSlotToEquipment(match.slot);
    }

    const armor = await entityCache.getStore("exotic-armor");
    const armorMatch = armor.find((a) => a.hash === exoticArmorHash);
    if (armorMatch) armorSlot = armorManifestSlotToEquipment(armorMatch.slot);

    return { weaponSlot, armorSlot };
  } catch {
    return { weaponSlot: exoticWeaponHash ? "primary" : null, armorSlot: "chest" };
  }
}

export type BuildDetail = Awaited<ReturnType<typeof getBuildDetail>>;

export async function getBuildDetail(db: AppDatabase, userId: number, buildId: string) {
  const build = getBuild(db, userId, buildId);
  if (!build) return null;

  const variants = listVariants(db, buildId);
  const synergies = getSynergiesByIds(db, userId, build.synergyIds);

  const variantsWithAttachments = await Promise.all(
    variants.map(async (variant) => {
      const attachments = listAttachments(db, variant.id);
      const slots = await lookupExoticSlots(variant.exoticWeaponHash, build.exoticArmorHash);
      const resolved = await resolveVariantEquipment(db, userId, build, variant, attachments, {
        exoticWeaponSlot: slots.weaponSlot,
        exoticArmorSlot: slots.armorSlot,
      });
      return { ...variant, attachments, resolved };
    }),
  );

  return { ...build, synergies, variants: variantsWithAttachments };
}

export function listUserBuilds(
  db: AppDatabase,
  userId: number,
  opts?: {
    tags?: ConceptTagId[];
    exoticArmorHash?: number;
    exoticWeaponHash?: number;
    synergyId?: string;
  },
) {
  if (
    opts?.exoticArmorHash !== undefined ||
    opts?.exoticWeaponHash !== undefined ||
    opts?.synergyId ||
    opts?.tags?.length
  ) {
    return listBuildsFiltered(db, userId, opts ?? {});
  }
  return listBuilds(db, userId);
}

export async function createUserBuild(db: AppDatabase, userId: number, input: CreateBuildInput) {
  const tags = parseTags(input.tagIds);

  seedDefaultSynergies(db, userId);
  const synergyIds =
    input.synergyIds && input.synergyIds.length > 0
      ? input.synergyIds
      : listSynergies(db, userId).slice(0, 1).map((s) => s.id);

  assertSynergiesPresent(synergyIds);
  const found = getSynergiesByIds(db, userId, synergyIds);
  if (found.length !== synergyIds.length) {
    throw new ApiError(API_ERROR_CODES.NO_SYNERGY, "One or more synergies not found");
  }

  const now = new Date().toISOString();
  const buildId = crypto.randomUUID();
  const variantId = crypto.randomUUID();

  createBuildRecord(db, userId, {
    id: buildId,
    name: input.name,
    className: input.className,
    subclass: input.subclass,
    exoticArmorHash: input.exoticArmorHash,
    exoticArmorName: input.exoticArmorName ?? `Exotic (${input.exoticArmorHash})`,
    tagIds: tags,
    synergyIds,
    now,
  });

  const defaultVariant = input.defaultVariant ?? {};
  createVariantRecord(db, {
    id: variantId,
    buildId,
    name: defaultVariant.name ?? "Default",
    isDefault: true,
    exoticWeaponHash: defaultVariant.exoticWeaponHash ?? null,
    exoticWeaponName: defaultVariant.exoticWeaponName ?? null,
    notes: defaultVariant.notes ?? null,
    now,
  });

  if (defaultVariant.attachments?.length) {
    await prepareAttachments(db, userId, variantId, defaultVariant.attachments, now);
    await validateVariantSave(db, userId, buildId, variantId);
  }

  return getBuildDetail(db, userId, buildId);
}

export async function updateUserBuild(
  db: AppDatabase,
  userId: number,
  buildId: string,
  input: UpdateBuildInput,
) {
  if (input.synergyIds) assertSynergiesPresent(input.synergyIds);
  if (input.tagIds) parseTags(input.tagIds);

  if (input.synergyIds) {
    const found = getSynergiesByIds(db, userId, input.synergyIds);
    if (found.length !== input.synergyIds.length) {
      throw new ApiError(API_ERROR_CODES.NO_SYNERGY, "One or more synergies not found");
    }
  }

  const now = new Date().toISOString();
  updateBuildRecord(db, userId, buildId, {
    name: input.name,
    className: input.className,
    subclass: input.subclass,
    exoticArmorHash: input.exoticArmorHash,
    exoticArmorName: input.exoticArmorName,
    tagIds: input.tagIds,
    synergyIds: input.synergyIds,
    now,
  });
  return getBuildDetail(db, userId, buildId);
}

export async function updateUserVariant(
  db: AppDatabase,
  userId: number,
  buildId: string,
  variantId: string,
  input: UpdateVariantInput,
) {
  const build = getBuild(db, userId, buildId);
  if (!build) return null;

  const now = new Date().toISOString();
  updateVariantRecord(db, buildId, variantId, {
    name: input.name,
    exoticWeaponHash: input.exoticWeaponHash,
    exoticWeaponName: input.exoticWeaponName,
    notes: input.notes,
    now,
  });

  if (input.attachments) {
    await prepareAttachments(db, userId, variantId, input.attachments, now);
    await validateVariantSave(db, userId, buildId, variantId);
  }

  return getBuildDetail(db, userId, buildId);
}

export async function validateVariantSave(
  db: AppDatabase,
  userId: number,
  buildId: string,
  variantId: string,
): Promise<void> {
  const build = getBuild(db, userId, buildId);
  const variant = getVariant(db, buildId, variantId);
  if (!build || !variant) return;

  const attachments = listAttachments(db, variantId);
  const slots = await lookupExoticSlots(variant.exoticWeaponHash, build.exoticArmorHash);
  const resolved = await resolveVariantEquipment(db, userId, build, variant, attachments, {
    exoticWeaponSlot: slots.weaponSlot,
    exoticArmorSlot: slots.armorSlot,
  });

  assertNoSlotConflicts(resolved);
  assertVariantNotEmpty(resolved);
}

export function deleteUserBuild(db: AppDatabase, userId: number, buildId: string) {
  return deleteBuildRecord(db, userId, buildId);
}

export async function getResolvedVariant(
  db: AppDatabase,
  userId: number,
  buildId: string,
  variantId: string,
) {
  const build = getBuild(db, userId, buildId);
  const variant = getVariant(db, buildId, variantId);
  if (!build || !variant) return null;

  const attachments = listAttachments(db, variantId);
  const slots = await lookupExoticSlots(variant.exoticWeaponHash, build.exoticArmorHash);
  return resolveVariantEquipment(db, userId, build, variant, attachments, {
    exoticWeaponSlot: slots.weaponSlot,
    exoticArmorSlot: slots.armorSlot,
  });
}

export type { VariantRecord, AttachmentRecord };
