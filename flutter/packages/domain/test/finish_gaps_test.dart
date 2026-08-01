import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

Map<String, FinishEquipmentClaim> eq(List<String> slots) {
  final out = <String, FinishEquipmentClaim>{};
  var i = 1;
  for (final slot in slots) {
    out[slot] = FinishEquipmentClaim(
      slot: slot,
      itemHash: i++,
      itemName: slot,
    );
  }
  return out;
}

List<String> get armorSlotNames =>
    EquipmentSlot.armorSlots.map((s) => s.wireName).toList();

List<String> get weaponSlotNames =>
    EquipmentSlot.weaponSlots.map((s) => s.wireName).toList();

FinishGap gap(
  FinishCategory category,
  FinishGapStatus status, {
  String? coveringSetId,
  AttachmentMode? coveringMode,
  List<String> emptySlots = const [],
  int filledSlotCount = 0,
  int requiredSlotCount = 0,
  int resolvedClaimCount = 0,
  bool canCapture = false,
}) {
  return FinishGap(
    category: category,
    status: status,
    coveringSetId: coveringSetId,
    coveringSetName: null,
    coveringMode: coveringMode,
    emptySlots: emptySlots,
    filledSlotCount: filledSlotCount,
    requiredSlotCount: requiredSlotCount,
    resolvedClaimCount: resolvedClaimCount,
    canCapture: canCapture,
  );
}

/// Gap list fields that must match across default vs non-default.
void expectStableGapList(FinishGapsResult a, FinishGapsResult b) {
  expect(a.complete, b.complete);
  expect(a.gaps.length, b.gaps.length);
  for (var i = 0; i < a.gaps.length; i++) {
    expect(a.gaps[i].category, b.gaps[i].category);
    expect(a.gaps[i].status, b.gaps[i].status);
    expect(a.gaps[i].emptySlots, b.gaps[i].emptySlots);
    expect(a.gaps[i].filledSlotCount, b.gaps[i].filledSlotCount);
    expect(a.gaps[i].requiredSlotCount, b.gaps[i].requiredSlotCount);
    expect(a.gaps[i].resolvedClaimCount, b.gaps[i].resolvedClaimCount);
    expect(a.gaps[i].canCapture, b.gaps[i].canCapture);
    expect(a.gaps[i].coveringSetId, b.gaps[i].coveringSetId);
    expect(a.gaps[i].coveringMode, b.gaps[i].coveringMode);
  }
  if (a.nextActionable == null) {
    expect(b.nextActionable, isNull);
  } else {
    expect(b.nextActionable, isNotNull);
    expect(a.nextActionable!.category, b.nextActionable!.category);
    expect(a.nextActionable!.status, b.nextActionable!.status);
  }
}

void main() {
  group('evaluateFinishGaps', () {
    test('orders categories armor → weapon → mod', () {
      final r = evaluateFinishGaps(
        const EvaluateFinishGapsInput(
          variantId: 'v1',
          isDefaultVariant: true,
        ),
      );
      expect(
        r.gaps.map((g) => g.category).toList(),
        [FinishCategory.armor, FinishCategory.weapon, FinishCategory.mod],
      );
    });

    test('needs_set when no covering set and no claims', () {
      final r = evaluateFinishGaps(
        const EvaluateFinishGapsInput(
          variantId: 'v1',
          isDefaultVariant: true,
        ),
      );
      expect(r.gaps[0].status, FinishGapStatus.needsSet);
      expect(r.gaps[0].canCapture, isFalse);
      expect(r.complete, isFalse);
    });

    test('capture_available when claims exist without covering set', () {
      final r = evaluateFinishGaps(
        EvaluateFinishGapsInput(
          variantId: 'v1',
          isDefaultVariant: true,
          equipment: eq(['helmet', 'arms']),
        ),
      );
      expect(r.gaps[0].status, FinishGapStatus.captureAvailable);
      expect(r.gaps[0].canCapture, isTrue);
      expect(r.gaps[0].resolvedClaimCount, 2);
    });

    test('needs_fill when covering set attached but slots empty', () {
      final r = evaluateFinishGaps(
        const EvaluateFinishGapsInput(
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
        ),
      );
      expect(r.gaps[0].status, FinishGapStatus.needsFill);
      expect(r.gaps[0].coveringSetId, 'a1');
      expect(r.gaps[0].emptySlots, armorSlotNames);
    });

    test('satisfied only when covering set and all required slots filled', () {
      final r = evaluateFinishGaps(
        EvaluateFinishGapsInput(
          variantId: 'v1',
          isDefaultVariant: true,
          attachments: const [
            FinishAttachmentInput(
              setId: 'a1',
              mode: AttachmentMode.live,
              setType: SetType.armor,
              setName: 'A',
            ),
            FinishAttachmentInput(
              setId: 'w1',
              mode: AttachmentMode.live,
              setType: SetType.weapon,
              setName: 'W',
            ),
            FinishAttachmentInput(
              setId: 'm1',
              mode: AttachmentMode.live,
              setType: SetType.mod,
              setName: 'M',
            ),
          ],
          equipment: eq([...armorSlotNames, ...weaponSlotNames]),
        ),
      );
      expect(r.gaps.every((g) => g.status == FinishGapStatus.satisfied), isTrue);
      expect(r.complete, isTrue);
      expect(r.nextActionable, isNull);
    });

    test('prefers live covering set over snapshot of same type', () {
      final r = evaluateFinishGaps(
        EvaluateFinishGapsInput(
          variantId: 'v1',
          isDefaultVariant: true,
          attachments: const [
            FinishAttachmentInput(
              setId: 'snap',
              mode: AttachmentMode.snapshot,
              setType: SetType.armor,
              setName: 'S',
            ),
            FinishAttachmentInput(
              setId: 'live',
              mode: AttachmentMode.live,
              setType: SetType.armor,
              setName: 'L',
            ),
          ],
          equipment: eq([...armorSlotNames]),
        ),
      );
      expect(r.gaps[0].coveringSetId, 'live');
      expect(r.gaps[0].coveringMode, AttachmentMode.live);
    });

    test('mod satisfied via hasModCoverage without mod set', () {
      final r = evaluateFinishGaps(
        EvaluateFinishGapsInput(
          variantId: 'v1',
          isDefaultVariant: true,
          attachments: const [
            FinishAttachmentInput(
              setId: 'a1',
              mode: AttachmentMode.live,
              setType: SetType.armor,
            ),
            FinishAttachmentInput(
              setId: 'w1',
              mode: AttachmentMode.live,
              setType: SetType.weapon,
            ),
          ],
          equipment: eq([...armorSlotNames, ...weaponSlotNames]),
          hasModCoverage: true,
        ),
      );
      expect(
        r.gaps.firstWhere((g) => g.category == FinishCategory.mod).status,
        FinishGapStatus.satisfied,
      );
      expect(r.complete, isTrue);
    });

    test('nextActionable skips session-skipped categories then falls back', () {
      final r = evaluateFinishGaps(
        const EvaluateFinishGapsInput(
          variantId: 'v1',
          isDefaultVariant: true,
          skippedKeys: ['armor'],
        ),
      );
      expect(r.nextActionable?.category, FinishCategory.weapon);
    });

    test('zero itemHash does not count as filled', () {
      final r = evaluateFinishGaps(
        const EvaluateFinishGapsInput(
          variantId: 'v1',
          isDefaultVariant: true,
          attachments: [
            FinishAttachmentInput(
              setId: 'a1',
              mode: AttachmentMode.live,
              setType: SetType.armor,
            ),
          ],
          equipment: {
            'helmet': FinishEquipmentClaim(
              slot: 'helmet',
              itemHash: 0,
              itemName: 'bad',
            ),
          },
        ),
      );
      expect(r.gaps[0].status, FinishGapStatus.needsFill);
      expect(r.gaps[0].emptySlots, contains('helmet'));
      expect(r.gaps[0].resolvedClaimCount, 0);
    });

    test('mod never canCapture', () {
      final r = evaluateFinishGaps(
        const EvaluateFinishGapsInput(
          variantId: 'v1',
          isDefaultVariant: false,
        ),
      );
      final mod = r.gaps.firstWhere((g) => g.category == FinishCategory.mod);
      expect(mod.status, FinishGapStatus.needsSet);
      expect(mod.canCapture, isFalse);
    });
  });

  group('default vs non-default gap list stability', () {
    test('empty kit: identical gaps; only isDefaultVariant differs', () {
      final def = evaluateFinishGaps(
        const EvaluateFinishGapsInput(
          variantId: 'v1',
          isDefaultVariant: true,
        ),
      );
      final non = evaluateFinishGaps(
        const EvaluateFinishGapsInput(
          variantId: 'v1',
          isDefaultVariant: false,
        ),
      );
      expect(def.isDefaultVariant, isTrue);
      expect(non.isDefaultVariant, isFalse);
      expectStableGapList(def, non);
    });

    test('partial capture_available + unsatisfied weapon: stable list', () {
      final equipment = eq(['helmet', 'arms']);
      final def = evaluateFinishGaps(
        EvaluateFinishGapsInput(
          variantId: 'v-partial',
          isDefaultVariant: true,
          equipment: equipment,
        ),
      );
      final non = evaluateFinishGaps(
        EvaluateFinishGapsInput(
          variantId: 'v-partial',
          isDefaultVariant: false,
          equipment: equipment,
        ),
      );
      expect(def.gaps[0].status, FinishGapStatus.captureAvailable);
      expect(def.nextActionable?.category, FinishCategory.armor);
      expectStableGapList(def, non);
    });

    test('fully satisfied kit: both complete with null nextActionable', () {
      final equipment = eq([...armorSlotNames, ...weaponSlotNames]);
      const attachments = [
        FinishAttachmentInput(
          setId: 'a1',
          mode: AttachmentMode.live,
          setType: SetType.armor,
        ),
        FinishAttachmentInput(
          setId: 'w1',
          mode: AttachmentMode.live,
          setType: SetType.weapon,
        ),
        FinishAttachmentInput(
          setId: 'm1',
          mode: AttachmentMode.live,
          setType: SetType.mod,
        ),
      ];
      final def = evaluateFinishGaps(
        EvaluateFinishGapsInput(
          variantId: 'v-full',
          isDefaultVariant: true,
          attachments: attachments,
          equipment: equipment,
        ),
      );
      final non = evaluateFinishGaps(
        EvaluateFinishGapsInput(
          variantId: 'v-full',
          isDefaultVariant: false,
          attachments: attachments,
          equipment: equipment,
        ),
      );
      expect(def.complete, isTrue);
      expect(non.complete, isTrue);
      expect(def.nextActionable, isNull);
      expect(non.nextActionable, isNull);
      expectStableGapList(def, non);
    });
  });

  group('finishNextSlot', () {
    test('maps category to set type', () {
      expect(finishCategoryToSetType(FinishCategory.weapon), SetType.weapon);
      expect(finishCategoryToSetType(FinishCategory.armor), SetType.armor);
      expect(finishCategoryToSetType(FinishCategory.mod), SetType.mod);
    });

    test('returns first empty weapon slot in primary→special→heavy order', () {
      final g = gap(
        FinishCategory.weapon,
        FinishGapStatus.needsFill,
        coveringSetId: 's1',
        coveringMode: AttachmentMode.live,
        emptySlots: ['primary', 'special', 'heavy'],
        requiredSlotCount: 3,
      );
      expect(firstEmptyRequiredSlot(g), 'primary');
      final step = resolvePostMutationStep(ResolvePostMutationStepInput(gap: g));
      expect(
        step,
        const FinishPostMutationTarget(
          step: FinishWalkthroughStep.fill,
          fillSlot: 'primary',
          category: FinishCategory.weapon,
        ),
      );
    });

    test('returns first empty armor slot in required order', () {
      final g = gap(
        FinishCategory.armor,
        FinishGapStatus.needsFill,
        coveringSetId: 'a1',
        coveringMode: AttachmentMode.live,
        emptySlots: armorSlotNames,
        requiredSlotCount: 5,
      );
      expect(firstEmptyRequiredSlot(g), 'helmet');
      expect(
        resolvePostMutationStep(
          ResolvePostMutationStepInput(gap: g, preferArmorOptimize: false),
        ).fillSlot,
        'helmet',
      );
    });

    test('opens armor_optimize for live covering armor by default', () {
      final g = gap(
        FinishCategory.armor,
        FinishGapStatus.needsFill,
        coveringSetId: 'a1',
        coveringMode: AttachmentMode.live,
        emptySlots: ['helmet'],
        requiredSlotCount: 5,
      );
      expect(
        resolvePostMutationStep(ResolvePostMutationStepInput(gap: g)),
        const FinishPostMutationTarget(
          step: FinishWalkthroughStep.armorOptimize,
          fillSlot: null,
          category: FinishCategory.armor,
        ),
      );
    });

    test('after synthetic needs_fill with only special left opens special', () {
      final g = gap(
        FinishCategory.weapon,
        FinishGapStatus.needsFill,
        coveringSetId: 's1',
        coveringMode: AttachmentMode.live,
        emptySlots: ['special', 'heavy'],
        filledSlotCount: 1,
        requiredSlotCount: 3,
      );
      final step =
          resolvePostMutationStep(ResolvePostMutationStepInput(gap: g));
      expect(step.step, FinishWalkthroughStep.fill);
      expect(step.fillSlot, 'special');
    });

    test('successive empties shrink to next slot', () {
      var empty = ['primary', 'special', 'heavy'];
      FinishPostMutationTarget next() {
        return resolvePostMutationStep(
          ResolvePostMutationStepInput(
            gap: gap(
              FinishCategory.weapon,
              empty.isEmpty
                  ? FinishGapStatus.satisfied
                  : FinishGapStatus.needsFill,
              coveringSetId: 's1',
              coveringMode: AttachmentMode.live,
              emptySlots: [...empty],
              requiredSlotCount: 3,
              filledSlotCount: 3 - empty.length,
            ),
          ),
        );
      }

      expect(next().fillSlot, 'primary');
      empty = ['special', 'heavy'];
      expect(next().fillSlot, 'special');
      empty = ['heavy'];
      expect(next().fillSlot, 'heavy');
      empty = [];
      expect(
        next(),
        const FinishPostMutationTarget(
          step: FinishWalkthroughStep.overview,
          fillSlot: null,
          category: null,
        ),
      );
    });

    test('satisfied gap returns overview', () {
      expect(
        resolvePostMutationStep(
          ResolvePostMutationStepInput(
            gap: gap(
              FinishCategory.weapon,
              FinishGapStatus.satisfied,
              emptySlots: const [],
            ),
          ),
        ),
        const FinishPostMutationTarget(
          step: FinishWalkthroughStep.overview,
          fillSlot: null,
          category: null,
        ),
      );
    });

    test('null gap returns overview', () {
      expect(
        resolvePostMutationStep(const ResolvePostMutationStepInput(gap: null)),
        const FinishPostMutationTarget(
          step: FinishWalkthroughStep.overview,
          fillSlot: null,
          category: null,
        ),
      );
    });

    test('snapshot needs_fill does not auto-enter fill', () {
      final g = gap(
        FinishCategory.armor,
        FinishGapStatus.needsFill,
        coveringSetId: 'snap',
        coveringMode: AttachmentMode.snapshot,
        emptySlots: ['helmet'],
        requiredSlotCount: 5,
      );
      expect(
        resolvePostMutationStep(ResolvePostMutationStepInput(gap: g)),
        const FinishPostMutationTarget(
          step: FinishWalkthroughStep.category,
          fillSlot: null,
          category: FinishCategory.armor,
        ),
      );
    });

    test('needs_set stays on category for create', () {
      expect(
        resolvePostMutationStep(
          ResolvePostMutationStepInput(
            gap: gap(FinishCategory.weapon, FinishGapStatus.needsSet),
          ),
        ),
        const FinishPostMutationTarget(
          step: FinishWalkthroughStep.category,
          fillSlot: null,
          category: FinishCategory.weapon,
        ),
      );
    });

    test('showFinishCreateActions for needs_set and capture_available', () {
      expect(showFinishCreateActions(FinishGapStatus.needsSet), isTrue);
      expect(showFinishCreateActions(FinishGapStatus.captureAvailable), isTrue);
      expect(showFinishCreateActions(FinishGapStatus.needsFill), isFalse);
      expect(showFinishCreateActions(FinishGapStatus.satisfied), isFalse);
    });

    test('finishCategoryLabel labels', () {
      expect(finishCategoryLabel(FinishCategory.armor), 'Armor');
      expect(finishCategoryLabel(FinishCategory.weapon), 'Weapons');
      expect(finishCategoryLabel(FinishCategory.mod), 'Mods');
    });
  });
}
