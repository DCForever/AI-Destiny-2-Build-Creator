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
    // Client payload replaces the list when provided (including []).
    ignoredSynergyTypeKeys:
      client.ignoredSynergyTypeKeys !== undefined
        ? client.ignoredSynergyTypeKeys
        : (server.ignoredSynergyTypeKeys ?? DEFAULT_PREFERENCES.ignoredSynergyTypeKeys),
  });
}

/** Add coverage keys to the ignore list (deduped). */
export function addIgnoredSynergyTypeKeys(
  prefs: UserPreferences,
  keys: string[],
): UserPreferences {
  const next = new Set(prefs.ignoredSynergyTypeKeys ?? []);
  for (const k of keys) {
    const t = k.trim();
    if (t) next.add(t);
  }
  return {
    ...prefs,
    ignoredSynergyTypeKeys: [...next].sort((a, b) => a.localeCompare(b)),
  };
}

/** Remove coverage keys from the ignore list. */
export function removeIgnoredSynergyTypeKeys(
  prefs: UserPreferences,
  keys: string[],
): UserPreferences {
  const drop = new Set(keys.map((k) => k.trim()).filter(Boolean));
  return {
    ...prefs,
    ignoredSynergyTypeKeys: (prefs.ignoredSynergyTypeKeys ?? []).filter(
      (k) => !drop.has(k),
    ),
  };
}
