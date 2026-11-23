import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_fixture.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_logic.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/optimize/builds_optimize_apply.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockBuild baseline;

  setUp(() {
    baseline = loadBuildsMockFixture().builds.first;
  });

  ArmorCombination _combo({
    required int score,
    required bool soft,
    Map<ArmorStatName, int>? stats,
  }) {
    return ArmorCombination(
      pieces: [
        for (final slot in EquipmentSlot.armorSlots)
          ArmorOptimizePiece(
            slot: slot,
            itemHash: 1000 + slot.index,
            instanceId: 'inst-${slot.wireName}',
            itemName: 'Opt ${slot.wireName}',
            isExotic: slot == EquipmentSlot.arms,
            setBonusKey: slot == EquipmentSlot.arms ? null : 'Techsec',
            statValues: const {ArmorStatName.health: 10},
          ),
      ],
      estimatedStats: stats ??
          const {
            ArmorStatName.weapons: 30,
            ArmorStatName.health: 70,
            ArmorStatName.classStat: 40,
            ArmorStatName.grenade: 100,
            ArmorStatName.superStat: 50,
            ArmorStatName.melee: 20,
          },
      incompleteEstimate: false,
      setBonusSummary: const [
        SetBonusSummaryEntry(
          setBonusKey: 'Techsec',
          pieceCount: 4,
          active2pc: true,
          active4pc: true,
        ),
      ],
      reusePieceCount: 3,
      score: score,
      meetsSoftThresholds: soft,
    );
  }

  test('apply sets Optimized flag, real stats, and armor slots', () {
    final next = applyOptimizeCombinationToBuild(
      build: baseline,
      combination: _combo(score: 400, soft: true),
      resultIndexOneBased: 1,
    );
    expect(next.isOptimized, isTrue);
    expect(isMockBuildOptimized(next), isTrue);
    expect(next.stats, isNotEmpty);
    expect(next.stats.any((s) => s.id == MockStatId.health && s.value == 70),
        isTrue);
    expect(next.setBonuses, isNotEmpty);
    expect(next.exoticArmor, 'Opt arms');
    final helmet = next.slots.singleWhere((s) => s.slot == 'helmet');
    expect(helmet.pieceName, 'Opt helmet');
    expect(helmet.filledIn, isTrue);
  });

  test('undo restores exact previous state and clears Optimized', () {
    final snap = snapshotMockBuild(baseline);
    final applied = applyOptimizeCombinationToBuild(
      build: baseline,
      combination: _combo(score: 400, soft: true),
      resultIndexOneBased: 2,
    );
    expect(applied.isOptimized, isTrue);
    final undone = undoOptimizeOnBuild(snap);
    expect(undone.isOptimized, isFalse);
    expect(undone.slots.map((s) => s.pieceName).toList(),
        baseline.slots.map((s) => s.pieceName).toList());
    expect(undone.stats.map((s) => s.value).toList(),
        baseline.stats.map((s) => s.value).toList());
  });

  test('Optimized readiness filter matches after apply', () {
    final applied = applyOptimizeCombinationToBuild(
      build: baseline,
      combination: _combo(score: 1, soft: false),
      resultIndexOneBased: 1,
    );
    final filtered = filterMockBuilds(
      builds: [baseline, applied],
      readiness: MockReadiness.optimized,
    );
    expect(filtered, hasLength(1));
    expect(filtered.single.id, applied.id);
  });

  test('toast message includes result index and brief Undo', () {
    expect(
      optimizeAppliedToastMessage(3),
      'Optimized with result #3 · Undo available briefly',
    );
  });

  test('fillInPlanFromCombination merges armor and keeps weapon pins', () {
    const existing = FillInSavedBuildPlan(
      buildId: 'b01',
      missing: ['Heavy'],
      applied: [
        FillInAppliedSlot(
          slotWire: 'primary',
          label: 'Kept Primary',
          originalLabel: 'Old Primary',
          instanceId: 'w-primary',
          itemHash: 9001,
        ),
        FillInAppliedSlot(
          slotWire: 'helmet',
          label: 'Old Helmet',
          originalLabel: '',
          instanceId: 'old-helm',
          itemHash: 1,
        ),
      ],
      rows: [
        FillInSavedSlotRow(
          slotWire: 'primary',
          slotLabel: 'Primary',
          state: 'filled',
          itemName: 'Kept Primary',
        ),
        FillInSavedSlotRow(
          slotWire: 'helmet',
          slotLabel: 'helmet',
          state: 'filled',
          itemName: 'Old Helmet',
        ),
      ],
    );
    final combo = ArmorCombination(
      pieces: [
        const ArmorOptimizePiece(
          slot: EquipmentSlot.helmet,
          itemHash: 42,
          instanceId: 'new-helm',
          itemName: 'New Helmet',
          isExotic: false,
          setBonusKey: 'Techsec',
        ),
        const ArmorOptimizePiece(
          slot: EquipmentSlot.arms,
          itemHash: 43,
          instanceId: 'new-arms',
          // No itemName — must not invent Armor <hash>.
          isExotic: true,
        ),
      ],
      estimatedStats: const {},
      incompleteEstimate: false,
      setBonusSummary: const [],
      reusePieceCount: 0,
      score: 1,
      meetsSoftThresholds: false,
    );
    final merged = fillInPlanFromCombination(
      buildId: 'b01',
      combination: combo,
      existing: existing,
    );
    expect(
      merged.applied.any((a) => a.slotWire == 'primary' && a.label == 'Kept Primary'),
      isTrue,
    );
    expect(
      merged.applied.any(
        (a) =>
            a.slotWire == 'helmet' &&
            a.label == 'New Helmet' &&
            a.instanceId == 'new-helm',
      ),
      isTrue,
    );
    final arms = merged.applied.singleWhere((a) => a.slotWire == 'arms');
    expect(arms.label, isEmpty);
    expect(arms.instanceId, 'new-arms');
    expect(merged.applied.any((a) => a.label.startsWith('Armor ')), isFalse);
    expect(
      merged.rows.any(
        (r) => r.slotWire == 'primary' && r.itemName == 'Kept Primary',
      ),
      isTrue,
    );
  });

  test(
    'weapon persist failure keeps armor-only build (unsaved weapons off screen)',
    () {
      final armorOnly = baseline.copyWith(isOptimized: true);
      final withWeapons = baseline.copyWith(
        isOptimized: true,
        slots: [
          ...baseline.slots,
          const MockSlotAssignment(
            slot: 'primary',
            setId: 'weapon',
            pieceName: 'Unsaved Gun',
            filledIn: true,
          ),
        ],
      );
      final kept = buildAfterWeaponMergePersist(
        armorOnly: armorOnly,
        weaponMerged: withWeapons,
        persistOk: false,
      );
      expect(identical(kept, armorOnly), isTrue);
      expect(kept.slots.any((s) => s.pieceName == 'Unsaved Gun'), isFalse);

      final shown = buildAfterWeaponMergePersist(
        armorOnly: armorOnly,
        weaponMerged: withWeapons,
        persistOk: true,
      );
      expect(identical(shown, withWeapons), isTrue);
      expect(shown.slots.any((s) => s.pieceName == 'Unsaved Gun'), isTrue);
    },
  );

  test('Apply confirms highlighted Optimize result only while panel is open', () {
    expect(
      shouldConfirmHighlightedOptimizeBeforeApply(
        panelOpen: true,
        combinationCount: 3,
        applying: false,
      ),
      isTrue,
    );
    expect(
      shouldConfirmHighlightedOptimizeBeforeApply(
        panelOpen: false,
        combinationCount: 3,
        applying: false,
      ),
      isFalse,
    );
    expect(
      shouldConfirmHighlightedOptimizeBeforeApply(
        panelOpen: true,
        combinationCount: 0,
        applying: false,
      ),
      isFalse,
    );
    expect(
      shouldConfirmHighlightedOptimizeBeforeApply(
        panelOpen: true,
        combinationCount: 2,
        applying: true,
      ),
      isFalse,
    );
  });
}
