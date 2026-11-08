# Quickstart: DART-002 Models

## Bootstrap

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
git checkout dart-002-models   # or feature/multiplatform-dart after merge
dart pub get
```

## Run tests

```powershell
dart test packages/domain
# or
melos run test
```

## Import models

```dart
import 'package:destiny2_domain/destiny2_domain.dart';

final claim = SlotClaim(
  slot: EquipmentSlot.helmet,
  itemHash: 1,
  itemName: 'Example',
  source: ClaimSource.set,
);
```

## Purity

`packages/domain/pubspec.yaml` must keep runtime `dependencies: {}` (or pure annotations only). No Flutter/Jaspr/Drift/http.

## Scope reminder

Models only — no hard/soft evaluators in this slice (DART-003+).
