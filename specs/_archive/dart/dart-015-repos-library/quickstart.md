# Quickstart: DART-015 library repos

```dart
import 'package:destiny2_db/destiny2_db.dart';

final db = AppDatabase.memory();
final userId = await insertUser(db, bungieMembershipId: 'm1', membershipType: 3);
final now = '2026-07-24T00:00:00Z';

await createBuildRecord(db, userId, CreateBuildInput(
  id: 'b1',
  name: 'Strand Titan',
  className: 'Titan',
  subclass: '{}',
  now: now,
));

await createSetRecord(db, userId, CreateSetInput(
  id: 's1', name: 'Weapons', type: 'weapon', tagIds: [], now: now,
));

// RESTRICT: attach then deleteSet throws SetInUseException
```

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test packages/db
```
