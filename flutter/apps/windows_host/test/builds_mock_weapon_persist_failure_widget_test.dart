import 'dart:io';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_fixture.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/optimize/builds_optimize_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Controller-level coverage for armor apply → unwritable Fill In store →
/// weapon apply returns null with Undo still available → Undo restores both
/// store files byte-for-byte.
///
/// Replaces the prior self-built widget shell that only asserted toast keys.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  Future<ArmorOptimizeResponse> fakeResponse(
    ArmorOptimizeRequest request,
  ) async {
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

  List<FillInInventoryItem> weapons() => const [
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
      ];

  test(
    'armor apply then unwritable Fill In store: weapon apply null, Undo restores bytes',
    () async {
      final temp = await Directory.systemTemp.createTemp('opt_unwritable_');
      addTearDown(() async {
        await Process.run('chmod', ['-R', 'u+w', temp.path]);
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
            slotWire: 'helmet',
            label: 'Prior Helm',
            originalLabel: '',
            instanceId: 'h0',
            itemHash: 9,
          ),
        ],
      );
      await fiStore.saveBuildPlan(priorPlan);

      final fillBeforeArmorBytes =
          await File(root.fillInMissingByBuildPath).readAsBytes();
      final optExistsBefore = File(root.optimizeByBuildPath).existsSync();
      final optBeforeArmorBytes = optExistsBefore
          ? await File(root.optimizeByBuildPath).readAsBytes()
          : null;

      final c = BuildsOptimizeController(
        loadArmorItems: () async => syntheticArmor(),
        loadWeaponItems: () async => weapons(),
        optimizeRunner: fakeResponse,
        optimizeStore: optStore,
        fillInStore: fiStore,
        knownSetKeys: const {'set:501'},
      );
      await c.refreshArmorCsv();
      await c.refreshWeaponsCsv();

      final armorApplied = await c.runOptimize(
        build: b,
        mode: BuildsOptimizeMode.autoApplyFirst,
      );
      expect(armorApplied, isNotNull);
      expect(c.canUndo, isTrue);

      // Make the Fill In store directory unwritable so weapon persist fails.
      final chmod = await Process.run('chmod', ['a-w', root.fillInCacheDir]);
      expect(chmod.exitCode, 0);

      await c.prepareWeaponResults(
        build: armorApplied!,
        existingPlan: await fiStore.loadForBuild(b.id),
        openPanel: false,
      );
      expect(c.weaponCombinations, isNotEmpty);

      final weaponApplied = await c.applySelectedWeaponResult(
        build: armorApplied,
        index: 0,
        existingPlan: await fiStore.loadForBuild(b.id),
      );
      expect(weaponApplied, isNull);
      expect(c.error, isNotNull);
      expect(c.error, isNotEmpty);
      expect(c.canUndo, isTrue);

      // Restore writability so Undo can rewrite store files.
      await Process.run('chmod', ['u+w', root.fillInCacheDir]);

      final restored = await c.undoLastApply();
      expect(restored, isNotNull);
      expect(c.canUndo, isFalse);

      expect(
        await File(root.fillInMissingByBuildPath).readAsBytes(),
        fillBeforeArmorBytes,
      );
      if (optBeforeArmorBytes == null) {
        expect(await optStore.loadForBuild(b.id), isNull);
      } else {
        expect(
          await File(root.optimizeByBuildPath).readAsBytes(),
          optBeforeArmorBytes,
        );
      }
    },
  );
}
