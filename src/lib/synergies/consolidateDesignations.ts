import { synergyTypeDesignationKey } from "@/lib/synergies/generateSynergyName";

export type ConsolidatableSynergy = {
  id: string;
  type: string;
  subType: string | null;
  createdAt?: string;
};

export type DesignationMergeGroup = {
  key: string;
  survivorId: string;
  sourceIds: string[];
};

/**
 * Pick survivor for auto-merge: earliest createdAt, then lowest id (stable).
 */
export function pickMergeSurvivor<T extends ConsolidatableSynergy>(
  rows: T[],
): T {
  if (rows.length === 0) {
    throw new Error("pickMergeSurvivor requires at least one row");
  }
  return [...rows].sort((a, b) => {
    const ca = a.createdAt ?? "";
    const cb = b.createdAt ?? "";
    if (ca !== cb) return ca.localeCompare(cb);
    return a.id.localeCompare(b.id);
  })[0]!;
}

/**
 * Group library rows by designation; return merge plans for groups with 2+.
 */
export function planDesignationConsolidations<T extends ConsolidatableSynergy>(
  rows: T[],
): DesignationMergeGroup[] {
  const byKey = new Map<string, T[]>();
  for (const row of rows) {
    const key = synergyTypeDesignationKey({
      type: row.type,
      subType: row.subType,
    });
    const list = byKey.get(key) ?? [];
    list.push(row);
    byKey.set(key, list);
  }

  const plans: DesignationMergeGroup[] = [];
  for (const [key, group] of byKey) {
    if (group.length < 2) continue;
    const survivor = pickMergeSurvivor(group);
    const sourceIds = group
      .filter((r) => r.id !== survivor.id)
      .map((r) => r.id);
    plans.push({ key, survivorId: survivor.id, sourceIds });
  }
  return plans;
}
