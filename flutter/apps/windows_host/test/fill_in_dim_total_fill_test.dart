import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/fill_in/fill_in_build_mapper.dart';
import 'package:destiny2_windows_host/fill_in/fill_in_cache_loader.dart';
import 'package:destiny2_windows_host/fill_in/fill_in_dialog.dart';
import 'package:destiny2_windows_host/fill_in/fill_in_labels.dart';
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
    // Matrix rows often omit slot meta — bucket must come from DIM / inventory.
    exoticWeaponSlot: null,
  );
}

/// Synthetic DIM loadout: exotic legs + exotic kinetic + legendary energy/power
/// + real class item. Uses plural Bungie bucket labels ("Kinetic Weapons").
CachedDimLoadout _swarmersDimLoadout() {
  return const CachedDimLoadout(
    shareId: 'syn-swarmers',
    name: 'Equipped 10/19/2026, 7:00:38 AM',
    classType: 2,
    items: [
      CachedDimItem(
        hash: 7101,
        name: 'Per Audacia Cover',
        itemType: 'Helmet',
        tier: 'Legendary',
      ),
      CachedDimItem(
        hash: 7102,
        name: 'Per Audacia Gloves',
        itemType: 'Gauntlets',
        tier: 'Legendary',
      ),
      CachedDimItem(
        hash: 7103,
        name: 'Per Audacia Robes',
        itemType: 'Chest Armor',
        tier: 'Legendary',
      ),
      CachedDimItem(
        hash: 7001,
        name: 'Swarmers',
        itemType: 'Leg Armor',
        tier: 'Exotic',
      ),
      CachedDimItem(
        hash: 7104,
        name: "Apostate's Blade Bond",
        itemType: 'Class Armor',
        tier: 'Legendary',
      ),
      CachedDimItem(
        hash: 8001,
        name: 'Barrow-Dyad',
        itemType: 'Kinetic Weapons',
        tier: 'Exotic',
      ),
      CachedDimItem(
        hash: 8002,
        name: 'Funnelweb',
        itemType: 'Energy Weapons',
        tier: 'Legendary',
      ),
      CachedDimItem(
        hash: 8003,
        name: 'Cataclysmic',
        itemType: 'Power Weapons',
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
      instanceId: 'helm-1',
      itemHash: 7201,
      name: 'AION Renewal Hood',
      slot: EquipmentSlot.helmet,
      isExotic: false,
      guardianClass: GuardianClass.warlock,
      armorSetHash: 42,
    ),
    FillInInventoryItem(
      instanceId: 'arms-1',
      itemHash: 7202,
      name: 'Aeon Soul',
      slot: EquipmentSlot.arms,
      isExotic: true,
      guardianClass: GuardianClass.warlock,
    ),
    FillInInventoryItem(
      instanceId: 'chest-1',
      itemHash: 7203,
      name: "Apostate's Blade Robe",
      slot: EquipmentSlot.chest,
      isExotic: false,
      guardianClass: GuardianClass.warlock,
      armorSetHash: 43,
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
      instanceId: 'class-1',
      itemHash: 7104,
      name: "Apostate's Blade Bond",
      slot: EquipmentSlot.classItem,
      isExotic: false,
      guardianClass: GuardianClass.warlock,
      armorSetHash: 43,
    ),
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
      instanceId: 'ene-1',
      itemHash: 8002,
      name: 'Funnelweb',
      slot: EquipmentSlot.special,
      isExotic: false,
      weaponType: 'Submachine Gun',
      damageType: 'Void',
    ),
    FillInInventoryItem(
      instanceId: 'pow-1',
      itemHash: 8003,
      name: 'Cataclysmic',
      slot: EquipmentSlot.heavy,
      isExotic: false,
      weaponType: 'Linear Fusion Rifle',
      damageType: 'Solar',
    ),
    // Same-bucket similar candidate — must NOT surface while Barrow-Dyad is held.
    FillInInventoryItem(
      instanceId: 'kin-sim',
      itemHash: 8010,
      name: 'Qua Nilus II',
      slot: EquipmentSlot.primary,
      isExotic: false,
      weaponType: 'Sidearm',
      damageType: 'Strand',
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
    expect(enriched.exoticWeaponSlot, 'primary');
    expect(
      enriched.slots.any(
        (s) => s.pieceName == 'Swarmers' && s.slot == 'legs',
      ),
      isTrue,
    );
    expect(
      enriched.slots.any(
        (s) => s.pieceName == 'Barrow-Dyad' && s.slot == 'primary',
      ),
      isTrue,
    );
    expect(
      enriched.slots.any(
        (s) =>
            s.pieceName == "Apostate's Blade Bond" && s.slot == 'class_item',
      ),
      isTrue,
    );
    expect(
      enriched.slots.any(
        (s) => s.slot == 'class_item' && s.pieceName == 'Swarmers',
      ),
      isFalse,
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

    final bySlot = {
      for (final s in mapped.requirement.slots) s.slot: s,
    };
    expect(bySlot[EquipmentSlot.legs]?.isExotic, isTrue);
    expect(bySlot[EquipmentSlot.legs]?.exoticItemHash, 7001);
    expect(bySlot[EquipmentSlot.classItem]?.isExotic, isFalse);
    expect(bySlot[EquipmentSlot.primary]?.isExotic, isTrue);
    expect(bySlot[EquipmentSlot.primary]?.exoticItemHash, 8001);
    expect(bySlot[EquipmentSlot.special]?.isExotic, isFalse);
    expect(bySlot[EquipmentSlot.heavy]?.isExotic, isFalse);

    final report = matchFillIn(
      inventory: mapped.inventory,
      builds: [mapped.requirement],
    );
    expect(report.builds.single.solipsismFlag, FillInSolipsismFlag.none);
    expect(report.builds.single.slots, hasLength(8));
  });

  test('slot labels are Kinetic/Energy/Power; only exotic gets Exotic', () {
    expect(fillInSlotLabel(EquipmentSlot.primary), 'Kinetic');
    expect(fillInSlotLabel(EquipmentSlot.special), 'Energy');
    expect(fillInSlotLabel(EquipmentSlot.heavy), 'Power');
    expect(
      fillInSlotLabel(EquipmentSlot.primary, isExotic: true),
      'Exotic Kinetic',
    );
    expect(
      fillInSlotLabel(EquipmentSlot.special, isExotic: true),
      'Exotic Energy',
    );
    expect(
      fillInSlotLabel(EquipmentSlot.heavy, isExotic: true),
      'Exotic Power',
    );
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

    // Row assertions: Barrow-Dyad kinetic held; class item not Swarmers;
    // no wire placeholders; similar only if exotic kinetic missing.
    expect(find.text('Exotic Kinetic'), findsOneWidget);
    expect(find.text('Energy'), findsOneWidget);
    expect(find.text('Power'), findsOneWidget);
    expect(find.textContaining('Barrow-Dyad → held'), findsOneWidget);
    expect(find.textContaining('Swarmers → held'), findsOneWidget);
    expect(
      find.textContaining("Apostate's Blade Bond"),
      findsWidgets,
    );
    expect(find.textContaining('Swarmers →'), findsOneWidget);
    expect(
      find.byKey(const Key('fill_in_diff_text_class_item')),
      findsOneWidget,
    );
    final classText = tester
        .widget<Text>(find.byKey(const Key('fill_in_diff_text_class_item')))
        .data!;
    expect(classText.toLowerCase().contains('swarmers'), isFalse);
    expect(classText.contains("Apostate's Blade Bond"), isTrue);

    for (final wire in ['primary', 'special', 'heavy']) {
      expect(find.textContaining('$wire →'), findsNothing);
    }
    expect(find.textContaining(kFillInNoWeaponInDimLink), findsNothing);
    expect(find.byKey(const Key('fill_in_similar_weapon')), findsNothing);

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
    expect(updated!.exoticWeapon, isNot(kFillInNoWeaponInDimLink));
    expect(updated!.exoticWeapon, 'Barrow-Dyad');
    expect(updated!.exoticWeaponSlot, 'primary');
    expect(
      updated!.slots.any(
        (s) => s.slot == 'class_item' && s.pieceName == 'Swarmers',
      ),
      isFalse,
    );
    expect(
      updated!.slots
          .map((s) => s.pieceName.toLowerCase())
          .toSet()
          .intersection({'primary', 'special', 'heavy'}),
      isEmpty,
    );

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
