import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_fixture.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/optimize/builds_optimize_apply.dart';
import 'package:destiny2_windows_host/optimize/builds_optimize_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MockBuild build() => loadBuildsMockFixture().builds.first;

  List<FillInInventoryItem> syntheticArmor() {
    return [
      for (final slot in EquipmentSlot.armorSlots) ...[
        FillInInventoryItem(
          instanceId: 'a-${slot.wireName}-1',
          itemHash: 100 + slot.index,
          slot: slot,
          isExotic: false,
          guardianClass: GuardianClass.warlock,
          armorSetHash: 501,
          name: 'Techsec ${slot.wireName} A',
          location: 'vault',
          statValues: const {
            ArmorStatName.health: 20,
            ArmorStatName.weapons: 10,
          },
        ),
        FillInInventoryItem(
          instanceId: 'a-${slot.wireName}-2',
          itemHash: 200 + slot.index,
          slot: slot,
          isExotic: slot == EquipmentSlot.arms,
          guardianClass: GuardianClass.warlock,
          armorSetHash: slot == EquipmentSlot.arms ? null : 501,
          name: slot == EquipmentSlot.arms
              ? 'Exotic Arms'
              : 'Techsec ${slot.wireName} B',
          location: 'character',
          statValues: const {
            ArmorStatName.health: 15,
            ArmorStatName.melee: 12,
          },
        ),
      ],
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
        ArmorCombination(
          pieces: pieces,
          estimatedStats: const {
            ArmorStatName.weapons: 20,
            ArmorStatName.health: 70,
            ArmorStatName.classStat: 35,
            ArmorStatName.grenade: 80,
            ArmorStatName.superStat: 25,
            ArmorStatName.melee: 15,
          },
          incompleteEstimate: false,
          setBonusSummary: const [
            SetBonusSummaryEntry(
              setBonusKey: 'set:501',
              pieceCount: 2,
              active2pc: true,
              active4pc: false,
            ),
          ],
          reusePieceCount: 1,
          score: 300,
          meetsSoftThresholds: false,
        ),
      ],
      truncated: false,
      evaluatedCount: 2,
    );
  }

  test('no CSV disables Optimize with Settings reason', () async {
    final c = BuildsOptimizeController(
      loadArmorItems: () async => null,
      optimizeRunner: fakeResponse,
    );
    await c.refreshArmorCsv();
    expect(c.disabledReason, kBuildsOptimizeNoCsvReason);
    expect(c.armorItems, isEmpty);
    final result = await c.runOptimize(
      build: build(),
      mode: BuildsOptimizeMode.panel,
    );
    expect(result, isNull);
    expect(c.error, contains('Settings'));
  });

  test('panel run maps CSV candidates and keeps results until confirm', () async {
    final c = BuildsOptimizeController(
      loadArmorItems: () async => syntheticArmor(),
      optimizeRunner: fakeResponse,
      knownSetKeys: const {'set:501'},
    );
    await c.refreshArmorCsv();
    expect(c.disabledReason, isNull);

    final applied = await c.runOptimize(
      build: build(),
      mode: BuildsOptimizeMode.panel,
    );
    expect(applied, isNull);
    expect(c.panelOpen, isTrue);
    expect(c.combinations, hasLength(2));
    expect(c.combinations.first.score, 350);

    final coverage = c.coverageForClass(GuardianClass.warlock)!;
    expect(coverage.setUniverseCount, greaterThanOrEqualTo(1));
    final helmet = coverage.slotRows
        .singleWhere((r) => r.slot == EquipmentSlot.helmet);
    expect(helmet.setsWithTwoPlus, 1);
  });

  test('auto-apply Fill In path applies result #1 and supports undo', () async {
    final c = BuildsOptimizeController(
      loadArmorItems: () async => syntheticArmor(),
      optimizeRunner: fakeResponse,
    );
    await c.refreshArmorCsv();
    final before = build();
    final updated = await c.runOptimize(
      build: before,
      mode: BuildsOptimizeMode.autoApplyFirst,
    );
    expect(updated, isNotNull);
    expect(updated!.isOptimized, isTrue);
    expect(updated.stats, isNotEmpty);
    expect(c.canUndo, isTrue);

    final restored = await c.undoLastApply();
    expect(restored, isNotNull);
    expect(restored!.isOptimized, isFalse);
    expect(
      restored.slots.map((s) => s.pieceName),
      before.slots.map((s) => s.pieceName),
    );
  });
}
