import 'dart:io';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_fixture.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/optimize/builds_optimize_apply.dart';
import 'package:destiny2_windows_host/optimize/builds_optimize_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Skeptic plan item 5 (2026-11-20): after Apply then Undo, state equals the
/// pre-Apply snapshot (mandatory; post-Undo must not drift).
void main() {
  late MockBuild baseline;

  setUp(() {
    baseline = loadBuildsMockFixture().builds.first;
  });

  MockBuild withSubstitutePrimary(MockBuild build) {
    final slots = [
      for (final s in build.slots)
        if (s.slot == 'primary')
          s.copyWith(isSubstitute: true, pieceName: 'Sub Gun')
        else
          s,
    ];
    if (!slots.any((s) => s.slot == 'primary')) {
      slots.add(
        const MockSlotAssignment(
          slot: 'primary',
          setId: 'weapon',
          pieceName: 'Sub Gun',
          isSubstitute: true,
        ),
      );
    }
    return build.copyWith(slots: List.unmodifiable(slots));
  }

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

  List<FillInInventoryItem> syntheticArmor() {
    return [
      for (final slot in EquipmentSlot.armorSlots)
        FillInInventoryItem(
          instanceId: 'a-${slot.wireName}-1',
          itemHash: 100 + slot.index,
          slot: slot,
          isExotic: slot == EquipmentSlot.arms,
          guardianClass: GuardianClass.warlock,
          armorSetHash: slot == EquipmentSlot.arms ? null : 501,
          name: 'Techsec ${slot.wireName}',
          location: 'vault',
          statValues: const {
            ArmorStatName.health: 20,
            ArmorStatName.weapons: 10,
          },
        ),
    ];
  }

  Future<ArmorOptimizeResponse> fakeResponse(ArmorOptimizeRequest request) async {
    final bySlot = <EquipmentSlot, CandidatePiece>{};
    for (final c in request.candidates) {
      bySlot.putIfAbsent(c.slot, () => c);
    }
    final pieces = <ArmorOptimizePiece>[
      for (final slot in EquipmentSlot.armorSlots)
        if (bySlot[slot] != null)
          ArmorOptimizePiece(
            slot: slot,
            itemHash: bySlot[slot]!.itemHash,
            instanceId: bySlot[slot]!.instanceId,
            itemName: bySlot[slot]!.itemName,
            isExotic: bySlot[slot]!.isExotic,
            setBonusKey: bySlot[slot]!.setBonusKey,
            statValues: bySlot[slot]!.statValues,
          ),
    ];
    return ArmorOptimizeResponse(
      combinations: [
        ArmorCombination(
          pieces: pieces,
          estimatedStats: const {
            ArmorStatName.weapons: 25,
            ArmorStatName.health: 80,
            ArmorStatName.classStat: 40,
            ArmorStatName.grenade: 90,
            ArmorStatName.superStat: 30,
            ArmorStatName.melee: 20,
          },
          incompleteEstimate: false,
          setBonusSummary: const [
            SetBonusSummaryEntry(
              setBonusKey: 'set:501',
              pieceCount: 4,
              active2pc: true,
              active4pc: true,
            ),
          ],
          reusePieceCount: 2,
          score: 350,
          meetsSoftThresholds: true,
        ),
      ],
      truncated: false,
      evaluatedCount: 1,
    );
  }

  test(
    'Skeptic #5: Apply then Undo restores the exact pre-Apply snapshot '
    'including isSubstitute',
    () {
      final before = withSubstitutePrimary(baseline);
      expect(
        before.slots.any((s) => s.slot == 'primary' && s.isSubstitute),
        isTrue,
      );
      final snap = snapshotMockBuild(before);
      _expectMockBuildEquals(
        snap,
        before,
        reason: 'snapshot must preserve isSubstitute',
      );

      final applied = applyOptimizeCombinationToBuild(
        build: before,
        combination: _combo(),
        resultIndexOneBased: 1,
      );
      expect(applied.isOptimized, isTrue);

      final undone = undoOptimizeOnBuild(snap);
      _expectMockBuildEquals(
        undone,
        snap,
        reason: 'post-Undo must equal the pre-Apply snapshot',
      );
      expect(
        undone.slots.singleWhere((s) => s.slot == 'primary').isSubstitute,
        isTrue,
        reason: 'Undo must restore isSubstitute on the substitute slot',
      );
    },
  );

  test(
    'Skeptic #5: controller undoLastApply restores isSubstitute via store path',
    () async {
      final temp = await Directory.systemTemp.createTemp('skeptic_undo_');
      addTearDown(() async {
        if (await temp.exists()) await temp.delete(recursive: true);
      });
      final root = StorageRoot(basePath: temp.path);
      final before = withSubstitutePrimary(baseline);
      final c = BuildsOptimizeController(
        loadArmorItems: () async => syntheticArmor(),
        optimizeRunner: fakeResponse,
        optimizeStore: OptimizeBuildStore(root: root),
        fillInStore: FillInMissingListStore(root: root),
      );
      await c.refreshArmorCsv();
      final applied = await c.runOptimize(
        build: before,
        mode: BuildsOptimizeMode.autoApplyFirst,
      );
      expect(applied, isNotNull);
      expect(c.canUndo, isTrue);

      final restored = await c.undoLastApply();
      expect(restored, isNotNull);
      _expectMockBuildEquals(
        restored!,
        before.copyWith(isOptimized: false),
        reason: 'controller Undo must restore full pre-Apply build',
      );
      expect(
        restored.slots.singleWhere((s) => s.slot == 'primary').isSubstitute,
        isTrue,
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
    '${s.isExoticSlot}|${s.statTotal}|${s.filledIn}|${s.isSubstitute}';

String _bonusKey(MockSetBonus b) =>
    '${b.setId}|${b.setName}|${b.pieces}|${b.tier}|${b.text}';
