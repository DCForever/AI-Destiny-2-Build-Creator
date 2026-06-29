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
import { validateSynergyLinks } from "@/lib/synergies/validateSynergyLink";

async function validateLinksOrThrow(links: CreateSynergyInput["links"]) {
  try {
    return await validateSynergyLinks(links);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Invalid synergy link";
    throw new ApiError(API_ERROR_CODES.INVALID_SYNERGY_LINK, message);
  }
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
  const now = new Date().toISOString();
  const id = crypto.randomUUID();
  return createSynergyRecord(db, userId, {
    id,
    name: input.name,
    type: input.type,
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
  const links = input.links ? await validateLinksOrThrow(input.links) : undefined;
  const now = new Date().toISOString();
  return updateSynergyRecord(db, userId, synergyId, {
    name: input.name,
    type: input.type,
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
