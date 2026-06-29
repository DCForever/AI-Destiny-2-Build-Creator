import type { AppDatabase } from "@/lib/db/client";
import { getBuild } from "@/lib/db/repositories/buildRepository";
import { listInventoryItems } from "@/lib/db/repositories/inventoryRepository";
import { getSet } from "@/lib/db/repositories/setRepository";
import { getSynergiesByIds } from "@/lib/db/repositories/synergyRepository";
import { listActiveSetItems } from "@/lib/sets/setItemService";
import {
  buildPerkWeaponIndex,
  loadPerkWeaponIndex,
  type PerkWeaponIndex,
} from "@/lib/manifest/perkWeaponIndex";
import type { WeaponRecord } from "@/lib/manifest/types/records";
import { getServices } from "@/lib/services";

import { mergeSynergyContext, type MergedRollContext } from "./mergeSynergyContext";
import { collectSetRollHints, suggestRolls, type RollSuggestion } from "./suggestRolls";

export type SuggestRollsInput = {
  setId?: string;
  synergyIds?: string[];
  buildId?: string;
  limit?: number;
};

export type SuggestRollsResult = {
  context: MergedRollContext;
  suggestions: RollSuggestion[];
};

async function resolvePerkIndex(): Promise<PerkWeaponIndex> {
  const { entityCache } = await getServices();
  const meta = await entityCache.getMeta();
  if (meta) {
    const loaded = await loadPerkWeaponIndex(meta.manifestVersion);
    if (loaded) return loaded;
  }
  const [weapons, exoticWeapons, weaponPerks] = await Promise.all([
    entityCache.getStore("weapons"),
    entityCache.getStore("exotic-weapons"),
    entityCache.getStore("weapon-perks"),
  ]);
  return buildPerkWeaponIndex(meta?.manifestVersion ?? "inline", {
    weapons,
    "exotic-weapons": exoticWeapons,
    "weapon-perks": weaponPerks,
  });
}

export async function suggestRollsForUser(
  db: AppDatabase,
  userId: number,
  input: SuggestRollsInput,
): Promise<SuggestRollsResult | null> {
  const build = input.buildId ? getBuild(db, userId, input.buildId) : null;
  if (input.buildId && !build) return null;

  const set = input.setId ? getSet(db, userId, input.setId) : null;
  if (input.setId && !set) return null;

  const synergyIds =
    input.synergyIds?.length ? input.synergyIds : build?.synergyIds ?? [];
  const synergies = getSynergiesByIds(db, userId, synergyIds);

  const setItems = set ? await listActiveSetItems(db, set.id) : [];
  const setHints = collectSetRollHints(setItems);

  const context = mergeSynergyContext(synergies, {
    setTagIds: set?.tagIds,
    buildTagIds: build?.tagIds,
  });

  const { entityCache } = await getServices();
  const [weapons, weaponPerks, perkIndex] = await Promise.all([
    entityCache.getStore("weapons") as Promise<WeaponRecord[]>,
    entityCache.getStore("weapon-perks"),
    resolvePerkIndex(),
  ]);

  const perkNames = new Map<number, string>(weaponPerks.map((p) => [p.hash, p.name]));
  const ownedItems = listInventoryItems(db, userId);

  const suggestions = suggestRolls({
    context,
    perkIndex,
    perkNames,
    weapons,
    setItemPerks: setHints.perkHashes,
    setWeaponHashes: setHints.weaponHashes,
    ownedItems,
    limit: input.limit,
  });

  return { context, suggestions };
}
