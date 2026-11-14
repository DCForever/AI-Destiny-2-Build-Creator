import 'dart:convert';
import 'dart:io';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
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

  test(
    'Apply then Undo restores Fill In + optimize store files (absent and present)',
    () async {
      final temp = await Directory.systemTemp.createTemp('opt_undo_');
      addTearDown(() async {
        if (await temp.exists()) await temp.delete(recursive: true);
      });
      final root = StorageRoot(basePath: temp.path);
      final optStore = OptimizeBuildStore(root: root);
      final fiStore = FillInMissingListStore(root: root);
      final b = build();

      // Case A: no prior records — Undo clears only this build's new entries.
      final cAbsent = BuildsOptimizeController(
        loadArmorItems: () async => syntheticArmor(),
        optimizeRunner: fakeResponse,
        optimizeStore: optStore,
        fillInStore: fiStore,
      );
      await cAbsent.refreshArmorCsv();
      final appliedA = await cAbsent.runOptimize(
        build: b,
        mode: BuildsOptimizeMode.autoApplyFirst,
      );
      expect(appliedA, isNotNull);
      expect(await optStore.loadForBuild(b.id), isNotNull);
      expect(await fiStore.loadForBuild(b.id), isNotNull);

      final undoneA = await cAbsent.undoLastApply();
      expect(undoneA, isNotNull);
      expect(await optStore.loadForBuild(b.id), isNull);
      expect(await fiStore.loadForBuild(b.id), isNull);

      // Case B: prior Fill In plan + prior Optimize record exist — restore both.
      final priorPlan = FillInSavedBuildPlan(
        buildId: b.id,
        missing: const [],
        applied: [
          FillInAppliedSlot(
            slotWire: 'primary',
            label: 'Prior Primary',
            originalLabel: '',
            instanceId: 'prior-w',
            itemHash: 77,
          ),
        ],
        rows: [
          FillInSavedSlotRow(
            slotWire: 'primary',
            slotLabel: 'Primary',
            state: 'filled',
            itemName: 'Prior Primary',
          ),
        ],
      );
      await fiStore.saveBuildPlan(priorPlan);
      final priorOpt = OptimizedBuildRecord(
        buildId: b.id,
        isOptimized: true,
        resultIndexOneBased: 9,
        slots: const [
          OptimizedArmorSlot(
            slotWire: 'helmet',
            pieceName: 'Prior Helm',
            setId: 'prior',
            isExotic: false,
          ),
        ],
        stats: const [],
        setBonuses: const [],
      );
      await optStore.saveBuildRecord(priorOpt);

      final fillBefore = await File(root.fillInMissingByBuildPath).readAsString();
      final optBefore = await File(root.optimizeByBuildPath).readAsString();

      final cPresent = BuildsOptimizeController(
        loadArmorItems: () async => syntheticArmor(),
        optimizeRunner: fakeResponse,
        optimizeStore: optStore,
        fillInStore: fiStore,
      );
      await cPresent.refreshArmorCsv();
      final appliedB = await cPresent.runOptimize(
        build: b,
        mode: BuildsOptimizeMode.autoApplyFirst,
      );
      expect(appliedB, isNotNull);
      expect(await optStore.loadForBuild(b.id), isNotNull);
      final midPlan = await fiStore.loadForBuild(b.id);
      expect(midPlan, isNotNull);
      // Weapon pin from prior must survive merge (B1).
      expect(
        midPlan!.applied.any(
          (a) => a.slotWire == 'primary' && a.label == 'Prior Primary',
        ),
        isTrue,
      );

      await cPresent.undoLastApply();
      final fillAfter = await File(root.fillInMissingByBuildPath).readAsString();
      final optAfter = await File(root.optimizeByBuildPath).readAsString();
      expect(jsonDecode(fillAfter), jsonDecode(fillBefore));
      expect(jsonDecode(optAfter), jsonDecode(optBefore));
      final restoredOpt = await optStore.loadForBuild(b.id);
      expect(restoredOpt!.resultIndexOneBased, 9);
      expect(restoredOpt.slots.single.pieceName, 'Prior Helm');
      final restoredPlan = await fiStore.loadForBuild(b.id);
      expect(restoredPlan!.applied.single.label, 'Prior Primary');
    },
  );

  test(
    'corrupt Fill In store stops before any write; corrupt bytes untouched',
    () async {
      final temp = await Directory.systemTemp.createTemp('opt_corrupt_fi_');
      addTearDown(() async {
        if (await temp.exists()) await temp.delete(recursive: true);
      });
      final root = StorageRoot(basePath: temp.path);
      await Directory(root.fillInCacheDir).create(recursive: true);
      const corrupt = '{not-json';
      final fiPath = root.fillInMissingByBuildPath;
      await File(fiPath).writeAsString(corrupt);
      final optPath = root.optimizeByBuildPath;
      expect(File(optPath).existsSync(), isFalse);

      final c = BuildsOptimizeController(
        loadArmorItems: () async => syntheticArmor(),
        optimizeRunner: fakeResponse,
        optimizeStore: OptimizeBuildStore(root: root),
        fillInStore: FillInMissingListStore(root: root),
      );
      await c.refreshArmorCsv();
      final applied = await c.runOptimize(
        build: build(),
        mode: BuildsOptimizeMode.autoApplyFirst,
      );
      expect(applied, isNull);
      expect(c.error, isNotNull);
      expect(c.canUndo, isFalse);
      expect(await File(fiPath).readAsString(), corrupt);
      expect(File(optPath).existsSync(), isFalse);
    },
  );

  test(
    'failed apply on corrupt Fill In leaves canUndo false; store files unchanged',
    () async {
      final temp = await Directory.systemTemp.createTemp('opt_baseline_');
      addTearDown(() async {
        if (await temp.exists()) await temp.delete(recursive: true);
      });
      final root = StorageRoot(basePath: temp.path);
      await Directory(root.fillInCacheDir).create(recursive: true);

      final b = build();
      final optStore = OptimizeBuildStore(root: root);
      await optStore.saveBuildRecord(
        OptimizedBuildRecord(
          buildId: b.id,
          isOptimized: true,
          resultIndexOneBased: 3,
          slots: const [
            OptimizedArmorSlot(
              slotWire: 'helmet',
              pieceName: 'Prior Helm',
              setId: 'prior',
              isExotic: false,
            ),
          ],
          stats: const [],
          setBonuses: const [],
        ),
      );
      const corrupt = '{not-json}';
      final fiPath = root.fillInMissingByBuildPath;
      await File(fiPath).writeAsString(corrupt);
      final optBefore = await File(root.optimizeByBuildPath).readAsString();

      final c = BuildsOptimizeController(
        loadArmorItems: () async => syntheticArmor(),
        optimizeRunner: fakeResponse,
        optimizeStore: optStore,
        fillInStore: FillInMissingListStore(root: root),
      );
      await c.refreshArmorCsv();
      final applied = await c.runOptimize(
        build: b,
        mode: BuildsOptimizeMode.autoApplyFirst,
      );
      expect(applied, isNull);
      expect(c.canUndo, isFalse);
      expect(c.error, isNotNull);
      expect(await File(fiPath).readAsString(), corrupt);
      expect(await File(root.optimizeByBuildPath).readAsString(), optBefore);
      // Prior optimize entry still loadable — Undo never cleared it.
      final prior = await optStore.loadForBuild(b.id);
      expect(prior, isNotNull);
      expect(prior!.resultIndexOneBased, 3);
    },
  );

  test(
    'persistMergedFillInPlan save failure sets error and returns false',
    () async {
      final temp = await Directory.systemTemp.createTemp('opt_persist_fail_');
      addTearDown(() async {
        if (await temp.exists()) await temp.delete(recursive: true);
      });
      final root = StorageRoot(basePath: temp.path);
      await Directory(root.fillInCacheDir).create(recursive: true);
      // Corrupt file → saveBuildPlan fails closed without overwriting.
      await File(root.fillInMissingByBuildPath).writeAsString('{not-json}');

      final c = BuildsOptimizeController(
        fillInStore: FillInMissingListStore(root: root),
      );
      final ok = await c.persistMergedFillInPlan(
        FillInSavedBuildPlan(
          buildId: build().id,
          missing: const [],
          applied: const [
            FillInAppliedSlot(
              slotWire: 'primary',
              label: 'Gun',
              originalLabel: '',
              instanceId: 'i1',
              itemHash: 1,
            ),
          ],
        ),
      );
      expect(ok, isFalse);
      expect(c.error, isNotNull);
      expect(await File(root.fillInMissingByBuildPath).readAsString(), '{not-json}');
    },
  );
}
