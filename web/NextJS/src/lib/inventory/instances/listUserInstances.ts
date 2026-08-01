import type { AppDatabase } from "@/lib/db/client";
import {
  getInventoryStatus,
  listInventoryItems,
} from "@/lib/db/repositories/inventoryRepository";

import {
  filterInventoryItems,
  filterProjectedByPerkQuery,
  hasActiveFilter,
} from "./filterInstances";
import { isEquipmentBucket, projectInstance } from "./projectInstance";
import type { PlugLookup } from "./resolvePlugs";
import { sortInstances } from "./sortInstances";
import type {
  ArmorInstanceMeta,
  CharacterLabel,
  InstanceFilterCriteria,
  ListInstancesResult,
} from "./types";

export interface ListUserInstancesInput {
  db: AppDatabase;
  userId: number;
  criteria: InstanceFilterCriteria;
  plugMap: PlugLookup;
  characterLabels?: Map<string, CharacterLabel>;
  membershipDisplayName?: string;
  armorMeta?: Map<number, ArmorInstanceMeta>;
  itemIdentity?: {
    itemSearchName: string | null;
    inventorySearchNames: Map<number, string>;
  };
}

const SYNC_MESSAGE = "Sync inventory to see owned copies";

export function listUserInstances(input: ListUserInstancesInput): ListInstancesResult {
  const status = getInventoryStatus(input.db, input.userId);
  const syncPrompt = !status || status.itemCount === 0;

  if (syncPrompt) {
    return {
      instances: [],
      count: 0,
      syncPrompt: true,
      message: SYNC_MESSAGE,
      filter: hasActiveFilter(input.criteria) ? input.criteria : undefined,
    };
  }

  const equipment = listInventoryItems(input.db, input.userId).filter((item) =>
    isEquipmentBucket(item.bucket),
  );

  const matched = filterInventoryItems(equipment, input.criteria, input.itemIdentity);
  let instances = matched.map((item) =>
    projectInstance(
      item,
      input.plugMap,
      input.characterLabels,
      input.membershipDisplayName,
      input.armorMeta,
    ),
  );

  if (input.criteria.q) {
    instances = filterProjectedByPerkQuery(instances, input.criteria.q);
  }

  const armorSortBy =
    input.criteria.sortBy &&
    (input.criteria.kind === "armor" || instances.every((row) => row.kind === "armor"))
      ? input.criteria.sortBy
      : undefined;
  instances = sortInstances(instances, armorSortBy);

  return {
    instances,
    count: instances.length,
    syncPrompt: false,
    filter: hasActiveFilter(input.criteria) ? input.criteria : undefined,
  };
}

export function getUserInstanceById(
  input: ListUserInstancesInput & { instanceId: string },
): ListInstancesResult & { instance?: ListInstancesResult["instances"][number] } {
  const list = listUserInstances(input);
  if (list.syncPrompt) return list;

  const instance = list.instances.find((row) => row.instanceId === input.instanceId);
  if (!instance) {
    return { ...list, instances: [], count: 0, instance: undefined };
  }

  return { ...list, instances: [instance], count: 1, instance };
}
