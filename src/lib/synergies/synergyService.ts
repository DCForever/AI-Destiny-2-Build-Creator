import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import type { AppDatabase } from "@/lib/db/client";
import {
  createSynergyRecord,
  deleteSynergyRecord,
  findSynergiesByTarget,
  getSynergy,
  listSynergies,
  updateSynergyRecord,
  type SynergyTargetQuery,
  type SynergyWithLinks,
} from "@/lib/db/repositories/synergyRepository";
import type { CreateSynergyInput } from "@/lib/synergies/schemas";
import type { SynergyType } from "@/lib/synergies/schemas";
import { generateSynergyName } from "@/lib/synergies/generateSynergyName";
import { normalizeLegacySynergyType } from "@/lib/synergies/legacySynergyTypes";
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
    const options = await listSubTypeOptions("weapon_archetype");
    if (!isValidSubTypeForCategory("weapon_archetype", subTypeCheck.subType, options)) {
      throw new ApiError(
        API_ERROR_CODES.INVALID_SYNERGY_SUBTYPE,
        `Unknown weapon archetype subType: ${subTypeCheck.subType}`,
      );
    }
  }

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

export function getUserSynergy(db: AppDatabase, userId: number, synergyId: string) {
  return getSynergy(db, userId, synergyId);
}

export function reverseLookupSynergies(
  db: AppDatabase,
  userId: number,
  query: SynergyTargetQuery,
): SynergyWithLinks[] {
  return findSynergiesByTarget(db, userId, query);
}
