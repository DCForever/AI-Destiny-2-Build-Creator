import type { BungieAuthClient, BungieProfileClient } from "@/lib/bungie/types";
import {
  parseCharacterLoadoutsResponse,
  presentationTablesFromRaw,
  type BungieInGameLoadout,
} from "@/lib/bungie/characterLoadouts";
import type { ManifestService } from "@/lib/manifest/types/services";

/**
 * Ensure loadout presentation tables are on disk (downloads only if missing).
 * Safe after a normal ensureCurrent once RAW_TABLES includes these defs.
 */
export async function ensureLoadoutPresentationTables(
  manifest: ManifestService,
): Promise<string> {
  return manifest.ensureCurrent();
}

export async function loadLoadoutPresentationTables(
  manifest: ManifestService,
  version: string,
): Promise<ReturnType<typeof presentationTablesFromRaw>> {
  const [icons, colors, names] = await Promise.all([
    manifest.loadRawTable(version, "DestinyLoadoutIconDefinition"),
    manifest.loadRawTable(version, "DestinyLoadoutColorDefinition"),
    manifest.loadRawTable(version, "DestinyLoadoutNameDefinition"),
  ]);
  return presentationTablesFromRaw({
    icons: icons as Record<string, unknown>,
    colors: colors as Record<string, unknown>,
    names: names as Record<string, unknown>,
  });
}

/**
 * Fetch Bungie in-game loadouts for the signed-in membership and resolve
 * icon / color / name the same way DIM does (component 206 + manifest tables).
 */
export async function fetchInGameLoadouts(input: {
  accessToken: string;
  profileClient: BungieProfileClient;
  manifest: ManifestService;
}): Promise<{
  membershipDisplayName: string;
  loadouts: BungieInGameLoadout[];
  manifestVersion: string;
}> {
  const version = await ensureLoadoutPresentationTables(input.manifest);
  const tables = await loadLoadoutPresentationTables(input.manifest, version);

  const memberships = await input.profileClient.getMemberships(input.accessToken);
  const membership = memberships[0];
  if (!membership) {
    return {
      membershipDisplayName: "",
      loadouts: [],
      manifestVersion: version,
    };
  }

  const profile = await input.profileClient.getCharacterLoadoutsProfile(
    input.accessToken,
    membership,
  );
  const characters = await input.profileClient.getCharacters(
    input.accessToken,
    membership,
  );

  // Prefer characters from the same profile payload when present
  const loadouts = parseCharacterLoadoutsResponse(profile, characters, tables);

  return {
    membershipDisplayName: membership.displayName,
    loadouts,
    manifestVersion: version,
  };
}

/** Test helper: auth client type unused but keeps signature room for token refresh. */
export type FetchInGameLoadoutsAuth = BungieAuthClient;
