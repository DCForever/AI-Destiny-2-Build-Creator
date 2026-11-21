import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_fixture.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/optimize/builds_optimize_apply.dart';
import 'package:flutter_test/flutter_test.dart';

/// Skeptic plan item 5 (2026-11-20): after Apply then Undo, state equals the
/// pre-Apply snapshot (mandatory; post-Undo must not drift).
void main() {
  late MockBuild baseline;

  setUp(() {
    baseline = loadBuildsMockFixture().builds.first;
  });

  ArmorCombination _combo() {
    return ArmorCombination(
      pieces: [
        for (final slot in EquipmentSlot.armorSlots)
          ArmorOptimizePiece(
            slot: slot,
            itemHash: 2000 + slot.index,
            instanceId: 'opt-${slot.wireName}',
            itemName: 'Applied ${slot.wireName}',
            isExotic: slot == EquipmentSlot.arms,
            setBonusKey: slot == EquipmentSlot.arms ? null : 'Techsec',
            statValues: const {ArmorStatName.health: 12},
          ),
      ],
      estimatedStats: const {
        ArmorStatName.weapons: 40,
        ArmorStatName.health: 80,
        ArmorStatName.classStat: 50,
        ArmorStatName.grenade: 90,
        ArmorStatName.superStat: 60,
        ArmorStatName.melee: 30,
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
      reusePieceCount: 2,
      score: 500,
      meetsSoftThresholds: true,
    );
  }

  test(
    'Skeptic #5: Apply then Undo restores the exact pre-Apply snapshot',
    () {
      final snap = snapshotMockBuild(baseline);
      _expectMockBuildEquals(snap, baseline, reason: 'snapshot must match pre-Apply');

      final applied = applyOptimizeCombinationToBuild(
        build: baseline,
        combination: _combo(),
        resultIndexOneBased: 1,
      );
      expect(applied.isOptimized, isTrue);
      expect(
        applied.slots.map((s) => s.pieceName).toList(),
        isNot(equals(baseline.slots.map((s) => s.pieceName).toList())),
        reason: 'Apply must change armor slots so Undo is meaningful',
      );

      final undone = undoOptimizeOnBuild(snap);
      _expectMockBuildEquals(
        undone,
        snap,
        reason: 'post-Undo must equal the pre-Apply snapshot',
      );
      _expectMockBuildEquals(
        undone,
        baseline.copyWith(isOptimized: false),
        reason: 'post-Undo must match the original build (Optimized cleared)',
      );
    },
  );
}

void _expectMockBuildEquals(
  MockBuild actual,
  MockBuild expected, {
  required String reason,
}) {
  expect(actual.id, expected.id, reason: reason);
  expect(actual.name, expected.name, reason: reason);
  expect(actual.subclass, expected.subclass, reason: reason);
  expect(actual.exoticArmor, expected.exoticArmor, reason: reason);
  expect(actual.exoticWeapon, expected.exoticWeapon, reason: reason);
  expect(actual.loop, expected.loop, reason: reason);
  expect(actual.splitWhy, expected.splitWhy, reason: reason);
  expect(actual.creator, expected.creator, reason: reason);
  expect(actual.dimLink, expected.dimLink, reason: reason);
  expect(actual.exoticWeaponType, expected.exoticWeaponType, reason: reason);
  expect(
    actual.exoticWeaponDamageType,
    expected.exoticWeaponDamageType,
    reason: reason,
  );
  expect(actual.exoticWeaponSlot, expected.exoticWeaponSlot, reason: reason);
  expect(actual.isOptimized, expected.isOptimized, reason: reason);
  expect(actual.artifact.name, expected.artifact.name, reason: reason);
  expect(actual.artifact.season, expected.artifact.season, reason: reason);
  expect(actual.artifact.perks, expected.artifact.perks, reason: reason);
  expect(
    actual.slots.map(_slotKey).toList(),
    expected.slots.map(_slotKey).toList(),
    reason: reason,
  );
  expect(
    actual.stats.map((s) => '${s.id.name}:${s.value}').toList(),
    expected.stats.map((s) => '${s.id.name}:${s.value}').toList(),
    reason: reason,
  );
  expect(
    actual.setBonuses.map(_bonusKey).toList(),
    expected.setBonuses.map(_bonusKey).toList(),
    reason: reason,
  );
}

String _slotKey(MockSlotAssignment s) =>
    '${s.slot}|${s.setId}|${s.pieceName}|${s.heldCopies}|'
    '${s.isExoticSlot}|${s.statTotal}|${s.filledIn}';

String _bonusKey(MockSetBonus b) =>
    '${b.setId}|${b.setName}|${b.pieces}|${b.tier}|${b.text}';
