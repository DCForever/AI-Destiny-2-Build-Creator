# Quickstart: DART-052 Inventory Socket Enrichment

## Pure helpers

```dart
import 'package:destiny2_bungie/destiny2_bungie.dart';

final classified = classifyWeaponSocket(
  socketIndex: 0,
  equippedPlugHash: 101,
  plugCategoryByHash: {101: 'barrels.rifle'},
  weaponPerkSocketIndexes: const [0, 1, 2, 3],
);
// columnKind: barrel, columnLabel: Barrel, includeInGrid: true

final stored = buildStoredSocketPlugs(
  socketCapture: const [
    RawSocketCapture(
      socketIndex: 0,
      equippedPlugHash: 101,
      reusablePlugHashes: [101, 102],
    ),
  ],
  plugCategoryByHash: {101: 'barrels.rifle', 102: 'barrels.rifle'},
  weaponPerkSocketIndexes: const [0, 1, 2, 3],
);
// stored.first.columnKind == SocketColumnKind.barrel
```

## Sync with context builder

```dart
await syncUserInventory(
  db: db,
  userId: userId,
  accessToken: token,
  profileClient: profile,
  equipmentBucketLookupBuilder: ...,
  weaponSocketContextBuilder: (itemHash, plugHashes) async {
    return buildWeaponSocketContextFromItemDefs(
      rawItemDefs,
      itemHash,
      plugHashes,
    );
  },
);
```

## Tests

```powershell
dart test packages/bungie
```

## Product parity

- Next: `buildStoredSocketPlugs.ts`, `classifyWeaponSocket.ts`, `weaponSocketContext.ts`
- Category hash: `4241085061` (weapon perks socket category)
