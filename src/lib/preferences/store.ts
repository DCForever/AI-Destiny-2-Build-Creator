import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";

import { userPreferencesPath } from "@/lib/manifest/cachePaths";
import {
  DEFAULT_PREFERENCES,
  userPreferencesSchema,
  type UserPreferences,
} from "./types";

function isNotFound(err: unknown): boolean {
  return typeof err === "object" && err !== null && (err as NodeJS.ErrnoException).code === "ENOENT";
}

export async function readUserPreferences(
  bungieMembershipId: string,
): Promise<UserPreferences> {
  try {
    const text = await readFile(userPreferencesPath(bungieMembershipId), "utf8");
    return userPreferencesSchema.parse(JSON.parse(text));
  } catch (err) {
    if (isNotFound(err)) return { ...DEFAULT_PREFERENCES };
    throw err;
  }
}

export async function writeUserPreferences(
  bungieMembershipId: string,
  prefs: UserPreferences,
): Promise<void> {
  const filePath = userPreferencesPath(bungieMembershipId);
  await mkdir(path.dirname(filePath), { recursive: true });
  const parsed = userPreferencesSchema.parse(prefs);
  await writeFile(filePath, JSON.stringify(parsed, null, 2), "utf8");
}

export function mergePreferences(
  server: UserPreferences,
  client: UserPreferences,
): UserPreferences {
  return userPreferencesSchema.parse({
    ...DEFAULT_PREFERENCES,
    ...server,
    ...client,
    weaponTypeFilters: {
      ...DEFAULT_PREFERENCES.weaponTypeFilters,
      ...server.weaponTypeFilters,
      ...client.weaponTypeFilters,
    },
  });
}
