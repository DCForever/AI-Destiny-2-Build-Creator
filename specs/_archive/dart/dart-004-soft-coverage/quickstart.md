# Quickstart: DART-004 Soft Coverage

## Run tests

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test packages/domain
dart analyze packages/domain
```

## Soft coverage example

```dart
import 'package:destiny2_domain/destiny2_domain.dart';

final result = evaluateCoverage(
  CoverageEvalInput(
    claims: [
      SlotClaim(
        slot: EquipmentSlot.primary,
        itemHash: 1,
        itemName: 'Gun',
        source: ClaimSource.set,
      ),
    ],
    synergies: [
      Synergy(
        id: 'syn-1',
        name: 'Trace',
        type: SynergyType('melee'),
        links: [
          SynergyLink(
            id: 'a',
            synergyId: 'syn-1',
            kind: SynergyLinkKind.weapon,
            displayName: 'A',
            itemHash: 1,
          ),
          SynergyLink(
            id: 'b',
            synergyId: 'syn-1',
            kind: SynergyLinkKind.weapon,
            displayName: 'B',
            itemHash: 2,
          ),
        ],
      ),
    ],
    subclassElement: 'Arc',
  ),
);
// result.synergies.first.tier == CoverageTier.weak
// result is CoverageResult — never a hard block
```

## Soft stat estimate

```dart
final estimate = estimateLoadoutStats(
  claims,
  {'inst-1': {ArmorStatName.health: 30}},
);
final warnings = softStatWarnings(
  SoftStatTargets({ArmorStatName.health: 100}),
  estimate,
);
```

## Hard vs soft

- Hard gates: `evaluateExoticLimits` → `ConstraintEvaluation.hardBlocks`
- Soft coverage: `evaluateCoverage` → `CoverageResult` (no hardBlocks)
