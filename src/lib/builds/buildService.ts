import type { ConceptTagId } from "@/data/conceptTags";
import { conceptTagIdsSchema } from "@/data/conceptTags";
import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import type { AppDatabase } from "@/lib/db/client";
import {
  createBuildRecord,
  deleteBuildRecord,
  findBuildByNameClass,
  getBuild,
  listBuilds,
  listBuildsFiltered,
  updateBuildRecord,
  type BuildRecord,
} from "@/lib/db/repositories/buildRepository";
import {
  createVariantRecord,
  getVariant,
  listAttachments,
  listVariants,
  replaceAttachments,
  updateVariantRecord,
  type AttachmentRecord,
  type VariantRecord,
} from "@/lib/db/repositories/variantRepository";
import { getSet } from "@/lib/db/repositories/setRepository";
import { prepareAttachments } from "@/lib/builds/attachmentService";
import { deriveDefaultBuildName } from "@/lib/builds/defaultBuildName";
import {
  designationKey,
  designationLabel,
  resolveDesignatedSynergies,
  type SynergyTypeDesignation,
} from "@/lib/builds/resolveDesignatedSynergies";
import { buildInventoryPinIndex, computeEquipReady } from "@/lib/builds/equipReady";
import type { CreateBuildInput, UpdateBuildInput, UpdateVariantInput } from "@/lib/builds/schemas";
import { normalizeSoftStatTargets } from "@/lib/builds/softStatTargets";
import {
  assertFullCombatLoadout,
  assertNoSlotConflicts,
  effectiveExoticWeapon,
  resolveVariantEquipment,
} from "@/lib/builds/resolveVariant";
import {
  isIdentityExoticArmorChange,
  lookupExoticArmorSlot,
  lookupExoticSlots,
  modeFromArmorSlot,
} from "@/lib/builds/exoticArmorIntent";
import { listActiveSetItems } from "@/lib/sets/setItemService";
import { listInventoryItems } from "@/lib/db/repositories/inventoryRepository";
import type { SynergyType } from "@/lib/synergies/schemas";
import { validateSynergySubType } from "@/lib/synergies/validateSynergySubType";

function parseTags(tagIds: unknown): ConceptTagId[] {
  const result = conceptTagIdsSchema.safeParse(tagIds ?? []);
  if (!result.success) {
    throw new ApiError(API_ERROR_CODES.INVALID_TAG, "Invalid concept tag ids");
  }
  return result.data;
}

function assertTypesPresent(types: SynergyTypeDesignation[]): void {
  if (types.length === 0) {
    throw new ApiError(
      API_ERROR_CODES.NO_SYNERGY,
      "Build must designate at least one synergy type",
      {},
      400,
    );
  }
}

function normalizeDesignations(
  input: Array<{ type: SynergyType; subType?: string | null }>,
): SynergyTypeDesignation[] {
  const seen = new Set<string>();
  const out: SynergyTypeDesignation[] = [];
  for (const raw of input) {
    const check = validateSynergySubType(raw.type, raw.subType);
    if (!check.ok) {
      throw new ApiError(API_ERROR_CODES.INVALID_SYNERGY_SUBTYPE, check.reason);
    }
    const designation: SynergyTypeDesignation = {
      type: raw.type,
      subType: check.subType,
    };
    const key = designationKey(designation);
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(designation);
  }
  return out;
}

function sortedDesignationKey(types: SynergyTypeDesignation[]): string {
  return [...types]
    .map((d) => designationKey(d))
    .sort()
    .join(",");
}

function assertUniqueBuildName(
  db: AppDatabase,
  userId: number,
  className: string,
  name: string,
  excludeId?: string,
): void {
  const clash = findBuildByNameClass(db, userId, className, name, excludeId);
  if (clash) {
    throw new ApiError(
      API_ERROR_CODES.DUPLICATE_BUILD_NAME,
      "Build name must be unique per class",
      { className, name },
      409,
    );
  }
}

async function identityFieldsChanged(
  existing: BuildRecord,
  input: UpdateBuildInput,
): Promise<string[]> {
  const fields: string[] = [];
  if (input.synergyTypes !== undefined) {
    const next = sortedDesignationKey(normalizeDesignations(input.synergyTypes));
    const prev = sortedDesignationKey(existing.synergyTypes);
    if (next !== prev) fields.push("synergyTypes");
  }
  if (input.exoticArmorHash !== undefined && input.exoticArmorHash !== existing.exoticArmorHash) {
    const [existingSlot, nextSlot] = await Promise.all([
      lookupExoticArmorSlot(existing.exoticArmorHash),
      lookupExoticArmorSlot(input.exoticArmorHash),
    ]);
    const existingMode = modeFromArmorSlot(existingSlot, existing.exoticArmorHash);
    const nextMode = modeFromArmorSlot(nextSlot, input.exoticArmorHash);
    if (
      isIdentityExoticArmorChange(
        existing.exoticArmorHash,
        input.exoticArmorHash,
        existingMode,
        nextMode,
      )
    ) {
      fields.push("exoticArmorHash");
    }
  }
  if (input.exoticWeaponHash !== undefined && input.exoticWeaponHash !== existing.exoticWeaponHash) {
    fields.push("exoticWeaponHash");
  }
  if (input.pinnedSuper !== undefined && input.pinnedSuper !== existing.pinnedSuper) {
    fields.push("pinnedSuper");
  }
  return fields;
}

async function variantHasMods(
  db: AppDatabase,
  userId: number,
  attachments: AttachmentRecord[],
): Promise<boolean> {
  for (const attachment of attachments) {
    const set = getSet(db, userId, attachment.setId);
    if (set?.type === "mod") return true;
    if (attachment.mode === "snapshot" && attachment.snapshotConfigs?.some((c) => c.modHashes?.length)) {
      return true;
    }
    const items = await listActiveSetItems(db, attachment.setId);
    if (items.some((item) => (item.modHashes?.length ?? 0) > 0)) return true;
  }
  return false;
}

export type BuildDetail = Awaited<ReturnType<typeof getBuildDetail>>;

export async function getBuildDetail(db: AppDatabase, userId: number, buildId: string) {
  const build = getBuild(db, userId, buildId);
  if (!build) return null;

  const variants = listVariants(db, buildId);
  const bridge = resolveDesignatedSynergies(db, userId, build.synergyTypes);
  const synergies = bridge.matchedSynergies;
  const synergyTypes = bridge.designations.map((d) => ({
    ...d,
    label: designationLabel(d),
    key: designationKey(d),
  }));

  const variantsWithAttachments = await Promise.all(
    variants.map(async (variant) => {
      const attachments = listAttachments(db, variant.id).map((attachment) => {
        const set = getSet(db, userId, attachment.setId);
        return {
          ...attachment,
          set: set
            ? { id: set.id, name: set.name, type: set.type }
            : undefined,
        };
      });
      const weapon = effectiveExoticWeapon(build, variant);
      const slots = await lookupExoticSlots(weapon.exoticWeaponHash, build.exoticArmorHash);
      const resolved = await resolveVariantEquipment(db, userId, build, variant, attachments, {
        exoticWeaponSlot: slots.weaponSlot,
        exoticArmorSlot: slots.armorSlot,
      });
      return { ...variant, attachments, resolved };
    }),
  );

  return { ...build, synergyTypes, synergies, variants: variantsWithAttachments };
}

export function listUserBuilds(
  db: AppDatabase,
  userId: number,
  opts?: {
    tags?: ConceptTagId[];
    exoticArmorHash?: number;
    exoticWeaponHash?: number;
    synergyType?: string;
    synergySubType?: string | null;
  },
) {
  if (
    opts?.exoticArmorHash !== undefined ||
    opts?.exoticWeaponHash !== undefined ||
    opts?.synergyType ||
    opts?.tags?.length
  ) {
    return listBuildsFiltered(db, userId, opts ?? {});
  }
  return listBuilds(db, userId);
}

function resolveCreateName(
  db: AppDatabase,
  userId: number,
  input: CreateBuildInput,
  synergyNames: string[],
): string {
  const trimmed = input.name?.trim() ?? "";
  if (trimmed) {
    assertUniqueBuildName(db, userId, input.className, trimmed);
    return trimmed;
  }
  const derived = deriveDefaultBuildName({
    className: input.className,
    subclass: input.subclass,
    pinnedSuper: input.pinnedSuper,
    exoticArmorHash: input.exoticArmorHash,
    exoticArmorName: input.exoticArmorName,
    exoticWeaponHash: input.exoticWeaponHash,
    exoticWeaponName: input.exoticWeaponName,
    synergyNames,
  });
  assertUniqueBuildName(db, userId, input.className, derived);
  return derived;
}

export async function createUserBuild(db: AppDatabase, userId: number, input: CreateBuildInput) {
  const tags = parseTags(input.tagIds);
  const synergyTypes = normalizeDesignations(input.synergyTypes ?? []);
  assertTypesPresent(synergyTypes);

  const name = resolveCreateName(
    db,
    userId,
    input,
    synergyTypes.map((d) => designationLabel(d)),
  );

  const exoticArmorHash = input.exoticArmorHash ?? null;
  const exoticArmorName =
    exoticArmorHash == null
      ? null
      : (input.exoticArmorName ?? `Exotic (${exoticArmorHash})`);
  const exoticWeaponHash = input.exoticWeaponHash ?? null;
  const exoticWeaponName =
    exoticWeaponHash == null
      ? null
      : (input.exoticWeaponName ?? `Exotic (${exoticWeaponHash})`);
  const pinnedSuper = input.pinnedSuper ?? null;

  const now = new Date().toISOString();
  const buildId = crypto.randomUUID();
  const variantId = crypto.randomUUID();

  createBuildRecord(db, userId, {
    id: buildId,
    name,
    className: input.className,
    subclass: input.subclass,
    exoticArmorHash,
    exoticArmorName,
    exoticWeaponHash,
    exoticWeaponName,
    pinnedSuper,
    softStatTargets: input.softStatTargets
      ? normalizeSoftStatTargets(input.softStatTargets)
      : {},
    tagIds: tags,
    synergyTypes,
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
    artifactHash: defaultVariant.artifactHash ?? null,
    artifactName: defaultVariant.artifactName ?? null,
    artifactConfig: defaultVariant.artifactConfig ?? [],
    notes: defaultVariant.notes ?? null,
    now,
  });

  if (defaultVariant.attachments?.length) {
    await prepareAttachments(db, userId, variantId, defaultVariant.attachments, now);
    await validateVariantSave(db, userId, buildId, variantId);
  }

  return getBuildDetail(db, userId, buildId);
}

async function forkBuildWithIdentity(
  db: AppDatabase,
  userId: number,
  existing: BuildRecord,
  input: UpdateBuildInput,
): Promise<BuildDetail> {
  const now = new Date().toISOString();
  const newBuildId = crypto.randomUUID();

  const synergyTypes = normalizeDesignations(input.synergyTypes ?? existing.synergyTypes);
  assertTypesPresent(synergyTypes);

  const className = input.className ?? existing.className;
  const subclass = input.subclass ?? existing.subclass;
  const exoticArmorHash =
    input.exoticArmorHash !== undefined ? input.exoticArmorHash : existing.exoticArmorHash;
  const exoticArmorName =
    input.exoticArmorName !== undefined ? input.exoticArmorName : existing.exoticArmorName;
  const exoticWeaponHash =
    input.exoticWeaponHash !== undefined ? input.exoticWeaponHash : existing.exoticWeaponHash;
  const exoticWeaponName =
    input.exoticWeaponName !== undefined ? input.exoticWeaponName : existing.exoticWeaponName;
  const pinnedSuper = input.pinnedSuper !== undefined ? input.pinnedSuper : existing.pinnedSuper;
  const tagIds = input.tagIds ? parseTags(input.tagIds) : existing.tagIds;

  let name = input.name?.trim() || existing.name;
  if (findBuildByNameClass(db, userId, className, name)) {
    name = `${name} (fork)`;
  }
  assertUniqueBuildName(db, userId, className, name);

  createBuildRecord(db, userId, {
    id: newBuildId,
    name,
    className,
    subclass,
    exoticArmorHash: exoticArmorHash ?? null,
    exoticArmorName: exoticArmorName ?? null,
    exoticWeaponHash: exoticWeaponHash ?? null,
    exoticWeaponName: exoticWeaponName ?? null,
    pinnedSuper: pinnedSuper ?? null,
    softStatTargets: existing.softStatTargets,
    tagIds,
    synergyTypes,
    now,
  });

  const variants = listVariants(db, existing.id);
  for (const variant of variants) {
    const newVariantId = crypto.randomUUID();
    createVariantRecord(db, {
      id: newVariantId,
      buildId: newBuildId,
      name: variant.name,
      isDefault: variant.isDefault,
      exoticWeaponHash: variant.exoticWeaponHash,
      exoticWeaponName: variant.exoticWeaponName,
      artifactHash: variant.artifactHash,
      artifactName: variant.artifactName,
      artifactConfig: variant.artifactConfig,
      notes: variant.notes,
      now,
    });

    const sourceAttachments = listAttachments(db, variant.id);
    if (sourceAttachments.length) {
      const prepared = await Promise.all(
        sourceAttachments.map(async (attachment) => {
          if (attachment.snapshotConfigs?.length) {
            return {
              setId: attachment.setId,
              mode: "snapshot" as const,
              snapshotConfigs: attachment.snapshotConfigs,
            };
          }
          const items = await listActiveSetItems(db, attachment.setId);
          return {
            setId: attachment.setId,
            mode: "snapshot" as const,
            snapshotConfigs: items.map((item) => ({
              slot: item.slot,
              itemHash: item.itemHash,
              itemName: item.itemName,
              selectedPerks: item.selectedPerks,
              masterworkHash: item.masterworkHash,
              modHashes: item.modHashes,
            })),
          };
        }),
      );
      replaceAttachments(db, newVariantId, prepared, now);
    }
  }

  const detail = await getBuildDetail(db, userId, newBuildId);
  if (!detail) {
    throw new ApiError(API_ERROR_CODES.INVALID_ITEM, "Forked build not found");
  }
  return Object.assign(detail, { forkedFromId: existing.id });
}

export async function updateUserBuild(
  db: AppDatabase,
  userId: number,
  buildId: string,
  input: UpdateBuildInput,
) {
  const existing = getBuild(db, userId, buildId);
  if (!existing) return null;

  if (input.synergyTypes) {
    assertTypesPresent(normalizeDesignations(input.synergyTypes));
  }
  if (input.tagIds) parseTags(input.tagIds);

  const changedIdentity = await identityFieldsChanged(existing, input);
  if (changedIdentity.length > 0) {
    if (!input.identityAction) {
      throw new ApiError(
        API_ERROR_CODES.IDENTITY_CONFIRM_REQUIRED,
        "Confirm in-place or fork to apply identity changes",
        { identityFields: changedIdentity },
        409,
      );
    }
    if (input.identityAction === "fork") {
      return forkBuildWithIdentity(db, userId, existing, input);
    }
  }

  const nextClass = input.className ?? existing.className;
  if (input.name !== undefined) {
    const trimmed = input.name.trim();
    if (trimmed) assertUniqueBuildName(db, userId, nextClass, trimmed, buildId);
  }

  const now = new Date().toISOString();
  let softStatTargets = existing.softStatTargets;
  if (input.acceptStatNudges) {
    const bridge = resolveDesignatedSynergies(db, userId, existing.synergyTypes);
    const { suggestStatNudges, targetsFromAcceptedNudges } = await import("@/lib/builds/statNudges");
    softStatTargets = targetsFromAcceptedNudges(
      softStatTargets,
      suggestStatNudges(bridge.designations, bridge.matchedSynergies),
    );
  }
  if (input.softStatTargets !== undefined) {
    softStatTargets =
      input.softStatTargets === null ? {} : normalizeSoftStatTargets(input.softStatTargets);
  }

  updateBuildRecord(db, userId, buildId, {
    name: input.name?.trim() || undefined,
    className: input.className,
    subclass: input.subclass,
    exoticArmorHash: input.exoticArmorHash,
    exoticArmorName: input.exoticArmorName,
    exoticWeaponHash: input.exoticWeaponHash,
    exoticWeaponName: input.exoticWeaponName,
    pinnedSuper: input.pinnedSuper,
    softStatTargets:
      input.softStatTargets !== undefined || input.acceptStatNudges ? softStatTargets : undefined,
    tagIds: input.tagIds,
    synergyTypes: input.synergyTypes
      ? normalizeDesignations(input.synergyTypes)
      : undefined,
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

  const existing = getVariant(db, buildId, variantId);
  if (!existing) return null;

  const now = new Date().toISOString();
  const { resolveArtifactSelection } = await import("@/lib/builds/artifactSelection");
  const artifactPatch = await resolveArtifactSelection({
    artifactHash: input.artifactHash,
    artifactName: input.artifactName,
    artifactConfig: input.artifactConfig,
    previous: {
      artifactHash: existing.artifactHash,
      artifactName: existing.artifactName,
      artifactConfig: existing.artifactConfig,
    },
  });

  updateVariantRecord(db, buildId, variantId, {
    name: input.name,
    exoticWeaponHash: input.exoticWeaponHash,
    exoticWeaponName: input.exoticWeaponName,
    notes: input.notes,
    ...(artifactPatch ?? {}),
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
  const weapon = effectiveExoticWeapon(build, variant);
  const slots = await lookupExoticSlots(weapon.exoticWeaponHash, build.exoticArmorHash);
  const resolved = await resolveVariantEquipment(db, userId, build, variant, attachments, {
    exoticWeaponSlot: slots.weaponSlot,
    exoticArmorSlot: slots.armorSlot,
  });

  assertNoSlotConflicts(resolved);
  if (variant.isDefault) {
    const hasMods = await variantHasMods(db, userId, attachments);
    assertFullCombatLoadout(resolved, build, { hasMods });
  }
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
  const weapon = effectiveExoticWeapon(build, variant);
  const slots = await lookupExoticSlots(weapon.exoticWeaponHash, build.exoticArmorHash);
  const resolved = await resolveVariantEquipment(db, userId, build, variant, attachments, {
    exoticWeaponSlot: slots.weaponSlot,
    exoticArmorSlot: slots.armorSlot,
  });
  const inventory = buildInventoryPinIndex(listInventoryItems(db, userId));
  const readiness = computeEquipReady(resolved, inventory);
  const { resolvedArtifactFromVariant, resolveFashionLayer } = await import(
    "@/lib/builds/resolveArtifactFashion"
  );
  return {
    ...resolved,
    ...readiness,
    artifact: resolvedArtifactFromVariant(variant),
    fashion: await resolveFashionLayer(db, userId, variantId, attachments),
  };
}

export type { VariantRecord, AttachmentRecord };
