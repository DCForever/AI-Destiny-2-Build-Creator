import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/fill_in/fill_in_build_mapper.dart';
import 'package:destiny2_windows_host/fill_in/fill_in_cache_loader.dart';
import 'package:destiny2_windows_host/fill_in/fill_in_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_material_theme.dart';

MockBuild _matrixStyleBuild() {
  return const MockBuild(
    id: 'matrix_dim_01',
    name: 'Equipped 10/19/2026, 7:00:38 AM',
    subclass: 'Strand',
    exoticArmor: '',
    exoticWeapon: 'Barrow-Dyad',
    slots: [],
    loop: 'loop',
    artifact: MockArtifact(name: '—', season: '—'),
    setBonuses: [],
    stats: [],
    dimLink: 'https://dim.gg/syn-swarmers',
    exoticWeaponSlot: 'primary',
  );
}

CachedDimLoadout _swarmersDimLoadout() {
  return const CachedDimLoadout(
    shareId: 'syn-swarmers',
    name: 'Equipped 10/19/2026, 7:00:38 AM',
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
        itemType: 'Kinetic Weapon',
        tier: 'Exotic',
      ),
      CachedDimItem(
        hash: 8002,
        name: 'Funnelweb',
        itemType: 'Energy Weapon',
        tier: 'Legendary',
      ),
      CachedDimItem(
        hash: 8003,
        name: 'Cataclysmic',
        itemType: 'Power Weapon',
        tier: 'Legendary',
      ),
    ],
    subclassPlugs: [],
    mods: [],
    artifactPerks: [],
    exotic: CachedDimExotic(
      hash: 7001,
      name: 'Swarmers',
      description: 'Strand exotic legs',
    ),
  );
}

List<FillInInventoryItem> _inventory() {
  return const [
    FillInInventoryItem(
      instanceId: 'legs-1',
      itemHash: 7001,
      name: 'Swarmers',
      slot: EquipmentSlot.legs,
      isExotic: true,
      guardianClass: GuardianClass.warlock,
    ),
    FillInInventoryItem(
      instanceId: 'kin-1',
      itemHash: 8001,
      name: 'Barrow-Dyad',
      slot: EquipmentSlot.primary,
      isExotic: true,
    ),
    FillInInventoryItem(
      instanceId: 'ene-1',
      itemHash: 8002,
      name: 'Funnelweb',
      slot: EquipmentSlot.special,
      isExotic: false,
    ),
    FillInInventoryItem(
      instanceId: 'pow-1',
      itemHash: 8003,
      name: 'Cataclysmic',
      slot: EquipmentSlot.heavy,
      isExotic: false,
    ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('enrichMockBuildFromDimLoadout fills Swarmers exotic armor', () {
    final enriched = enrichMockBuildFromDimLoadout(
      _matrixStyleBuild(),
      loadout: _swarmersDimLoadout(),
    );
    expect(enriched.exoticArmor, 'Swarmers');
    expect(enriched.exoticWeapon, 'Barrow-Dyad');
    expect(
      enriched.slots.any(
        (s) => s.pieceName == 'Swarmers' && s.slot == 'legs',
      ),
      isTrue,
    );
  });

  test('DIM-loadout build maps to 8 total-fill slot requirements', () {
    final mapped = mapMockBuildForFillIn(
      build: _matrixStyleBuild(),
      inventory: _inventory(),
      dimLoadout: _swarmersDimLoadout(),
    );
    expect(mapped.requirement.exoticArmorName, 'Swarmers');
    expect(mapped.requirement.slots, hasLength(8));
    final slotSet = mapped.requirement.slots.map((s) => s.slot).toSet();
    expect(slotSet, {
      ...EquipmentSlot.armorSlots,
      ...EquipmentSlot.weaponSlots,
    });

    final report = matchFillIn(
      inventory: mapped.inventory,
      builds: [mapped.requirement],
    );
    expect(report.builds.single.solipsismFlag, FillInSolipsismFlag.none);
    expect(report.builds.single.slots, hasLength(8));
  });

  testWidgets('Apply to build stores all 8 total-fill slots', (tester) async {
    MockBuild? updated;
    FillInSavedBuildPlan? saved;
    final build = _matrixStyleBuild();
    final loadout = _swarmersDimLoadout();
    final original = enrichMockBuildFromDimLoadout(build, loadout: loadout);

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
                    build: build,
                    dimLoadout: loadout,
                    loadCaches: () async =>
                        FillInCacheLoadResult.ok(_inventory()),
                    saveMissingList: (plan) async => saved = plan,
                    onBuildUpdated: (b) => updated = b,
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

    expect(find.byKey(const Key('fill_in_solipsism_flag')), findsNothing);
    expect(find.byKey(const Key('fill_in_diff_legs')), findsOneWidget);
    expect(find.byKey(const Key('fill_in_diff_primary')), findsOneWidget);
    expect(find.byKey(const Key('fill_in_diff_special')), findsOneWidget);
    expect(find.byKey(const Key('fill_in_diff_heavy')), findsOneWidget);
    expect(find.byKey(const Key('fill_in_diff_helmet')), findsOneWidget);
    expect(find.byKey(const Key('fill_in_diff_arms')), findsOneWidget);
    expect(find.byKey(const Key('fill_in_diff_chest')), findsOneWidget);
    expect(find.byKey(const Key('fill_in_diff_class_item')), findsOneWidget);

    await tester.tap(find.byKey(const Key('fill_in_apply_to_build')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(saved, isNotNull);
    expect(saved!.applied, hasLength(8));
    expect(updated, isNotNull);
    expect(updated!.exoticArmor, 'Swarmers');
    expect(updated!.slots, hasLength(8));
    // Placeholder wire names must never become the exotic weapon.
    expect(updated!.exoticWeapon.toLowerCase(), isNot('heavy'));
    expect(updated!.exoticWeapon.toLowerCase(), isNot('primary'));
    expect(updated!.exoticWeapon.toLowerCase(), isNot('special'));
    expect(updated!.exoticWeapon, 'Barrow-Dyad');

    await tester.tap(find.byKey(const Key('fill_in_undo')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(updated, isNotNull);
    expect(updated!.exoticWeapon, original.exoticWeapon);
    expect(updated!.exoticWeaponSlot, original.exoticWeaponSlot);
    expect(updated!.exoticArmor, original.exoticArmor);
    expect(updated!.slots, hasLength(original.slots.length));
    expect(
      updated!.slots.map((s) => '${s.slot}:${s.pieceName}').toList()..sort(),
      original.slots.map((s) => '${s.slot}:${s.pieceName}').toList()..sort(),
    );
    expect(saved, isNotNull);
    expect(saved!.hasAppliedSubstitutes, isFalse);
    expect(saved!.applied, isEmpty);
  });
}
