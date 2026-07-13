import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import type { AppDatabase } from "@/lib/db/client";
import {
  createSynergyRecord,
  deleteSynergyRecord,
  findSynergiesByTarget,
  getSynergiesByIds,
  getSynergy,
  listSynergies,
  updateSynergyRecord,
  type SynergyTargetQuery,
  type SynergyWithLinks,
} from "@/lib/db/repositories/synergyRepository";
import type { CreateSynergyInput, MergeSynergiesInput } from "@/lib/synergies/schemas";
import type { SynergyType } from "@/lib/synergies/schemas";
import { generateSynergyName } from "@/lib/synergies/generateSynergyName";
import { normalizeLegacySynergyType } from "@/lib/synergies/legacySynergyTypes";
import {
  enrichSynergyWithLinkDescriptions,
  type SynergyWithLinkDescriptions,
} from "@/lib/synergies/enrichSynergyLinks";
import {
  mergeSynergyDescriptions,
  sameSynergyDesignation,
  unionSynergyLinks,
} from "@/lib/synergies/mergeSynergies";
import { isValidSubTypeForCategory, listSubTypeOptions } from "@/lib/synergies/subTypeVocabularies";
import { validateSynergyLinks } from "@/lib/synergies/validateSynergyLink";
import { validateSynergySubType } from "@/lib/synergies/validateSynergySubType";

async function validateLinksOrThrow(links: CreateSynergyInput["links"]) {
  try {
    return await validateSynergyLinks(links);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Invalid synergy link";
    throw new ApiError(API_ERROR_CODES.INVALID_SYNERGY_LINK, message);
  }
}

async function resolveSynergyFields(input: {
  type?: SynergyType;
  subType?: string | null;
  links: CreateSynergyInput["links"];
  name?: string;
}) {
  const normalized = normalizeLegacySynergyType(input.type ?? "melee", input.subType);
  const subTypeCheck = validateSynergySubType(normalized.type, normalized.subType);
  if (!subTypeCheck.ok) {
    throw new ApiError(API_ERROR_CODES.INVALID_SYNERGY_SUBTYPE, subTypeCheck.reason);
  }

  if (normalized.type === "weapon_archetype" && subTypeCheck.subType) {
    const options = await listSubTypeOptions(normalized.type);
    if (!isValidSubTypeForCategory(normalized.type, subTypeCheck.subType, options)) {
      throw new ApiError(
        API_ERROR_CODES.INVALID_SYNERGY_SUBTYPE,
        `Unknown ${normalized.type} subType: ${subTypeCheck.subType}`,
      );
    }
  }
  // verb: curated list OR keyword-like names validated in validateSynergySubType
  // (allows object-discovered terms such as Sliding).

  const linkDisplayName = input.links[0]?.displayName ?? "Unlinked";
  const name = generateSynergyName({
    type: normalized.type,
    subType: subTypeCheck.subType,
    linkDisplayName,
  });

  return {
    type: normalized.type,
    subType: subTypeCheck.subType,
    name,
  };
}

export function listUserSynergies(db: AppDatabase, userId: number, type?: SynergyType): SynergyWithLinks[] {
  return listSynergies(db, userId, type);
}

export async function createUserSynergy(
  db: AppDatabase,
  userId: number,
  input: CreateSynergyInput,
): Promise<SynergyWithLinks> {
  const links = await validateLinksOrThrow(input.links);
  const resolved = await resolveSynergyFields({
    type: input.type,
    subType: input.subType,
    links,
    name: input.name,
  });

  const now = new Date().toISOString();
  const id = crypto.randomUUID();
  return createSynergyRecord(db, userId, {
    id,
    name: resolved.name,
    type: resolved.type,
    subType: resolved.subType,
    description: input.description ?? "",
    links,
    now,
  });
}

export async function updateUserSynergy(
  db: AppDatabase,
  userId: number,
  synergyId: string,
  input: Partial<CreateSynergyInput>,
): Promise<SynergyWithLinks | null> {
  const existing = getSynergy(db, userId, synergyId);
  if (!existing) return null;

  const links = input.links ? await validateLinksOrThrow(input.links) : undefined;
  const mergedType = (input.type ?? existing.type) as SynergyType;
  const mergedSubType = input.subType !== undefined ? input.subType : existing.subType;
  const mergedLinks = links ?? existing.links.map((l) => ({
    kind: l.kind as CreateSynergyInput["links"][number]["kind"],
    displayName: l.displayName,
    itemHash: l.itemHash ?? undefined,
    perkHash: l.perkHash ?? undefined,
    parentItemHash: l.parentItemHash ?? undefined,
    originTraitName: l.originTraitName ?? undefined,
    originTraitHash: l.originTraitHash ?? undefined,
    armorSetName: l.armorSetName ?? undefined,
    bonusPieces: (l.bonusPieces === 2 || l.bonusPieces === 4 ? l.bonusPieces : undefined),
    bonusName: l.bonusName ?? undefined,
    armorSetHash: l.armorSetHash ?? undefined,
  }));

  const resolved = await resolveSynergyFields({
    type: mergedType,
    subType: mergedSubType,
    links: mergedLinks,
    name: input.name,
  });

  const now = new Date().toISOString();
  return updateSynergyRecord(db, userId, synergyId, {
    name: resolved.name,
    type: resolved.type,
    subType: resolved.subType,
    description: input.description,
    links,
    now,
  });
}

export function deleteUserSynergy(db: AppDatabase, userId: number, synergyId: string): boolean {
  return deleteSynergyRecord(db, userId, synergyId);
}

/**
 * Merge source library rows into a survivor of the same type + subType.
 * Unions links (deduped), joins unique descriptions, regenerates name,
 * then deletes the sources.
 */
export async function mergeUserSynergies(
  db: AppDatabase,
  userId: number,
  input: MergeSynergiesInput,
): Promise<{
  synergy: SynergyWithLinks;
  deletedIds: string[];
  linksAdded: number;
}> {
  const survivorId = input.survivorId.trim();
  const sourceIds = [
    ...new Set(input.sourceIds.map((id) => id.trim()).filter(Boolean)),
  ].filter((id) => id !== survivorId);

  if (sourceIds.length === 0) {
    throw new ApiError(
      API_ERROR_CODES.INVALID_ITEM,
      "Select at least one other synergy to merge into the survivor.",
    );
  }

  const allIds = [survivorId, ...sourceIds];
  const loaded = getSynergiesByIds(db, userId, allIds);
  const byId = new Map(loaded.map((s) => [s.id, s]));

  const survivor = byId.get(survivorId);
  if (!survivor) {
    throw new ApiError(
      API_ERROR_CODES.INVALID_ITEM,
      "Survivor synergy not found.",
      undefined,
      404,
    );
  }

  const missing = sourceIds.filter((id) => !byId.has(id));
  if (missing.length > 0) {
    throw new ApiError(
      API_ERROR_CODES.INVALID_ITEM,
      `Source synergy not found: ${missing[0]}`,
      { missingIds: missing },
      404,
    );
  }

  const sources = sourceIds.map((id) => byId.get(id)!);
  for (const src of sources) {
    if (!sameSynergyDesignation(survivor, src)) {
      throw new ApiError(
        API_ERROR_CODES.INVALID_SYNERGY_TYPE,
        `Cannot merge different designations: “${src.name}” (${src.type}${src.subType ? `: ${src.subType}` : ""}) into “${survivor.name}” (${survivor.type}${survivor.subType ? `: ${survivor.subType}` : ""}). Only rows with the same type and subtype can be merged.`,
      );
    }
  }

  const beforeCount = survivor.links.length;
  const mergedLinks = unionSynergyLinks([
    survivor.links,
    ...sources.map((s) => s.links),
  ]);
  const description = mergeSynergyDescriptions([
    survivor.description,
    ...sources.map((s) => s.description),
  ]);

  const validated = await validateLinksOrThrow(mergedLinks);
  const resolved = await resolveSynergyFields({
    type: survivor.type as SynergyType,
    subType: survivor.subType,
    links: validated,
  });

  const now = new Date().toISOString();
  const updated = updateSynergyRecord(db, userId, survivorId, {
    name: resolved.name,
    type: resolved.type,
    subType: resolved.subType,
    description,
    links: validated,
    now,
  });
  if (!updated) {
    throw new ApiError(
      API_ERROR_CODES.INVALID_ITEM,
      "Survivor synergy not found.",
      undefined,
      404,
    );
  }

  const deletedIds: string[] = [];
  for (const id of sourceIds) {
    if (deleteSynergyRecord(db, userId, id)) {
      deletedIds.push(id);
    }
  }

  return {
    synergy: updated,
    deletedIds,
    linksAdded: Math.max(0, updated.links.length - beforeCount),
  };
}

export function getUserSynergy(db: AppDatabase, userId: number, synergyId: string) {
  return getSynergy(db, userId, synergyId);
}

/** Detail payload with catalog descriptions for each linked object. */
export async function getUserSynergyDetail(
  db: AppDatabase,
  userId: number,
  synergyId: string,
): Promise<SynergyWithLinkDescriptions | null> {
  const synergy = getSynergy(db, userId, synergyId);
  if (!synergy) return null;
  return enrichSynergyWithLinkDescriptions(synergy);
}

/** Attach link descriptions after create/update/merge for the detail UI. */
export async function withLinkDescriptions(
  synergy: SynergyWithLinks,
): Promise<SynergyWithLinkDescriptions> {
  return enrichSynergyWithLinkDescriptions(synergy);
}

export function reverseLookupSynergies(
  db: AppDatabase,
  userId: number,
  query: SynergyTargetQuery,
): SynergyWithLinks[] {
  return findSynergiesByTarget(db, userId, query);
}
