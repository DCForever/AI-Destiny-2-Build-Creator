import 'dart:math';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/fill_in/fill_in_cache_loader.dart';
import 'package:destiny2_windows_host/fill_in/fill_in_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_material_theme.dart';

/// Fixed-seed Save → Apply → Undo → reopen: proposed names must not re-roll.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const loadout = CachedDimLoadout(
    shareId: 'syn-undo-stable',
    name: 'Undo stability',
    classType: 2,
    items: [
      CachedDimItem(
        hash: 7001,
        name: 'Swarmers',
        itemType: 'Leg Armor',
        tier: 'Exotic',
      ),
      CachedDimItem(
        hash: 8001,
        name: 'Barrow-Dyad',
        itemType: 'Kinetic Weapons',
        tier: 'Exotic',
      ),
    ],
    subclassPlugs: [],
    mods: [],
    artifactPerks: [],
    exotic: CachedDimExotic(
      hash: 7001,
      name: 'Swarmers',
      description: '',
    ),
  );

  const build = MockBuild(
    id: 'undo_stable',
    name: 'Undo stable',
    subclass: 'Strand',
    exoticArmor: '',
    exoticWeapon: 'Barrow-Dyad',
    slots: [],
    loop: 'loop',
    artifact: MockArtifact(name: '—', season: '—'),
    setBonuses: [],
    stats: [],
    dimLink: 'https://dim.gg/syn-undo-stable',
  );

  /// Multiple Energy/Power options so a re-roll after Undo would change names.
  List<FillInInventoryItem> inventory() => const [
        FillInInventoryItem(
          instanceId: 'kin-1',
          itemHash: 8001,
          name: 'Barrow-Dyad',
          slot: EquipmentSlot.primary,
          isExotic: true,
          weaponType: 'Sidearm',
          damageType: 'Strand',
        ),
        FillInInventoryItem(
          instanceId: 'legs-1',
          itemHash: 7001,
          name: 'Swarmers',
          slot: EquipmentSlot.legs,
          isExotic: true,
          guardianClass: GuardianClass.warlock,
        ),
        FillInInventoryItem(
          instanceId: 'ene-a',
          itemHash: 9101,
          name: 'Funnelweb',
          slot: EquipmentSlot.special,
          isExotic: false,
          weaponType: 'Submachine Gun',
          damageType: 'Strand',
        ),
        FillInInventoryItem(
          instanceId: 'ene-b',
          itemHash: 9102,
          name: 'Calus Mini-Tool',
          slot: EquipmentSlot.special,
          isExotic: false,
          weaponType: 'Submachine Gun',
          damageType: 'Strand',
        ),
        FillInInventoryItem(
          instanceId: 'pow-a',
          itemHash: 9201,
          name: 'Cataclysmic',
          slot: EquipmentSlot.heavy,
          isExotic: false,
          weaponType: 'Linear Fusion Rifle',
          damageType: 'Strand',
        ),
        FillInInventoryItem(
          instanceId: 'pow-b',
          itemHash: 9202,
          name: 'Reed\'s Regret',
          slot: EquipmentSlot.heavy,
          isExotic: false,
          weaponType: 'Linear Fusion Rifle',
          damageType: 'Strand',
        ),
      ];

  Map<String, String> proposedByWire(FillInSavedBuildPlan plan) {
    return {
      for (final r in plan.rows)
        if (r.state == 'proposed' || r.state == 'filled')
          if (r.itemName.trim().isNotEmpty) r.slotWire: r.itemName.trim(),
    };
  }

  Future<void> openDialog(
    WidgetTester tester, {
    required Random random,
    required void Function(FillInSavedBuildPlan) onSave,
    void Function(MockBuild)? onBuildUpdated,
    FillInSavedBuildPlan? existingPlan,
    MockBuild? buildOverride,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: testMaterialTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                key: const Key('open_fill_in'),
                onPressed: () {
                  showFillInDialog(
                    context: context,
                    build: buildOverride ?? build,
                    dimLoadout: loadout,
                    loadCaches: () async =>
                        FillInCacheLoadResult.ok(inventory()),
                    saveMissingList: (plan) async => onSave(plan),
                    onBuildUpdated: onBuildUpdated,
                    existingPlan: existingPlan,
                    random: random,
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open_fill_in')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets(
    'Save → Apply → Undo → reopen keeps pre-Apply proposed names',
    (tester) async {
      FillInSavedBuildPlan? saved;
      MockBuild? updated;
      // Single advancing RNG: Undo rematch would re-roll without stabilize.
      final random = Random(42);

      await openDialog(
        tester,
        random: random,
        onSave: (plan) => saved = plan,
        onBuildUpdated: (b) => updated = b,
      );

      expect(find.byKey(const Key('fill_in_dialog_undo_stable')), findsOneWidget);
      expect(
        find.byKey(const Key('fill_in_similar_pick_special')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('fill_in_similar_pick_heavy')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('fill_in_save_missing')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(saved, isNotNull);
      final preApply = Map<String, String>.from(proposedByWire(saved!));
      expect(preApply.containsKey('special'), isTrue);
      expect(preApply.containsKey('heavy'), isTrue);
      final preEnergy = preApply['special']!;
      final prePower = preApply['heavy']!;

      await tester.tap(find.byKey(const Key('fill_in_apply_to_build')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(saved!.hasAppliedSubstitutes, isTrue);
      expect(proposedByWire(saved!)['special'], preEnergy);
      expect(proposedByWire(saved!)['heavy'], prePower);
      expect(updated, isNotNull);

      await tester.tap(find.byKey(const Key('fill_in_undo')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(saved!.hasAppliedSubstitutes, isFalse);
      final afterUndo = proposedByWire(saved!);
      expect(afterUndo['special'], preEnergy);
      expect(afterUndo['heavy'], prePower);
      // UI Similar picks match the stable proposed names.
      expect(find.textContaining('Similar pick: $preEnergy'), findsOneWidget);
      expect(find.textContaining('Similar pick: $prePower'), findsOneWidget);

      await tester.tap(find.byKey(const Key('fill_in_close')));
      await tester.pumpAndSettle();

      // Reopen with a different seed — stabilize must still win.
      await openDialog(
        tester,
        random: Random(99),
        onSave: (plan) => saved = plan,
        existingPlan: saved,
      );
      expect(find.textContaining('Similar pick: $preEnergy'), findsOneWidget);
      expect(find.textContaining('Similar pick: $prePower'), findsOneWidget);
      final reopened = proposedByWire(saved!);
      // Touch Save so rows refresh from current diffs.
      await tester.tap(find.byKey(const Key('fill_in_save_missing')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(proposedByWire(saved!)['special'], preEnergy);
      expect(proposedByWire(saved!)['heavy'], prePower);
      expect(reopened['special'] ?? preEnergy, preEnergy);
    },
  );

  testWidgets(
    'stabilize + exotic cap: saved exotic cannot leave a second exotic roll',
    (tester) async {
      // Saved proposed exotic on Energy; Kinetic empty can also roll exotic.
      // After rematch, at most one exotic weapon substitute remains.
      final existing = FillInSavedBuildPlan(
        buildId: 'two_ex',
        missing: const [],
        rows: const [
          FillInSavedSlotRow(
            slotWire: 'special',
            slotLabel: 'Energy',
            state: 'proposed',
            itemName: 'Riskrunner',
          ),
        ],
      );
      final inv = [
        const FillInInventoryItem(
          instanceId: 'ex-kin',
          itemHash: 501,
          name: 'Qua Nilus II',
          slot: EquipmentSlot.primary,
          isExotic: true,
          weaponType: 'Sidearm',
          damageType: 'Strand',
        ),
        const FillInInventoryItem(
          instanceId: 'ex-ene',
          itemHash: 502,
          name: 'Riskrunner',
          slot: EquipmentSlot.special,
          isExotic: true,
          weaponType: 'Submachine Gun',
          damageType: 'Arc',
        ),
        const FillInInventoryItem(
          instanceId: 'leg-kin',
          itemHash: 503,
          name: 'Funnelweb',
          slot: EquipmentSlot.primary,
          isExotic: false,
          weaponType: 'Submachine Gun',
          damageType: 'Void',
        ),
      ];
      const emptyBuild = MockBuild(
        id: 'two_ex',
        name: 'Two exotic risk',
        subclass: 'Strand',
        exoticArmor: '',
        exoticWeapon: '',
        slots: [],
        loop: 'loop',
        artifact: MockArtifact(name: '—', season: '—'),
        setBonuses: [],
        stats: [],
      );

      FillInSavedBuildPlan? saved;
      await tester.pumpWidget(
        MaterialApp(
          theme: testMaterialTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  key: const Key('open_fill_in'),
                  onPressed: () {
                    showFillInDialog(
                      context: context,
                      build: emptyBuild,
                      loadCaches: () async => FillInCacheLoadResult.ok(inv),
                      saveMissingList: (plan) async => saved = plan,
                      existingPlan: existing,
                      // Prefer exotic Kinetic when rolling fresh.
                      random: Random(1),
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open_fill_in')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byKey(const Key('fill_in_save_missing')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(saved, isNotNull);

      final exoticNames = <String>{};
      for (final row in saved!.rows) {
        if (row.state != 'proposed' && row.state != 'filled') continue;
        final name = row.itemName.trim();
        if (name == 'Riskrunner' || name == 'Qua Nilus II') {
          exoticNames.add(name);
        }
      }
      expect(
        exoticNames.length,
        lessThanOrEqualTo(1),
        reason: 'at most one exotic weapon after stabilize+cap: $exoticNames',
      );
      // Prefer the saved proposed exotic when demoting a fresh Kinetic exotic.
      expect(exoticNames, contains('Riskrunner'));
    },
  );
}
