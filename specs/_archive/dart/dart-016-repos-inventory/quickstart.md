# Quickstart: DART-016 inventory repos

```dart
import 'package:destiny2_db/destiny2_db.dart';

final db = AppDatabase.memory();
final userId = await insertUser(
  db,
  bungieMembershipId: 'm1',
  membershipType: 3,
);
const now = '2026-07-24T00:00:00.000Z';

await replaceInventoryBatchExclusive(
  db,
  userId,
  items: [
    InventoryItemRecord(
      instanceId: 'inst-1',
      itemHash: 42,
      bucket: 'kinetic',
      location: 'vault',
      power: 1800,
      plugHashes: const [1, 2],
      rollTags: const ['Crafted'],
      syncedAt: now,
    ),
  ],
  now: now,
);

final status = await getInventoryStatus(db, userId);
// status.itemCount == 1, status.syncVersion == 1

final listed = await listInventoryItems(db, userId);
```

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test packages/db
```
