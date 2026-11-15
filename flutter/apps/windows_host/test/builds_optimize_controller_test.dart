import 'dart:io';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_fixture.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/optimize/builds_optimize_apply.dart';
import 'package:destiny2_windows_host/optimize/builds_optimize_controller.dart';
import 'package:destiny2_windows_host/optimize/weapon_optimize_apply.dart';
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

      final fillBeforeBytes =
          await File(root.fillInMissingByBuildPath).readAsBytes();
      final optBeforeBytes =
          await File(root.optimizeByBuildPath).readAsBytes();

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
      expect(
        await File(root.fillInMissingByBuildPath).readAsBytes(),
        fillBeforeBytes,
      );
      expect(
        await File(root.optimizeByBuildPath).readAsBytes(),
        optBeforeBytes,
      );
      final restoredOpt = await optStore.loadForBuild(b.id);
      expect(restoredOpt!.resultIndexOneBased, 9);
      expect(restoredOpt.slots.single.pieceName, 'Prior Helm');
      final restoredPlan = await fiStore.loadForBuild(b.id);
      expect(restoredPlan!.applied.single.label, 'Prior Primary');
    },
  );

  test(
    'corrupt Fill In store stops before any write; corrupt file bytes untouched',
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
      final corruptBytes = await File(fiPath).readAsBytes();
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
      expect(await File(fiPath).readAsBytes(), corruptBytes);
      expect(File(optPath).existsSync(), isFalse);
    },
  );

  test(
    'failed apply leaves appliedResultIndex unset (highlight not on failed result)',
    () async {
      final temp = await Directory.systemTemp.createTemp('opt_idx_fail_');
      addTearDown(() async {
        if (await temp.exists()) await temp.delete(recursive: true);
      });
      final root = StorageRoot(basePath: temp.path);
      await Directory(root.fillInCacheDir).create(recursive: true);
      await File(root.fillInMissingByBuildPath).writeAsString('{not-json}');

      final c = BuildsOptimizeController(
        loadArmorItems: () async => syntheticArmor(),
        optimizeRunner: fakeResponse,
        optimizeStore: OptimizeBuildStore(root: root),
        fillInStore: FillInMissingListStore(root: root),
      );
      await c.refreshArmorCsv();
      expect(c.appliedResultIndex, isNull);
      final applied = await c.runOptimize(
        build: build(),
        mode: BuildsOptimizeMode.autoApplyFirst,
      );
      expect(applied, isNull);
      expect(c.canUndo, isFalse);
      expect(c.appliedResultIndex, isNull);
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

  test(
    'apply A then failing apply B leaves A undo intact; Undo restores A priors',
    () async {
      final temp = await Directory.systemTemp.createTemp('opt_atomic_prior_');
      addTearDown(() async {
        if (await temp.exists()) await temp.delete(recursive: true);
      });
      final root = StorageRoot(basePath: temp.path);
      final fiStore = FillInMissingListStore(root: root);
      // Fail on 2nd optimize load (apply B) while Fill In load still succeeds.
      final optStore = _FailOnNthOptimizeLoadStore(
        root: root,
        failOnLoadCall: 2,
      );
      final b = build();

      // Seed priors so Undo has something concrete to restore (not clearBuild).
      final priorPlan = FillInSavedBuildPlan(
        buildId: b.id,
        missing: const [],
        applied: const [
          FillInAppliedSlot(
            slotWire: 'primary',
            label: 'Seed Primary',
            originalLabel: '',
            instanceId: 'seed-w',
            itemHash: 11,
          ),
        ],
        rows: const [
          FillInSavedSlotRow(
            slotWire: 'primary',
            slotLabel: 'Primary',
            state: 'filled',
            itemName: 'Seed Primary',
          ),
        ],
      );
      await fiStore.saveBuildPlan(priorPlan);
      await optStore.saveBuildRecord(
        OptimizedBuildRecord(
          buildId: b.id,
          isOptimized: true,
          resultIndexOneBased: 7,
          slots: const [
            OptimizedArmorSlot(
              slotWire: 'helmet',
              pieceName: 'Seed Helm',
              setId: 'seed',
              isExotic: false,
            ),
          ],
          stats: const [],
          setBonuses: const [],
        ),
      );
      final fillBeforeABytes =
          await File(root.fillInMissingByBuildPath).readAsBytes();
      final optBeforeABytes =
          await File(root.optimizeByBuildPath).readAsBytes();

      final c = BuildsOptimizeController(
        loadArmorItems: () async => syntheticArmor(),
        optimizeRunner: fakeResponse,
        optimizeStore: optStore,
        fillInStore: fiStore,
      );
      await c.refreshArmorCsv();

      // Apply A — undoable.
      final appliedA = await c.runOptimize(
        build: b,
        mode: BuildsOptimizeMode.autoApplyFirst,
      );
      expect(appliedA, isNotNull);
      expect(c.canUndo, isTrue);
      expect(c.appliedResultIndex, 1);
      final fillAfterABytes =
          await File(root.fillInMissingByBuildPath).readAsBytes();
      final optAfterABytes =
          await File(root.optimizeByBuildPath).readAsBytes();
      expect(fillAfterABytes, isNot(fillBeforeABytes));
      expect(optAfterABytes, isNot(optBeforeABytes));

      // Apply B — second store load fails; must not clobber A's undo priors.
      final appliedB = await c.runOptimize(
        build: appliedA!,
        mode: BuildsOptimizeMode.autoApplyFirst,
      );
      expect(appliedB, isNull);
      expect(c.error, isNotNull);
      expect(c.canUndo, isTrue);
      // Failed B must keep appliedResultIndex from A (loads never succeeded).
      expect(c.appliedResultIndex, 1);
      // Failed B must not have rewritten stores past A's apply.
      expect(
        await File(root.fillInMissingByBuildPath).readAsBytes(),
        fillAfterABytes,
      );
      expect(
        await File(root.optimizeByBuildPath).readAsBytes(),
        optAfterABytes,
      );

      // Undo restores A's prior file state exactly (raw bytes).
      final restored = await c.undoLastApply();
      expect(restored, isNotNull);
      expect(c.canUndo, isFalse);
      expect(c.appliedResultIndex, isNull);
      expect(
        await File(root.fillInMissingByBuildPath).readAsBytes(),
        fillBeforeABytes,
      );
      expect(
        await File(root.optimizeByBuildPath).readAsBytes(),
        optBeforeABytes,
      );
      final restoredPlan = await fiStore.loadForBuild(b.id);
      expect(restoredPlan!.applied.single.label, 'Seed Primary');
      final restoredOpt = await OptimizeBuildStore(root: root).loadForBuild(b.id);
      expect(restoredOpt!.resultIndexOneBased, 7);
      expect(restoredOpt.slots.single.pieceName, 'Seed Helm');
    },
  );

  test(
    'armor auto-apply then weapon merge then Undo restores both store files',
    () async {
      final temp = await Directory.systemTemp.createTemp('opt_fill_in_path_');
      addTearDown(() async {
        if (await temp.exists()) await temp.delete(recursive: true);
      });
      final root = StorageRoot(basePath: temp.path);
      final optStore = OptimizeBuildStore(root: root);
      final fiStore = FillInMissingListStore(root: root);
      final b = build();

      final priorPlan = FillInSavedBuildPlan(
        buildId: b.id,
        missing: const [],
        applied: const [
          FillInAppliedSlot(
            slotWire: 'primary',
            label: 'Pre Primary',
            originalLabel: '',
            instanceId: 'pre-w',
            itemHash: 55,
          ),
        ],
        rows: const [
          FillInSavedSlotRow(
            slotWire: 'primary',
            slotLabel: 'Primary',
            state: 'filled',
            itemName: 'Pre Primary',
          ),
        ],
      );
      await fiStore.saveBuildPlan(priorPlan);
      final fillBeforeBytes =
          await File(root.fillInMissingByBuildPath).readAsBytes();
      final optExistsBefore = File(root.optimizeByBuildPath).existsSync();
      final optBeforeBytes = optExistsBefore
          ? await File(root.optimizeByBuildPath).readAsBytes()
          : null;

      final c = BuildsOptimizeController(
        loadArmorItems: () async => syntheticArmor(),
        optimizeRunner: fakeResponse,
        optimizeStore: optStore,
        fillInStore: fiStore,
      );
      await c.refreshArmorCsv();

      // Armor auto-apply (Fill In path step 1).
      final armorApplied = await c.runOptimize(
        build: b,
        mode: BuildsOptimizeMode.autoApplyFirst,
      );
      expect(armorApplied, isNotNull);
      expect(c.canUndo, isTrue);
      expect(c.appliedResultIndex, 1);

      // Weapon auto-apply merge (Fill In path step 2) — merge plan without
      // touching armor pins; persist via the same controller Undo snapshot.
      final weaponPlan = FillInSavedBuildPlan(
        buildId: b.id,
        missing: const [],
        applied: [
          ...?((await fiStore.loadForBuild(b.id))?.applied),
          const FillInAppliedSlot(
            slotWire: 'special',
            label: 'Filled Special',
            originalLabel: '',
            instanceId: 'sp-1',
            itemHash: 99,
          ),
        ],
        rows: [
          ...?((await fiStore.loadForBuild(b.id))?.rows),
          const FillInSavedSlotRow(
            slotWire: 'special',
            slotLabel: 'Special',
            state: 'filled',
            itemName: 'Filled Special',
          ),
        ],
      );
      final persisted = await c.persistMergedFillInPlan(weaponPlan);
      expect(persisted, isTrue);
      final midPlan = await fiStore.loadForBuild(b.id);
      expect(
        midPlan!.applied.any((a) => a.label == 'Filled Special'),
        isTrue,
      );

      // (b) Undo restores both store files to exact pre-apply raw bytes.
      await c.undoLastApply();
      expect(
        await File(root.fillInMissingByBuildPath).readAsBytes(),
        fillBeforeBytes,
      );
      if (optBeforeBytes == null) {
        expect(await optStore.loadForBuild(b.id), isNull);
      } else {
        expect(
          await File(root.optimizeByBuildPath).readAsBytes(),
          optBeforeBytes,
        );
      }
      final restoredPlan = await fiStore.loadForBuild(b.id);
      expect(restoredPlan!.applied.single.label, 'Pre Primary');
    },
  );

  test(
    '(b) weapon optimize apply then Undo restores prior store file bytes',
    () async {
      final temp = await Directory.systemTemp.createTemp('opt_weapon_undo_');
      addTearDown(() async {
        if (await temp.exists()) await temp.delete(recursive: true);
      });
      final root = StorageRoot(basePath: temp.path);
      final fiStore = FillInMissingListStore(root: root);
      final optStore = OptimizeBuildStore(root: root);
      final b = build();
      final priorPlan = FillInSavedBuildPlan(
        buildId: b.id,
        missing: const [],
        applied: const [
          FillInAppliedSlot(
            slotWire: 'helmet',
            label: 'Prior Helm',
            originalLabel: '',
            instanceId: 'h1',
            itemHash: 1,
          ),
        ],
      );
      await fiStore.saveBuildPlan(priorPlan);
      final fillBeforeBytes =
          await File(root.fillInMissingByBuildPath).readAsBytes();

      final c = BuildsOptimizeController(
        loadArmorItems: () async => syntheticArmor(),
        loadWeaponItems: () async => const [
          FillInInventoryItem(
            instanceId: 'wk1',
            itemHash: 201,
            name: 'Kinetic Scout',
            slot: EquipmentSlot.primary,
            isExotic: false,
            weaponType: 'Scout Rifle',
            damageType: 'Kinetic',
          ),
          FillInInventoryItem(
            instanceId: 'we1',
            itemHash: 202,
            name: 'Energy Fusion',
            slot: EquipmentSlot.special,
            isExotic: false,
            weaponType: 'Fusion Rifle',
            damageType: 'Solar',
          ),
          FillInInventoryItem(
            instanceId: 'wp1',
            itemHash: 203,
            name: 'Power Rocket',
            slot: EquipmentSlot.heavy,
            isExotic: false,
            weaponType: 'Rocket Launcher',
            damageType: 'Solar',
          ),
        ],
        optimizeRunner: fakeResponse,
        optimizeStore: optStore,
        fillInStore: fiStore,
      );
      await c.refreshArmorCsv();
      await c.refreshWeaponsCsv();
      expect(c.hasWeaponsCsv, isTrue);

      final armorApplied = await c.runOptimize(
        build: b,
        mode: BuildsOptimizeMode.autoApplyFirst,
      );
      expect(armorApplied, isNotNull);
      expect(c.canUndo, isTrue);

      await c.prepareWeaponResults(
        build: armorApplied!,
        existingPlan: await fiStore.loadForBuild(b.id),
        openPanel: true,
      );
      expect(c.weaponPanelOpen, isTrue);
      expect(c.weaponCombinations, isNotEmpty);
      expect(c.weaponCombinations.first.isOptimized, isTrue);

      final weaponApplied = await c.applySelectedWeaponResult(
        build: armorApplied,
        index: 0,
        existingPlan: await fiStore.loadForBuild(b.id),
      );
      expect(weaponApplied, isNotNull);
      expect(
        (await fiStore.loadForBuild(b.id))!.applied.any(
          (a) => a.slotWire == 'primary' || a.slotWire == 'special',
        ),
        isTrue,
      );

      await c.undoLastApply();
      expect(
        await File(root.fillInMissingByBuildPath).readAsBytes(),
        fillBeforeBytes,
      );
      expect(c.appliedResultIndex, isNull);
      expect(c.weaponPanelOpen, isFalse);
    },
  );

  test(
    '(d) no weapons CSV → substitute results; never saved as optimized',
    () async {
      final temp = await Directory.systemTemp.createTemp('opt_weapon_sub_');
      addTearDown(() async {
        if (await temp.exists()) await temp.delete(recursive: true);
      });
      final root = StorageRoot(basePath: temp.path);
      final fiStore = FillInMissingListStore(root: root);
      final b = build();

      final c = BuildsOptimizeController(
        loadArmorItems: () async => syntheticArmor(),
        loadWeaponItems: () async => null,
        optimizeRunner: fakeResponse,
        fillInStore: fiStore,
      );
      await c.refreshArmorCsv();
      await c.refreshWeaponsCsv();
      expect(c.hasWeaponsCsv, isFalse);
      expect(c.weaponsCsvReason, kWeaponOptimizeNoCsvReason);

      final armorApplied = await c.runOptimize(
        build: b,
        mode: BuildsOptimizeMode.autoApplyFirst,
      );
      expect(armorApplied, isNotNull);

      // Provide inventory for substitute picks without claiming CSV import.
      c.weaponItems; // touch getter
      final response = runWeaponOptimizeForBuild(
        build: armorApplied!,
        weaponInventory: const [
          FillInInventoryItem(
            instanceId: 'sub1',
            itemHash: 301,
            name: 'Sub Scout',
            slot: EquipmentSlot.primary,
            isExotic: false,
            weaponType: 'Scout Rifle',
            damageType: 'Kinetic',
          ),
        ],
        hasWeaponsCsv: false,
      );
      expect(response.combinations.single.isSubstitute, isTrue);
      expect(response.combinations.single.reason, kWeaponOptimizeNoCsvReason);

      final merged = applyWeaponOptimizeCombination(
        build: armorApplied,
        combination: response.combinations.single,
      );
      final ok = await c.persistMergedFillInPlan(merged.plan);
      expect(ok, isTrue);
      final plan = await fiStore.loadForBuild(b.id);
      expect(plan, isNotNull);
      for (final row in plan!.rows) {
        if (row.slotWire == 'primary') {
          expect(row.state, 'proposed');
        }
      }
      // Armor isOptimized may be true; substitute weapons are proposed only.
      expect(merged.build.isOptimized, armorApplied.isOptimized);
    },
  );
}

/// Optimize store that throws on the Nth [loadForBuild] (1-based).
class _FailOnNthOptimizeLoadStore extends OptimizeBuildStore {
  _FailOnNthOptimizeLoadStore({
    required super.root,
    required this.failOnLoadCall,
  });

  final int failOnLoadCall;
  int _loadCalls = 0;

  @override
  Future<OptimizedBuildRecord?> loadForBuild(String buildId) async {
    _loadCalls += 1;
    if (_loadCalls >= failOnLoadCall) {
      throw OptimizeBuildStoreException(
        'forced optimize load failure on call $_loadCalls',
      );
    }
    return super.loadForBuild(buildId);
  }
}
