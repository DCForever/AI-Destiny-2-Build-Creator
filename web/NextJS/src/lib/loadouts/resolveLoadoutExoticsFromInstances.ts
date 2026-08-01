/**
 * Resolve exotic armor/weapon hashes for a Bungie loadout from instance IDs
 * + synced inventory (itemHash) + exotic catalog sets.
 */

export type LoadoutExoticResolution = {
  exoticArmorHash: number | null;
  exoticWeaponHash: number | null;
  exoticArmorName: string | null;
  exoticWeaponName: string | null;
};

export type ExoticCatalogIndex = {
  armorHashes: ReadonlySet<number>;
  weaponHashes: ReadonlySet<number>;
  armorNames: ReadonlyMap<number, string>;
  weaponNames: ReadonlyMap<number, string>;
};

export function buildExoticCatalogIndex(
  exoticArmor: ReadonlyArray<{ hash: number; name: string }>,
  exoticWeapons: ReadonlyArray<{ hash: number; name: string }>,
): ExoticCatalogIndex {
  return {
    armorHashes: new Set(exoticArmor.map((a) => a.hash)),
    weaponHashes: new Set(exoticWeapons.map((w) => w.hash)),
    armorNames: new Map(exoticArmor.map((a) => [a.hash, a.name])),
    weaponNames: new Map(exoticWeapons.map((w) => [w.hash, w.name])),
  };
}

/**
 * Map loadout item instance IDs → exotic identity using inventory hashes.
 * First exotic armor and first exotic weapon win (Destiny equips one each).
 */
export function resolveLoadoutExoticsFromInstances(
  itemInstanceIds: readonly string[],
  instanceIdToHash: ReadonlyMap<string, number>,
  catalog: ExoticCatalogIndex,
): LoadoutExoticResolution {
  let exoticArmorHash: number | null = null;
  let exoticWeaponHash: number | null = null;

  for (const instanceId of itemInstanceIds) {
    if (!instanceId || instanceId === "0") continue;
    const hash = instanceIdToHash.get(instanceId);
    if (hash == null) continue;

    if (exoticArmorHash == null && catalog.armorHashes.has(hash)) {
      exoticArmorHash = hash;
    } else if (exoticWeaponHash == null && catalog.weaponHashes.has(hash)) {
      exoticWeaponHash = hash;
    }

    if (exoticArmorHash != null && exoticWeaponHash != null) break;
  }

  return {
    exoticArmorHash,
    exoticWeaponHash,
    exoticArmorName:
      exoticArmorHash != null
        ? (catalog.armorNames.get(exoticArmorHash) ?? null)
        : null,
    exoticWeaponName:
      exoticWeaponHash != null
        ? (catalog.weaponNames.get(exoticWeaponHash) ?? null)
        : null,
  };
}

/** Build instanceId → itemHash from inventory rows. */
export function instanceHashMapFromInventory(
  items: ReadonlyArray<{ instanceId: string; itemHash: number }>,
): Map<string, number> {
  const map = new Map<string, number>();
  for (const item of items) {
    if (item.instanceId) map.set(item.instanceId, item.itemHash);
  }
  return map;
}
