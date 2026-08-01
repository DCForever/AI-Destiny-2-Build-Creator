/**
 * Server: DBR-SUB-004 illegal subclass kits cannot save.
 */

import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import {
  evaluateSubclassKit,
  MAX_SUBCLASS_ASPECTS,
} from "@/lib/builds/destinyBuildConstraints";
import { getServices } from "@/lib/services";

export type SubclassKitInput = {
  aspects?: string[] | null;
  fragments?: string[] | null;
  super?: string | null;
  melee?: string | null;
  grenade?: string | null;
  classAbility?: string | null;
  name?: string | null;
};

export async function resolveFragmentCapacity(
  aspectNames: string[],
): Promise<{ capacity: number; resolvedCount: number }> {
  if (aspectNames.length === 0) {
    return { capacity: 0, resolvedCount: 0 };
  }
  const { entityCache } = await getServices();
  const aspects = await entityCache.getStore("aspects");
  const byName = new Map(
    aspects.map((a) => [a.name.trim().toLowerCase(), a] as const),
  );

  let capacity = 0;
  let resolvedCount = 0;
  for (const name of aspectNames) {
    const rec = byName.get(name.trim().toLowerCase());
    if (rec) {
      capacity += rec.fragmentCapacity;
      resolvedCount += 1;
    }
  }
  return { capacity, resolvedCount };
}

export async function assertSubclassKitLegal(
  subclass: SubclassKitInput,
): Promise<void> {
  const aspectNames = (subclass.aspects ?? []).filter(
    (a) => typeof a === "string" && a.trim().length > 0,
  );
  const fragmentNames = (subclass.fragments ?? []).filter(
    (f) => typeof f === "string" && f.trim().length > 0,
  );

  const { capacity, resolvedCount } = await resolveFragmentCapacity(aspectNames);
  const capacityResolved =
    aspectNames.length === 0 || resolvedCount === aspectNames.length;

  const { hardBlocks } = evaluateSubclassKit({
    aspectCount: aspectNames.length,
    fragmentCount: fragmentNames.length,
    fragmentCapacity: capacity,
    maxAspects: MAX_SUBCLASS_ASPECTS,
    capacityResolved,
  });

  if (hardBlocks.length === 0) return;
  throw new ApiError(
    API_ERROR_CODES.ILLEGAL_SUBCLASS_KIT,
    hardBlocks.map((b) => b.message).join("; "),
    { hardBlocks, fragmentCapacity: capacity, aspectCount: aspectNames.length },
    400,
  );
}
