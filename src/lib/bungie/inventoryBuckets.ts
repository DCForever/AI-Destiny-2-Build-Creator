/** Destiny inventory bucket hashes used when parsing Bungie profile inventory. */

export const SUBCLASS_BUCKET_HASH = 3284755031;

/** Vault and other containers whose items need manifest bucket resolution. */
export const TRANSFER_CONTAINER_BUCKETS = new Set<number>([
  138197802, // General (vault)
  215593132, // Postmaster
]);

export const EQUIPMENT_BUCKET_LABELS: Record<number, string> = {
  1498876634: "Kinetic",
  2465295065: "Energy",
  953998645: "Power",
  3448274439: "Helmet",
  3551918588: "Gauntlets",
  14239492: "Chest",
  20886954: "Legs",
  1585787867: "ClassItem",
  3284755031: "Subclass",
};

/** Labels for transfer containers (diagnostics only — resolved before storage). */
export const TRANSFER_CONTAINER_LABELS: Record<number, string> = {
  138197802: "VaultGeneral",
  215593132: "Postmaster",
};

/** Equipment bucket display labels for loadout text import. */
export const EQUIPMENT_BUCKET_DISPLAY_LABELS: Record<number, string> = {
  1498876634: "Kinetic Weapons",
  2465295065: "Energy Weapons",
  953998645: "Power Weapons",
  3448274439: "Helmet",
  3551918588: "Gauntlets",
  14239492: "Chest Armor",
  20886954: "Leg Armor",
  1585787867: "Class Armor",
  3284755031: "Subclass",
};

export function isEquipmentBucketHash(bucketHash: number): boolean {
  return bucketHash in EQUIPMENT_BUCKET_LABELS;
}

export function isParsableInventoryBucket(bucketHash: number): boolean {
  return isEquipmentBucketHash(bucketHash) || TRANSFER_CONTAINER_BUCKETS.has(bucketHash);
}

export function inventoryBucketLabel(bucketHash: number): string {
  return EQUIPMENT_BUCKET_LABELS[bucketHash] ?? "Unknown";
}

export function parseBucketLabel(bucketHash: number): string {
  return (
    EQUIPMENT_BUCKET_LABELS[bucketHash] ??
    TRANSFER_CONTAINER_LABELS[bucketHash] ??
    "Unknown"
  );
}
