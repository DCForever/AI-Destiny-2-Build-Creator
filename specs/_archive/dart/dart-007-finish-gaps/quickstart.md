# Quickstart: DART-007 Finish Gaps

## Run tests

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test packages/domain
dart analyze packages/domain
```

## Evaluate finish gaps

```dart
import 'package:destiny2_domain/destiny2_domain.dart';

final result = evaluateFinishGaps(
  EvaluateFinishGapsInput(
    variantId: 'v1',
    isDefaultVariant: true,
    attachments: [
      FinishAttachmentInput(
        setId: 'a1',
        mode: AttachmentMode.live,
        setType: SetType.armor,
        setName: 'A',
      ),
    ],
    equipment: {},
  ),
);
// result.gaps[0].status == FinishGapStatus.needsFill
// result.nextActionable?.category == FinishCategory.armor

final step = resolvePostMutationStep(
  ResolvePostMutationStepInput(gap: result.nextActionable),
);
// preferArmorOptimize default → armor_optimize for live armor covering
```
