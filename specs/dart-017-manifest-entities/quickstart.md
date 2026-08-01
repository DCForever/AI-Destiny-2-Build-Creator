# Quickstart: DART-017 Manifest Entities

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart pub get
dart test packages/manifest
```

## Usage sketch

```dart
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';

final root = StorageRoot(basePath: appSupportPath);
await root.ensureLayout();

// Offline read of prebuilt entities
final cache = FileEntityCache(
  storageRoot: root,
  version: '1.0.0',
);
final aspects = await cache.getStore(MvpStoreName.aspects);

// Or rebuild from raw tables (no network)
await cache.rebuild(
  version: '1.0.0',
  loadRawTable: (name) async => myRawTables[name]!,
);

// Hard constraints adapters
final eval = await evaluateSubclassKitFromEntityCache(
  cache: cache,
  aspectNames: ['Touch of Thunder'],
  fragmentNames: ['Spark of Brilliance', 'Echo of Undermining'],
);
```

## Notes

- Do not use repo `.cache` as StorageRoot base (Next legacy).
- Manifest **download** is DART-018; this package only extracts/reads.
