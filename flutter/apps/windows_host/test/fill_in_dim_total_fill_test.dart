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
    expect(
      fillInMissingSlotLabel(
        slot: EquipmentSlot.exoticArmor,
        exoticArmorName: 'Swarmers',
      ),
      'Exotic armor (slot unknown): Swarmers',
    );
  });

  test('unowned summary-only Swarmers is missing; build not complete', () {
    const loadout = CachedDimLoadout(
      shareId: 'syn-swarmers-summary',
      name: 'Summary only',
      classType: 2,
      items: [],
      subclassPlugs: [],
      mods: [],
      artifactPerks: [],
      exotic: CachedDimExotic(
        hash: 7001,
        name: 'Swarmers',
        description: '',
      ),
    );
    final mapped = mapMockBuildForFillIn(
      build: const MockBuild(
        id: 'matrix_summary',
        name: 'Summary Swarmers',
        subclass: 'Strand',
        exoticArmor: '',
        exoticWeapon: '',
        slots: [],
        loop: 'loop',
        artifact: MockArtifact(name: '—', season: '—'),
        setBonuses: [],
        stats: [],
        dimLink: 'https://dim.gg/syn-swarmers-summary',
      ),
      inventory: const [],
      dimLoadout: loadout,
    );

    expect(mapped.requirement.exoticArmorName, 'Swarmers');
    final exoticNeed = mapped.requirement.slots.singleWhere(
      (s) => s.isExotic && s.slot == EquipmentSlot.exoticArmor,
    );
    expect(exoticNeed.exoticItemHash, 7001);
    expect(
      mapped.requirement.slots.any(
        (s) => s.isExotic && s.slot == EquipmentSlot.classItem,
      ),
      isFalse,
    );

    final report = matchFillIn(
      inventory: mapped.inventory,
      builds: [mapped.requirement],
    );
    final result = report.builds.single;
    final exoticMatch = result.slots.singleWhere(
      (s) => s.slot == EquipmentSlot.exoticArmor,
    );
    expect(exoticMatch.isHeld, isFalse);
    expect(result.slots.every((s) => s.isHeld), isFalse);

    final diffs = planFillInSubstitutes(
      match: result,
      requirement: mapped.requirement,
      inventory: mapped.inventory,
      currentLabels: const {EquipmentSlot.exoticArmor: 'Swarmers'},
    );
    final exoticDiff = diffs.singleWhere(
      (d) => d.slot == EquipmentSlot.exoticArmor,
    );
    expect(exoticDiff.isHeld, isFalse);
    expect(exoticDiff.wouldSubstitute, isFalse);
    expect(exoticDiff.substituteLabel, isNull);
    expect(
      fillInMissingSlotLabel(
        slot: EquipmentSlot.exoticArmor,
        exoticArmorName: 'Swarmers',
      ),
      'Exotic armor (slot unknown): Swarmers',
    );
  });

  test('unowned Swarmers with known legs slot is missing on Legs', () {
    const loadout = CachedDimLoadout(
      shareId: 'syn-swarmers-legs',
      name: 'Legs Swarmers',
      classType: 2,
      items: [
        CachedDimItem(
          hash: 7001,
          name: 'Swarmers',
          itemType: 'Leg Armor',
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
    final mapped = mapMockBuildForFillIn(
      build: const MockBuild(
        id: 'matrix_legs',
        name: 'Legs Swarmers',
        subclass: 'Strand',
        exoticArmor: '',
        exoticWeapon: '',
        slots: [],
        loop: 'loop',
        artifact: MockArtifact(name: '—', season: '—'),
        setBonuses: [],
        stats: [],
        dimLink: 'https://dim.gg/syn-swarmers-legs',
      ),
      // Legendary legs only — must never cover the exotic Swarmers need.
      inventory: const [
        FillInInventoryItem(
          instanceId: 'legs-leg',
          itemHash: 9999,
          name: 'Per Audacia Boots',
          slot: EquipmentSlot.legs,
          isExotic: false,
          guardianClass: GuardianClass.warlock,
          armorSetHash: 1,
        ),
      ],
      dimLoadout: loadout,
    );

    final legsNeed = mapped.requirement.slots.singleWhere(
      (s) => s.slot == EquipmentSlot.legs,
    );
    expect(legsNeed.isExotic, isTrue);
    expect(legsNeed.exoticItemHash, 7001);
    expect(
      mapped.requirement.slots.any((s) => s.slot == EquipmentSlot.exoticArmor),
      isFalse,
    );

    final report = matchFillIn(
      inventory: mapped.inventory,
      builds: [mapped.requirement],
    );
    final legsMatch = report.builds.single.slots.singleWhere(
      (s) => s.slot == EquipmentSlot.legs,
    );
    expect(legsMatch.isHeld, isFalse);

    final diffs = planFillInSubstitutes(
      match: report.builds.single,
      requirement: mapped.requirement,
      inventory: mapped.inventory,
      currentLabels: const {EquipmentSlot.legs: 'Swarmers'},
    );
    final legsDiff = diffs.singleWhere((d) => d.slot == EquipmentSlot.legs);
    expect(legsDiff.isHeld, isFalse);
    expect(legsDiff.substituteLabel, isNull);
    expect(legsDiff.wouldSubstitute, isFalse);
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
    expect(find.byKey(const Key('fill_in_section_armor')), findsOneWidget);
    expect(find.byKey(const Key('fill_in_section_weapons')), findsOneWidget);

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

  testWidgets('placeholders never reach saved applied labels or pieceName',
      (tester) async {
    FillInSavedBuildPlan? saved;
    MockBuild? updated;
    // Summary-only exotic + no weapon items → weapon rows display
    // "No weapon in DIM link"; Apply must not persist that or wire names.
    const loadout = CachedDimLoadout(
      shareId: 'syn-placeholder',
      name: 'Placeholder guard',
      classType: 2,
      items: [],
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
      id: 'matrix_ph',
      name: 'Placeholder',
      subclass: 'Strand',
      exoticArmor: '',
      exoticWeapon: 'Barrow-Dyad',
      slots: [],
      loop: 'loop',
      artifact: MockArtifact(name: '—', season: '—'),
      setBonuses: [],
      stats: [],
      dimLink: 'https://dim.gg/syn-placeholder',
    );

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
                    loadCaches: () async => FillInCacheLoadResult.ok(const []),
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

    expect(find.textContaining(kFillInNoWeaponInDimLink), findsWidgets);
    expect(
      find.textContaining('Exotic armor (slot unknown): Swarmers'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('fill_in_apply_to_build')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(saved, isNotNull);
    // Lowercase so toLowerCase() comparisons can actually fail (Skeptic).
    final banned = {
      kFillInNoWeaponInDimLink.toLowerCase(),
      'primary',
      'special',
      'heavy',
      'helmet',
      'arms',
      'chest',
      'legs',
      'class_item',
      'exotic_armor',
    };
    for (final row in saved!.applied) {
      expect(banned.contains(row.label.toLowerCase()), isFalse,
          reason: 'applied.label=${row.label}');
      expect(banned.contains(row.originalLabel.toLowerCase()), isFalse,
          reason: 'applied.originalLabel=${row.originalLabel}');
    }
    expect(updated, isNotNull);
    for (final slot in updated!.slots) {
      expect(banned.contains(slot.pieceName.toLowerCase()), isFalse,
          reason: 'pieceName=${slot.pieceName}');
      expect(slot.pieceName, isNot(kFillInNoWeaponInDimLink));
    }
    expect(updated!.exoticWeapon.toLowerCase(), isNot('primary'));
    expect(updated!.exoticWeapon.toLowerCase(), isNot('special'));
    expect(updated!.exoticWeapon.toLowerCase(), isNot('heavy'));
    expect(updated!.exoticWeapon, isNot(kFillInNoWeaponInDimLink));
  });

  testWidgets(
    'empty Energy/Power get same-bucket Similar picks; Apply writes weapons; Undo restores',
    (tester) async {
      MockBuild? updated;
      FillInSavedBuildPlan? saved;

      // Kinetic exotic held; Energy/Power absent from DIM + build.
      const loadout = CachedDimLoadout(
        shareId: 'syn-empty-weapons',
        name: 'Empty energy/power',
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
        id: 'matrix_empty_weps',
        name: 'Empty weapons',
        subclass: 'Strand',
        exoticArmor: '',
        exoticWeapon: 'Barrow-Dyad',
        slots: [],
        loop: 'loop',
        artifact: MockArtifact(name: '—', season: '—'),
        setBonuses: [],
        stats: [],
        dimLink: 'https://dim.gg/syn-empty-weapons',
      );
      final inventory = [
        ..._inventory(),
        // Ensure Energy/Power held copies exist for substitutes.
      ];

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
                          FillInCacheLoadResult.ok(inventory),
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

      expect(find.byKey(const Key('fill_in_section_armor')), findsOneWidget);
      expect(find.byKey(const Key('fill_in_section_weapons')), findsOneWidget);
      expect(find.textContaining('Barrow-Dyad → held'), findsOneWidget);
      expect(
        find.byKey(const Key('fill_in_similar_pick_special')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('fill_in_similar_pick_heavy')),
        findsOneWidget,
      );
      // Similar pick is labeled for its own slot — never "for Barrow-Dyad".
      expect(find.textContaining('(for Barrow-Dyad)'), findsNothing);
      expect(find.textContaining('Similar pick: Funnelweb'), findsOneWidget);
      expect(find.textContaining('Similar pick: Cataclysmic'), findsOneWidget);

      final beforeApply = enrichMockBuildFromDimLoadout(build, loadout: loadout);

      await tester.tap(find.byKey(const Key('fill_in_apply_to_build')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(saved, isNotNull);
      expect(saved!.applied, isNotEmpty);
      expect(
        saved!.applied.any((a) => a.label.trim().isEmpty),
        isFalse,
        reason: 'applied must never write empty names',
      );
      expect(updated, isNotNull);
      final energy = updated!.slots.where((s) => s.slot == 'special');
      final power = updated!.slots.where((s) => s.slot == 'heavy');
      expect(energy, isNotEmpty);
      expect(energy.first.pieceName, 'Funnelweb');
      expect(power, isNotEmpty);
      expect(power.first.pieceName, 'Cataclysmic');
      expect(updated!.exoticWeapon, 'Barrow-Dyad');
      // Structured rows: Kinetic held, Energy/Power filled.
      expect(saved!.rows, isNotEmpty);
      final kinRow = saved!.rows.singleWhere((r) => r.slotWire == 'primary');
      expect(kinRow.state, 'held');
      expect(kinRow.itemName, 'Barrow-Dyad');
      final eneRow = saved!.rows.singleWhere((r) => r.slotWire == 'special');
      expect(eneRow.state, 'filled');
      expect(eneRow.itemName, 'Funnelweb');

      await tester.tap(find.byKey(const Key('fill_in_undo')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(updated, isNotNull);
      expect(
        updated!.slots.map((s) => '${s.slot}:${s.pieceName}').toList()..sort(),
        beforeApply.slots.map((s) => '${s.slot}:${s.pieceName}').toList()
          ..sort(),
      );
      expect(updated!.exoticWeapon, beforeApply.exoticWeapon);
      expect(saved!.hasAppliedSubstitutes, isFalse);
    },
  );

  testWidgets(
    'empty exotic Kinetic substitute saves as proposed; Apply fills; Undo restores',
    (tester) async {
      FillInSavedBuildPlan? saved;
      MockBuild? updated;

      // Exotic Kinetic slot on the build with blank pieceName and no kinetic in
      // the DIM link → "No weapon in DIM link" + Similar pick Qua Nilus II.
      // Inventory must NOT also hold Barrow-Dyad (would mark the slot held).
      const loadout = CachedDimLoadout(
        shareId: 'syn-empty-exotic-kin',
        name: 'Empty exotic kinetic',
        classType: 2,
        items: [
          CachedDimItem(
            hash: 7001,
            name: 'Swarmers',
            itemType: 'Leg Armor',
            tier: 'Exotic',
          ),
          // No kinetic weapon in the DIM link.
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
        id: 'matrix_empty_ex_kin',
        name: 'Empty exotic kinetic',
        subclass: 'Strand',
        exoticArmor: '',
        exoticWeapon: '',
        slots: [
          MockSlotAssignment(
            slot: 'primary',
            setId: 'exotic_weapon',
            pieceName: '',
            isExoticSlot: true,
          ),
        ],
        loop: 'loop',
        artifact: MockArtifact(name: '—', season: '—'),
        setBonuses: [],
        stats: [],
        dimLink: 'https://dim.gg/syn-empty-exotic-kin',
      );
      final inventory = [
        const FillInInventoryItem(
          instanceId: 'qua-1',
          itemHash: 9101,
          name: 'Qua Nilus II',
          slot: EquipmentSlot.primary,
          isExotic: false,
          guardianClass: null,
          weaponType: 'Sidearm',
          damageType: 'Strand',
        ),
        const FillInInventoryItem(
          instanceId: 'legs-1',
          itemHash: 7001,
          name: 'Swarmers',
          slot: EquipmentSlot.legs,
          isExotic: true,
          guardianClass: GuardianClass.warlock,
        ),
      ];

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
                          FillInCacheLoadResult.ok(inventory),
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

      expect(find.textContaining(kFillInNoWeaponInDimLink), findsWidgets);
      expect(find.textContaining('Similar pick: Qua Nilus II'), findsOneWidget);
      expect(find.textContaining('Exotic Kinetic'), findsWidgets);

      await tester.tap(find.byKey(const Key('fill_in_save_missing')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(saved, isNotNull);
      final kinRow = saved!.rows.singleWhere((r) => r.slotWire == 'primary');
      expect(kinRow.state, 'proposed');
      expect(kinRow.itemName, 'Qua Nilus II');
      expect(kinRow.slotLabel, 'Exotic Kinetic');
      expect(
        saved!.rows.any(
          (r) =>
              r.slotWire == 'primary' &&
              r.state == 'missing' &&
              r.itemName.trim().isEmpty,
        ),
        isFalse,
      );

      final beforeApply = enrichMockBuildFromDimLoadout(build, loadout: loadout);

      await tester.tap(find.byKey(const Key('fill_in_apply_to_build')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(updated, isNotNull);
      final primary = updated!.slots.where((s) => s.slot == 'primary');
      expect(primary, isNotEmpty);
      expect(primary.first.pieceName, 'Qua Nilus II');
      expect(primary.first.filledIn, isTrue);
      expect(
        updated!.slots
            .where((s) => s.filledIn)
            .every((s) => s.pieceName.trim().isNotEmpty),
        isTrue,
      );
      final appliedRow =
          saved!.rows.singleWhere((r) => r.slotWire == 'primary');
      expect(appliedRow.state, 'filled');
      expect(saved!.hasAppliedSubstitutes, isTrue);

      await tester.tap(find.byKey(const Key('fill_in_undo')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(updated, isNotNull);
      expect(
        updated!.slots.map((s) => '${s.slot}:${s.pieceName}').toList()..sort(),
        beforeApply.slots.map((s) => '${s.slot}:${s.pieceName}').toList()
          ..sort(),
      );
      expect(saved!.hasAppliedSubstitutes, isFalse);
      final undoneRow =
          saved!.rows.singleWhere((r) => r.slotWire == 'primary');
      expect(undoneRow.state, 'proposed');
      expect(undoneRow.itemName, 'Qua Nilus II');
    },
  );

  testWidgets('Save missing list never writes empty names', (tester) async {
    FillInSavedBuildPlan? saved;
    const loadout = CachedDimLoadout(
      shareId: 'syn-save-blanks',
      name: 'Save blanks',
      classType: 2,
      items: [],
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
      id: 'matrix_save',
      name: 'Save',
      subclass: 'Strand',
      exoticArmor: '',
      exoticWeapon: '',
      slots: [],
      loop: 'loop',
      artifact: MockArtifact(name: '—', season: '—'),
      setBonuses: [],
      stats: [],
      dimLink: 'https://dim.gg/syn-save-blanks',
    );

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
                    loadCaches: () async => FillInCacheLoadResult.ok(const []),
                    saveMissingList: (plan) async => saved = plan,
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
    expect(saved!.missing.every((m) => m.trim().isNotEmpty), isTrue);
    expect(
      saved!.rows.every(
        (r) => r.state == 'missing' || r.itemName.trim().isNotEmpty,
      ),
      isTrue,
    );
    expect(saved!.updatedAt, isNotNull);
  });
}
