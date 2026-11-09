# Quickstart: DART-005 Resolve Variant

## Run tests

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test packages/domain
dart analyze packages/domain
```

## Claims-only resolve example

```dart
import 'package:destiny2_domain/destiny2_domain.dart';

final resolved = resolveVariantClaims(
  expandedItems: [
    ExpandedSetItem(
      slot: EquipmentSlot.primary,
      itemHash: 1,
      itemName: 'Gun',
      setId: 's1',
      setType: SetType.weapon,
    ),
  ],
  buildExoticArmorHash: null,
  buildExoticWeaponHash: null,
  variantExoticWeaponHash: null,
  exoticWeaponSlot: null,
  exoticArmorSlot: null,
);

assertNoSlotConflicts(resolved);
assertVariantNotEmpty(resolved);
// Default only:
// assertFullCombatLoadout(resolved, className: 'Titan', subclassName: 'Sunbreaker', hasMods: true);
```
