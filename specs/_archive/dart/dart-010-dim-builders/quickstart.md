# Quickstart: DART-010 DIM Builders

## Run tests

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test packages/domain
dart analyze packages/domain
```

Focused:

```powershell
dart test packages/domain/test/dim_builders_test.dart
```

## Use (pure)

```dart
import 'package:destiny2_domain/destiny2_domain.dart';

final loadout = buildVariantDimLoadout(
  VariantDimLoadoutInput(
    buildName: 'Solar Titan',
    className: GuardianClass.titan,
    equipment: {
      EquipmentSlot.primary: SlotClaim(
        slot: EquipmentSlot.primary,
        itemHash: 111,
        itemName: 'Gun',
        source: ClaimSource.set,
        instanceId: 'inst-1',
      ),
    },
    modHashes: const [9001],
  ),
  id: '00000000-0000-4000-8000-000000000001',
);

final payload = buildJsonOnlyDimExport(
  readiness: computeEquipReady(resolved, inventory),
  input: /* same input */,
  loadoutId: '00000000-0000-4000-8000-000000000001',
);
// payload['loadout'] is a JSON-ready Map
```

## Non-goals here

- dim.gg share, OAuth, HTTP
- Loading mods from SQLite (`collectVariantMods`)
