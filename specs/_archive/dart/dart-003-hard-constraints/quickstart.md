# Quickstart: DART-003 Hard Constraints

## Run tests

```powershell
Set-Location F:\Destiny2BuildCreator-multiplatform-dart
dart test packages/domain
# or
melos run test
```

## Import

```dart
import 'package:destiny2_domain/destiny2_domain.dart';

final exotic = evaluateExoticLimits(const ExoticComposition(
  exoticWeaponHashes: [1, 2],
  exoticArmorHashes: [],
));
assert(exotic.isHardBlocked);
assert(exotic.hardBlocks.first.code == DomainFailureCodes.tooManyExotics);

final kit = evaluateSubclassKit(const SubclassKitEvalInput(
  aspectCount: 2,
  fragmentCount: 99,
  fragmentCapacity: 0,
  capacityResolved: false, // skip fragment hard block
));
assert(!kit.isHardBlocked);
```

## capacityResolved (caller contract)

1. Resolve aspect names → sum `fragmentCapacity` from entity data when possible.
2. If any aspect could not be resolved, set `capacityResolved: false`.
3. Pass counts into `evaluateSubclassKit` / `SubclassKitEvalInput`.
4. Never invent capacity as `0` with `capacityResolved: true` unless zero is truly correct — that hard-blocks any fragment.

## TS parity reference

- Source: `src/lib/builds/destinyBuildConstraints.ts`
- Tests: `src/lib/builds/destinyBuildConstraints.test.ts`
