import type { AuthenticatedUser } from "@/lib/api/requireUser";
import type { AppDatabase } from "@/lib/db/client";
import { loadInstanceListContext } from "@/lib/inventory/instances/loadInstanceContext";
import { listUserInstances } from "@/lib/inventory/instances/listUserInstances";
import type { MaterializeOwnership } from "@/lib/sets/materializeCombination";

/**
 * Build an instanceId → owned identity map for every owned armor instance
 * (all classes). Used to validate materialize/apply pieces against the user's
 * inventory (ownership + exotic count) without class filtering.
 */
export async function loadOwnedArmorOwnership(params: {
  db: AppDatabase;
  userId: number;
  auth: AuthenticatedUser;
}): Promise<MaterializeOwnership> {
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

  const byInstanceId = new Map<string, { itemHash: number; isExotic: boolean }>();
  for (const instance of list.instances) {
    byInstanceId.set(instance.instanceId, {
      itemHash: instance.itemHash,
      isExotic: context.armorMeta.get(instance.itemHash)?.isExotic ?? false,
    });
  }
  return { byInstanceId };
}
