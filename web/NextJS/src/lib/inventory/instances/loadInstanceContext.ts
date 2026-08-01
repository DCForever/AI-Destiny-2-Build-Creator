import type { AuthenticatedUser } from "@/lib/auth/requireUser";
import { createBungieProfileClient } from "@/lib/bungie/profile";
import type { EntityCache, ManifestService } from "@/lib/manifest/types/services";
import type { EntityStores } from "@/lib/manifest/types/stores";
import { getServices } from "@/lib/services";

import { buildSetBonusByItemHash, lookupSetBonus } from "./armorSetBonus";
import { resolvePlugPresentationsFromManifest } from "./plugNamesFromManifest";
import { buildCharacterLabelMap } from "./resolveCharacterLabels";
import {
  buildPlugPresentationMap,
  mergeManifestPlugPresentation,
  type PlugPresentation,
} from "./resolvePlugs";
import type { ArmorInstanceMeta, CharacterLabel } from "./types";

export interface InstanceListContext {
  plugMap: Map<number, PlugPresentation>;
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

/** Cache full entity→presentation map while store array refs are stable. */
const entityPlugMapByStores = new WeakMap<object, Map<number, PlugPresentation>>();

function entityPlugPresentationMap(
  weaponPerks: EntityStores["weapon-perks"],
  mods: EntityStores["mods"],
  originTraits: EntityStores["origin-traits"],
): Map<number, PlugPresentation> {
  const key = weaponPerks as object;
  const hit = entityPlugMapByStores.get(key);
  if (hit) return hit;
  const map = buildPlugPresentationMap({
    "weapon-perks": weaponPerks,
    mods,
    "origin-traits": originTraits,
  });
  entityPlugMapByStores.set(key, map);
  return map;
}

function scopePlugMap(
  entityMap: Map<number, PlugPresentation>,
  plugHashes: number[],
): Map<number, PlugPresentation> {
  if (plugHashes.length === 0) return new Map(entityMap);
  const scoped = new Map<number, PlugPresentation>();
  for (const hash of new Set(plugHashes)) {
    const p = entityMap.get(hash);
    if (p) scoped.set(hash, p);
  }
  return scoped;
}

export async function buildPlugMapForInventory(
  entityCache: EntityCache,
  manifest: ManifestService,
  manifestVersion: string | null | undefined,
  plugHashes: number[],
): Promise<Map<number, PlugPresentation>> {
  const [weaponPerks, mods, originTraits] = await Promise.all([
    entityCache.getStore("weapon-perks"),
    entityCache.getStore("mods"),
    entityCache.getStore("origin-traits"),
  ]);

  const entityMap = entityPlugPresentationMap(weaponPerks, mods, originTraits);

  // Fill missing hashes, icons, and descriptions from raw inventory defs
  // (barrels/mags/frames often absent from compact weapon-perks store).
  const uniqueHashes = [...new Set(plugHashes)];
  const needManifest = uniqueHashes.filter((hash) => {
    const p = entityMap.get(hash);
    return !p || !p.icon || !p.description;
  });
  if (needManifest.length === 0 || !manifestVersion) {
    return scopePlugMap(entityMap, uniqueHashes);
  }

  const manifestMap = await resolvePlugPresentationsFromManifest(
    manifest,
    manifestVersion,
    needManifest,
  );
  return mergeManifestPlugPresentation(
    scopePlugMap(entityMap, uniqueHashes),
    manifestMap,
  );
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
