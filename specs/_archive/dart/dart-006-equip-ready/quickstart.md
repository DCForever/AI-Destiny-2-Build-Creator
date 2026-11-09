# Quickstart: DART-006 Equip Ready

## Run tests

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test packages/domain
dart analyze packages/domain
```

## Equip-ready example

```dart
import 'package:destiny2_domain/destiny2_domain.dart';

final resolved = ResolvedVariantEquipment(
  equipment: {
    EquipmentSlot.primary: SlotClaim(
      slot: EquipmentSlot.primary,
      itemHash: 1,
      itemName: 'Gun',
      source: ClaimSource.set,
      instanceId: 'a',
    ),
  },
);

final inventory = buildInventoryPinIndex([
  InventoryPinItem(instanceId: 'a', itemHash: 1),
]);

final result = computeEquipReady(resolved, inventory);
// result.equipReady == true

assertEquipReady(result); // no throw
```
