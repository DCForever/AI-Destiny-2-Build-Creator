# Quickstart: DART-024 Bungie Profile Sync

## Prerequisites

- Dart SDK ^3.5
- Workspace on branch `dart-024-bungie-profile-sync` (or merged base)

## Run tests

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart pub get
dart test packages/bungie
```

## Host usage (conceptual)

```dart
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';

final http = BungieHttpClient(apiKey: publicApiKey);
final profile = BungieProfileClient(http: http);
final db = AppDatabase.memory(); // or file from StorageRoot

final result = await syncUserInventory(
  db: db,
  userId: userId,
  accessToken: tokens.accessToken,
  profileClient: profile,
  // optional: equipmentBucketLookup: hash -> equipment bucketHash
);

if (isInventoryFresh(result.lastFullSyncAt)) {
  // reuse
}

final stale = await syncIfStale(
  db: db,
  userId: userId,
  accessToken: tokens.accessToken,
  profileClient: profile,
);
```

## Notes

- No CLIENT_SECRET; public API key + user access token only.
- Settings inventory sync card is DART-025.
- Soft guidance never auto-applies.
)
