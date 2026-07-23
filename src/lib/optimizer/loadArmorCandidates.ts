import { ARMOR_STAT_NAMES, type ArmorStatName } from "@/data/rules/statBenefits";
import type { AuthenticatedUser } from "@/lib/api/requireUser";
import { resolveInventoryHashProjections } from "@/lib/catalog/inventoryHashProjections";
import type { AppDatabase } from "@/lib/db/client";
import { armorEnergyCapacity } from "@/lib/builds/modEnergy";
import { loadInstanceListContext } from "@/lib/inventory/instances/loadInstanceContext";
import { listUserInstances } from "@/lib/inventory/instances/listUserInstances";
import type { OwnedInstanceDetail } from "@/lib/inventory/instances/types";
import { listActiveSetItems } from "@/lib/sets/setItemService";
import { listUserSets } from "@/lib/sets/setService";
import { getServices } from "@/lib/services";
import type { DestinyClassName } from "@/lib/manifest/types/records";

import type { ArmorSlot, CandidatePiece, ReuseSetRef } from "./types";

export type LoadArmorCandidatesParams = {
  db: AppDatabase;
  userId: number;
  auth: AuthenticatedUser;
  classType: DestinyClassName;
  /** Armor Set being optimized/refreshed; excluded from reuse annotations. */
  armorSetId?: string;
};

export type LoadArmorCandidatesResult = {
  candidates: CandidatePiece[];
  /** False when the user has never synced inventory (NO_INVENTORY). */
  hasInventory: boolean;
};

const BUCKET_TO_SLOT: Record<string, ArmorSlot> = {
  Helmet: "helmet",
  Gauntlets: "arms",
  Chest: "chest",
  Legs: "legs",
  ClassItem: "class_item",
};

function toArmorStats(
  values: Partial<Record<string, number>> | undefined,
): Partial<Record<ArmorStatName, number>> {
  const out: Partial<Record<ArmorStatName, number>> = {};
  if (!values) return out;
  for (const name of ARMOR_STAT_NAMES) {
    const value = values[name];
    if (typeof value === "number") out[name] = value;
  }
  return out;
}

/** instanceId → other Armor Sets that already use it (soft-removed items excluded). */
async function buildReuseMap(
  db: AppDatabase,
  userId: number,
  armorSetId: string | undefined,
): Promise<Map<string, ReuseSetRef[]>> {
  const armorSets = listUserSets(db, userId, { type: "armor" }).filter(
    (set) => set.id !== armorSetId,
  );
  const map = new Map<string, ReuseSetRef[]>();
  for (const set of armorSets) {
    const items = await listActiveSetItems(db, set.id);
    for (const item of items) {
      if (!item.instanceId) continue;
      const refs = map.get(item.instanceId) ?? [];
      refs.push({ id: set.id, name: set.name });
      map.set(item.instanceId, refs);
    }
  }
  return map;
}

function toCandidate(
  instance: OwnedInstanceDetail,
  slot: ArmorSlot,
  name: string | undefined,
  isExotic: boolean,
  reuseMap: Map<string, ReuseSetRef[]>,
): CandidatePiece {
  return {
    slot,
    itemHash: instance.itemHash,
    instanceId: instance.instanceId,
    ...(name ? { itemName: name } : {}),
    isExotic,
    ...(instance.setBonus?.name ? { setBonusKey: instance.setBonus.name } : {}),
    statValues: toArmorStats(instance.statValues),
    energyCapacity: armorEnergyCapacity(instance.tier?.tier ?? null),
    usedInSets: reuseMap.get(instance.instanceId) ?? [],
  };
}

export async function loadArmorCandidates(
  params: LoadArmorCandidatesParams,
): Promise<LoadArmorCandidatesResult> {
  const context = await loadInstanceListContext(params.auth, []);
  const list = listUserInstances({
    db: params.db,
    userId: params.userId,
    criteria: { kind: "armor" },
    plugMap: context.plugMap,
    characterLabels: context.characterLabels,
    membershipDisplayName: context.membershipDisplayName,
    armorMeta: context.armorMeta,
  });
  if (list.syncPrompt) return { candidates: [], hasInventory: false };

  const { manifest } = await getServices();
  const version = (await manifest.getStatus()).cachedVersion;
  const hashes = [...new Set(list.instances.map((instance) => instance.itemHash))];
  const projections = version
    ? await resolveInventoryHashProjections(manifest, version, hashes)
    : new Map();
  const reuseMap = await buildReuseMap(params.db, params.userId, params.armorSetId);

  const candidates: CandidatePiece[] = [];
  for (const instance of list.instances) {
    const projection = projections.get(instance.itemHash);
    if (projection?.classType && projection.classType !== params.classType) continue;
    const slot = BUCKET_TO_SLOT[instance.bucket];
    if (!slot) continue;
    const isExotic = context.armorMeta.get(instance.itemHash)?.isExotic ?? false;
    candidates.push(toCandidate(instance, slot, projection?.name, isExotic, reuseMap));
  }

  return { candidates, hasInventory: true };
}
