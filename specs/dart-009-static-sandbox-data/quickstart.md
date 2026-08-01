# Quickstart: DART-009 Static Sandbox Data

## Bootstrap

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart pub get
```

## Run tests

```powershell
dart test packages/sandbox_data
dart analyze packages/sandbox_data
# full workspace (optional):
dart test packages/domain
```

## Minimal usage

```dart
import 'package:destiny2_sandbox_data/destiny2_sandbox_data.dart';

final meleeLines = computeBenefitsAt(ArmorStatName.melee, 200);
// contains "+30% melee ability damage"

final verb = resolveVerbSubType('Arc Ionic Traces'); // Ionic Trace
final element = impliedElementForVerb(verb); // Arc

final counter = getChampionCounterForFrame('Adaptive Frame', 'Scout Rifle');
// ChampionType.barrier

final artifactOk = isArtifactAllowed('Grandmaster Nightfall'); // true
```

## Sandbox patches

See [docs/sandbox-data-update-process.md](../../docs/sandbox-data-update-process.md).

## Branch workflow

1. Base: `feature/multiplatform-dart`
2. Feature: `dart-009-static-sandbox-data`
3. Merge finish-spec **only** into `feature/multiplatform-dart`
