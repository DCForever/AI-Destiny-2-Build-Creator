// Destiny inventory bucket hashes used when parsing Bungie profile inventory.
// Product parity: `src/lib/bungie/inventoryBuckets.ts`.

const int kSubclassBucketHash = 3284755031;

/// Vault and other containers whose items need equipment-bucket resolution.
const Set<int> kTransferContainerBuckets = {
  138197802, // General (vault)
  215593132, // Postmaster
};

/// Equipment bucket hash → stored inventory label (catalog / owned filters).
const Map<int, String> kEquipmentBucketLabels = {
  1498876634: 'Kinetic',
  2465295065: 'Energy',
  953998645: 'Power',
  3448274439: 'Helmet',
  3551918588: 'Gauntlets',
  14239492: 'Chest',
  20886954: 'Legs',
  1585787867: 'ClassItem',
  kSubclassBucketHash: 'Subclass',
};

/// Labels for transfer containers (diagnostics only — resolve before storage).
const Map<int, String> kTransferContainerLabels = {
  138197802: 'VaultGeneral',
  215593132: 'Postmaster',
};

const Set<int> kWeaponBucketHashes = {
  1498876634,
  2465295065,
  953998645,
};

const Set<int> kArmorBucketHashes = {
  3448274439,
  3551918588,
  14239492,
  20886954,
  1585787867,
};

bool isEquipmentBucketHash(int bucketHash) =>
    kEquipmentBucketLabels.containsKey(bucketHash);

bool isParsableInventoryBucket(int bucketHash) =>
    isEquipmentBucketHash(bucketHash) ||
    kTransferContainerBuckets.contains(bucketHash);

bool isWeaponBucketHash(int bucketHash) =>
    kWeaponBucketHashes.contains(bucketHash);

bool isArmorBucketHash(int bucketHash) => kArmorBucketHashes.contains(bucketHash);

bool needsEquipmentBucketResolution(int bucketHash) =>
    kTransferContainerBuckets.contains(bucketHash);

String inventoryBucketLabel(int bucketHash) =>
    kEquipmentBucketLabels[bucketHash] ?? 'Unknown';

String parseBucketLabel(int bucketHash) =>
    kEquipmentBucketLabels[bucketHash] ??
    kTransferContainerLabels[bucketHash] ??
    'Unknown';
