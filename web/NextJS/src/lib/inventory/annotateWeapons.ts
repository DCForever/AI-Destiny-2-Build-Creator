import type { ResolvedWeapon } from "@/lib/build/types";
import type { AppDatabase } from "@/lib/db/client";
import { queryInventoryByHashes } from "@/lib/db/repositories/inventoryRepository";
import type { ItemResolver } from "@/lib/manifest/types/services";

async function resolvePerkHashes(
  resolver: ItemResolver,
  perkNames: string[],
): Promise<number[]> {
  const hashes: number[] = [];
  for (const name of perkNames) {
    const resolved = await resolver.resolve("weapon-perks", name);
    if (resolved) hashes.push(resolved.record.hash);
  }
  return hashes;
}

function instanceMatchesPerks(
  plugHashes: number[],
  requiredHashes: number[],
): boolean {
  if (requiredHashes.length === 0) return true;
  const owned = new Set(plugHashes);
  return requiredHashes.every((hash) => owned.has(hash));
}

/**
 * Annotates resolved weapons with owned status and roll tags from synced inventory.
 */
export async function annotateWeaponsWithInventory(
  weapons: ResolvedWeapon[],
  db: AppDatabase,
  userId: number,
  resolver: ItemResolver,
): Promise<ResolvedWeapon[]> {
  const weaponHashes = weapons
    .map((w) => w.reference.resolved?.hash)
    .filter((hash): hash is number => hash !== undefined);

  if (weaponHashes.length === 0) return weapons;

  const ownedItems = queryInventoryByHashes(db, userId, weaponHashes);

  return Promise.all(
    weapons.map(async (weapon) => {
      const hash = weapon.reference.resolved?.hash;
      if (!hash) return weapon;

      const candidates = ownedItems.filter((item) => item.itemHash === hash);
      if (candidates.length === 0) {
        return { ...weapon, owned: false };
      }

      const requestedPerkNames = weapon.perks
        .map((p) => p.resolved?.name ?? p.requestedName)
        .filter(Boolean);
      const requiredHashes = await resolvePerkHashes(resolver, requestedPerkNames);

      const matching = candidates.find((item) =>
        instanceMatchesPerks(item.plugHashes, requiredHashes),
      );
      const best = matching ?? candidates[0];

      return {
        ...weapon,
        owned: Boolean(matching ?? candidates.length > 0),
        matchingInstanceId: matching?.instanceId ?? best?.instanceId,
        rollTags: best?.rollTags ?? [],
      };
    }),
  );
}
