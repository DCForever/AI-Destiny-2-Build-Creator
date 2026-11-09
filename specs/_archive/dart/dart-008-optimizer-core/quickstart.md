# Quickstart: DART-008 Optimizer Core

## Run tests

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test packages/domain
# or focused:
dart test packages/domain/test/optimizer_core_test.dart
dart analyze packages/domain
```

## Minimal usage (pure)

```dart
import 'package:destiny2_domain/destiny2_domain.dart';

final pieces = <CandidatePiece>[/* five slots */];
final bySlot = groupBySlot(pieces);
final pruned = prunePiecesBySlot(bySlot, const PruneOptions(priorities: [ArmorStatName.melee]));
final result = enumerateKits(
  pruned,
  const EnumerateOptions(constraints: KitConstraints(), maxCombinations: 10_000),
);
// result.kits, result.truncated, result.evaluatedCount
final stats = estimateKitStats(result.kits.first);
```

## Branch workflow

1. Base: `feature/multiplatform-dart`
2. Feature: `dart-008-optimizer-core`
3. Merge finish-spec **only** into `feature/multiplatform-dart`
