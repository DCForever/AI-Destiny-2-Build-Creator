import 'package:destiny2_domain/destiny2_domain.dart';
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

  test('toast message includes result index', () {
    expect(
      optimizeAppliedToastMessage(3),
      'Optimized with result #3 · Undo',
    );
  });
}
