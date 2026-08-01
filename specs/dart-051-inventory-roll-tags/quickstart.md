# Quickstart: DART-051 Inventory Roll Tags

## Pure helper

```dart
import 'package:destiny2_bungie/destiny2_bungie.dart';

final tags = computeRollTags(
  [1, 2],
  {1: 'Pugilist', 2: 'Swashbuckler'},
  weapon: const RollTagWeaponMeta(
    frame: 'Adaptive Frame',
    itemTypeName: 'Hand Cannon',
  ),
);
// contains MeleeBuildCandidate (+ ChampionBarrier from Adaptive Frame)
```

## Sync with enrichment maps

```dart
await syncUserInventory(
  db: db,
  userId: userId,
  accessToken: token,
  profileClient: profile,
  equipmentBucketLookupBuilder: ...,
  perkNameMap: {plugHash: 'Pugilist', ...},
  weaponRollMetaLookup: {
    itemHash: RollTagWeaponMeta(frame: 'Adaptive Frame', itemTypeName: 'Scout Rifle'),
  },
);
```

## Tests

```powershell
dart test packages/bungie
```

## Product parity

- Next: `src/lib/inventory/rollTags.ts` + `rollTags.test.ts`
- Dart champion frames: `destiny2_sandbox_data` `getChampionCounterForFrame`
