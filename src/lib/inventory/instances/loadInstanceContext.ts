import type { AuthenticatedUser } from "@/lib/auth/requireUser";
import { createBungieProfileClient } from "@/lib/bungie/profile";
import type { EntityCache } from "@/lib/manifest/types/services";
import type { ManifestService } from "@/lib/manifest/types/services";
import { getServices } from "@/lib/services";

import { buildSetBonusByItemHash, lookupSetBonus } from "./armorSetBonus";
import { resolvePlugNamesFromManifest } from "./plugNamesFromManifest";
import { buildCharacterLabelMap } from "./resolveCharacterLabels";
import { buildPlugNameMap, mergeManifestPlugNames } from "./resolvePlugs";
import type { ArmorInstanceMeta, CharacterLabel } from "./types";

export interface InstanceListContext {
  plugMap: Map<number, string>;
  characterLabels?: Map<string, CharacterLabel>;
  membershipDisplayName: string;
  armorMeta: Map<number, ArmorInstanceMeta>;
}

/**
 * Build a per-`itemHash` armor-metadata lookup (isExotic + 2pc/4pc set bonus)
 * so projection can resolve Tier and Set Bonus without any manifest reads.
 */
export async function buildArmorInstanceMeta(
  entityCache: EntityCache,
): Promise<Map<number, ArmorInstanceMeta>> {
  const [setBonuses, exoticArmor] = await Promise.all([
    entityCache.getStore("set-bonuses"),
    entityCache.getStore("exotic-armor"),
  ]);

  const setBonusByItemHash = buildSetBonusByItemHash(setBonuses);
  const meta = new Map<number, ArmorInstanceMeta>();

  for (const itemHash of setBonusByItemHash.keys()) {
    meta.set(itemHash, { isExotic: false, setBonus: lookupSetBonus(setBonusByItemHash, itemHash) });
  }
  for (const piece of exoticArmor) {
    const existing = meta.get(piece.hash);
    meta.set(piece.hash, { isExotic: true, setBonus: existing?.setBonus ?? null });
  }

  return meta;
}

export async function buildPlugMapForInventory(
  entityCache: EntityCache,
  manifest: ManifestService,
  manifestVersion: string | null | undefined,
  plugHashes: number[],
): Promise<Map<number, string>> {
  const [weaponPerks, mods, originTraits] = await Promise.all([
    entityCache.getStore("weapon-perks"),
    entityCache.getStore("mods"),
    entityCache.getStore("origin-traits"),
  ]);

  const entityMap = buildPlugNameMap({
    "weapon-perks": weaponPerks,
    mods,
    "origin-traits": originTraits,
  });

  const unresolved = [...new Set(plugHashes)].filter((hash) => !entityMap.has(hash));
  if (unresolved.length === 0 || !manifestVersion) {
    return entityMap;
  }

  const manifestMap = await resolvePlugNamesFromManifest(manifest, manifestVersion, unresolved);
  return mergeManifestPlugNames(entityMap, manifestMap);
}

export async function loadInstanceListContext(
  auth: AuthenticatedUser,
  plugHashes: number[] = [],
): Promise<InstanceListContext> {
  const { entityCache, manifest } = await getServices();
  const manifestStatus = await manifest.getStatus();
  const [plugMap, armorMeta] = await Promise.all([
    buildPlugMapForInventory(entityCache, manifest, manifestStatus.cachedVersion, plugHashes),
    buildArmorInstanceMeta(entityCache),
  ]);

  let membershipDisplayName = auth.user.displayName || "Guardian";
  let characterLabels: Map<string, CharacterLabel> | undefined;

  const profileClient = createBungieProfileClient();
  if (profileClient) {
    try {
      const memberships = await profileClient.getMemberships(auth.tokens.accessToken);
      const membership = memberships[0];
      if (membership) {
        membershipDisplayName = membership.displayName.trim() || membershipDisplayName;
        const characters = await profileClient.getCharacters(auth.tokens.accessToken, membership);
        characterLabels = buildCharacterLabelMap(characters, membershipDisplayName);
      }
    } catch {
      // Degrade to DB display name when roster lookup fails.
    }
  }

  return { plugMap, characterLabels, membershipDisplayName, armorMeta };
}
