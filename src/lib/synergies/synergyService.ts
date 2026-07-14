import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import type { AppDatabase } from "@/lib/db/client";
import { listBuilds } from "@/lib/db/repositories/buildRepository";
import {
  createSynergyRecord,
  deleteSynergyRecord,
  findSynergiesByTarget,
  getSynergiesByIds,
  getSynergiesByTypeSubType,
  getSynergy,
  listSynergies,
  updateSynergyRecord,
  type SynergyTargetQuery,
  type SynergyWithLinks,
} from "@/lib/db/repositories/synergyRepository";
import type { CreateSynergyInput, MergeSynergiesInput } from "@/lib/synergies/schemas";
import type { SynergyType } from "@/lib/synergies/schemas";
import { planDesignationConsolidations } from "@/lib/synergies/consolidateDesignations";
import { buildCountByDesignationKey } from "@/lib/synergies/countBuildsByDesignation";
import {
  generateSynergyName,
  synergyTypeDesignationKey,
} from "@/lib/synergies/generateSynergyName";
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

/** Collapse duplicate evidence targets on one library row. */
function dedupeLinksInput(
  links: CreateSynergyInput["links"],
): CreateSynergyInput["links"] {
  return unionSynergyLinks([links]);
}
import { isValidSubTypeForCategory, listSubTypeOptions } from "@/lib/synergies/subTypeVocabularies";
import { validateSynergyLinks } from "@/lib/synergies/validateSynergyLink";
import { validateSynergySubType } from "@/lib/synergies/validateSynergySubType";

/** Library list row with usage counts for UI subtitles. */
export type SynergyListItem = SynergyWithLinks & {
  buildCount: number;
  objectCount: number;
};

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

/**
 * Merge same type+subtype library rows into one (oldest survivor).
 * Safe to call on every list; no-op when already unique per designation.
 */
export async function consolidateDuplicateDesignations(
  db: AppDatabase,
  userId: number,
): Promise<{ deletedIds: string[]; survivorIds: string[] }> {
  const rows = listSynergies(db, userId);
  const plans = planDesignationConsolidations(rows);
  const deletedIds: string[] = [];
  const survivorIds: string[] = [];

  for (const plan of plans) {
    const result = await mergeUserSynergies(db, userId, {
      survivorId: plan.survivorId,
      sourceIds: plan.sourceIds,
    });
    deletedIds.push(...result.deletedIds);
    survivorIds.push(result.synergy.id);
  }

  return { deletedIds, survivorIds };
}

/** Attach buildCount / objectCount for library list subtitles. */
export function enrichSynergiesWithUsage(
  db: AppDatabase,
  userId: number,
  synergies: SynergyWithLinks[],
): SynergyListItem[] {
  const builds = listBuilds(db, userId);
  const counts = buildCountByDesignationKey(builds);
  return synergies.map((s) => {
    const key = synergyTypeDesignationKey({ type: s.type, subType: s.subType });
    return {
      ...s,
      buildCount: counts.get(key) ?? 0,
      objectCount: s.links.length,
    };
  });
}

/**
 * List library after auto-merge cleanup, with usage counts.
 * Prefer this for GET /api/user/synergies.
 */
export async function listUserSynergiesConsolidated(
  db: AppDatabase,
  userId: number,
  type?: SynergyType,
): Promise<SynergyListItem[]> {
  await consolidateDuplicateDesignations(db, userId);
  const rows = listSynergies(db, userId, type);
  return enrichSynergiesWithUsage(db, userId, rows);
}

export async function createUserSynergy(
  db: AppDatabase,
  userId: number,
  input: CreateSynergyInput,
): Promise<SynergyWithLinks> {
  const links = await validateLinksOrThrow(dedupeLinksInput(input.links));
  const resolved = await resolveSynergyFields({
    type: input.type,
    subType: input.subType,
    links,
    name: input.name,
  });

  const now = new Date().toISOString();
  const id = crypto.randomUUID();
  createSynergyRecord(db, userId, {
    id,
    name: resolved.name,
    type: resolved.type,
    subType: resolved.subType,
    description: input.description ?? "",
    links,
    now,
  });

  // Collapse same-designation forks so create cannot re-fork a type+subtype.
  await consolidateDuplicateDesignations(db, userId);

  // Always return the surviving designation row (may not be the just-created id).
  const remaining = getSynergiesByTypeSubType(
    db,
    userId,
    resolved.type,
    resolved.subType,
  );
  if (remaining[0]) return remaining[0];
  const stillThere = getSynergy(db, userId, id);
  if (stillThere) return stillThere;
  throw new ApiError(
    API_ERROR_CODES.INVALID_ITEM,
    "Synergy was created but could not be reloaded after consolidation.",
  );
}

/** Map a library row into a create payload (clone fields; new id assigned on create). */
export function createInputFromSynergy(source: {
  type: string;
  subType?: string | null;
  description?: string | null;
  links: Array<{
    kind: string;
    displayName: string;
    itemHash?: number | null;
    perkHash?: number | null;
    parentItemHash?: number | null;
    originTraitName?: string | null;
    originTraitHash?: number | null;
    armorSetName?: string | null;
    bonusPieces?: number | null;
    bonusName?: string | null;
    armorSetHash?: number | null;
  }>;
}): CreateSynergyInput {
  return {
    type: source.type as CreateSynergyInput["type"],
    subType: source.subType ?? null,
    description: source.description ?? "",
    links: source.links.map((l) => ({
      kind: l.kind as CreateSynergyInput["links"][number]["kind"],
      displayName: l.displayName,
      itemHash: l.itemHash ?? undefined,
      perkHash: l.perkHash ?? undefined,
      parentItemHash: l.parentItemHash ?? undefined,
      originTraitName: l.originTraitName ?? undefined,
      originTraitHash: l.originTraitHash ?? undefined,
      armorSetName: l.armorSetName ?? undefined,
      bonusPieces: (l.bonusPieces === 2 || l.bonusPieces === 4
        ? l.bonusPieces
        : undefined) as 2 | 4 | undefined,
      bonusName: l.bonusName ?? undefined,
      armorSetHash: l.armorSetHash ?? undefined,
    })),
  };
}

/**
 * Duplicate an existing library row into a new independent entry.
 * Source id is never mutated; returns the new row.
 */
export async function duplicateUserSynergy(
  db: AppDatabase,
  userId: number,
  sourceId: string,
): Promise<SynergyWithLinks | null> {
  const existing = getSynergy(db, userId, sourceId);
  if (!existing) return null;
  return createUserSynergy(db, userId, createInputFromSynergy(existing));
}

function normalizeSubTypeForCompare(subType: string | null | undefined): string | null {
  const t = subType?.trim() ?? "";
  return t === "" ? null : t;
}

export async function updateUserSynergy(
  db: AppDatabase,
  userId: number,
  synergyId: string,
  input: Partial<CreateSynergyInput>,
): Promise<SynergyWithLinks | null> {
  const existing = getSynergy(db, userId, synergyId);
  if (!existing) return null;

  // Designation (type + subtype) is immutable after create.
  if (input.type != null && input.type !== existing.type) {
    throw new ApiError(
      API_ERROR_CODES.INVALID_SYNERGY_TYPE,
      "Synergy type cannot be changed after create",
    );
  }
  if (input.subType !== undefined) {
    const next = normalizeSubTypeForCompare(input.subType);
    const prev = normalizeSubTypeForCompare(existing.subType);
    if (next !== prev) {
      throw new ApiError(
        API_ERROR_CODES.INVALID_SYNERGY_SUBTYPE,
        "Synergy subtype cannot be changed after create",
      );
    }
  }

  const links = input.links
    ? await validateLinksOrThrow(dedupeLinksInput(input.links))
    : undefined;
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
    type: existing.type,
    subType: existing.subType,
    links: mergedLinks,
    name: input.name,
  });

  const now = new Date().toISOString();
  return updateSynergyRecord(db, userId, synergyId, {
    name: resolved.name,
    type: existing.type,
    subType: existing.subType,
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
