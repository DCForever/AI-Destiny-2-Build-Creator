import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_fixture.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/optimize/weapon_optimize_apply.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MockBuild baseBuild() {
    final b = loadBuildsMockFixture().builds.first;
    // Ensure weapon combat slots are empty (fixture is armor-only slots).
    return b.copyWith(
      slots: [
        for (final s in b.slots)
          if (s.slot != 'primary' &&
              s.slot != 'special' &&
              s.slot != 'heavy')
            s,
      ],
    );
  }

  List<FillInInventoryItem> weapons() => [
        const FillInInventoryItem(
          instanceId: 'w-k1',
          itemHash: 101,
          name: 'Kinetic Scout',
          slot: EquipmentSlot.primary,
          isExotic: false,
          weaponType: 'Scout Rifle',
          damageType: 'Kinetic',
          perkTags: ['Rapid Hit'],
        ),
        const FillInInventoryItem(
          instanceId: 'w-e1',
          itemHash: 102,
          name: 'Energy Fusion',
          slot: EquipmentSlot.special,
          isExotic: false,
          weaponType: 'Fusion Rifle',
          damageType: 'Solar',
        ),
        const FillInInventoryItem(
          instanceId: 'w-p1',
          itemHash: 103,
          name: 'Power Rocket',
          slot: EquipmentSlot.heavy,
          isExotic: false,
          weaponType: 'Rocket Launcher',
          damageType: 'Solar',
        ),
      ];

  test(
    '(a) merge never overwrites pinned weapon slots; armor pins unchanged',
    () {
      final build = baseBuild();
      final prior = FillInSavedBuildPlan(
        buildId: build.id,
        missing: const [],
        applied: const [
          FillInAppliedSlot(
            slotWire: 'primary',
            label: 'Pinned Kinetic',
            originalLabel: '',
            instanceId: 'pin-k',
            itemHash: 999,
          ),
          FillInAppliedSlot(
            slotWire: 'helmet',
            label: 'Pinned Helm',
            originalLabel: '',
            instanceId: 'pin-h',
            itemHash: 888,
          ),
        ],
        rows: const [
          FillInSavedSlotRow(
            slotWire: 'primary',
            slotLabel: 'Kinetic',
            state: 'filled',
            itemName: 'Pinned Kinetic',
          ),
          FillInSavedSlotRow(
            slotWire: 'helmet',
            slotLabel: 'Helmet',
            state: 'filled',
            itemName: 'Pinned Helm',
          ),
        ],
      );

      final empty = emptyUnpinnedWeaponSlots(build: build, plan: prior);
      expect(empty, isNot(contains(EquipmentSlot.primary)));
      expect(empty, contains(EquipmentSlot.special));
      expect(empty, contains(EquipmentSlot.heavy));

      final response = runWeaponOptimizeForBuild(
        build: build,
        weaponInventory: weapons(),
        hasWeaponsCsv: true,
        plan: prior,
      );
      expect(response.combinations, isNotEmpty);
      final merged = applyWeaponOptimizeCombination(
        build: build,
        combination: response.combinations.first,
        existingPlan: prior,
      );

      final primaryPin = merged.plan.applied.firstWhere(
        (a) => a.slotWire == 'primary',
      );
      expect(primaryPin.label, 'Pinned Kinetic');
      expect(primaryPin.instanceId, 'pin-k');

      final helmPin = merged.plan.applied.firstWhere(
        (a) => a.slotWire == 'helmet',
      );
      expect(helmPin.label, 'Pinned Helm');
      expect(helmPin.instanceId, 'pin-h');

      expect(
        merged.plan.applied.any((a) => a.slotWire == 'special'),
        isTrue,
      );
    },
  );

  test('(c) stale CSV picks absent from cached inventory are dropped', () {
    final csv = weapons();
    final live = [
      csv[0],
      csv[1],
      // heavy missing from live cache
    ];
    final filtered = filterWeaponsPresentInCache(
      csvWeapons: csv,
      cachedInventory: live,
    );
    expect(filtered.map((e) => e.instanceId), ['w-k1', 'w-e1']);
    expect(filtered.any((e) => e.instanceId == 'w-p1'), isFalse);
  });

  test('(d) substitute kit never labeled optimized; reason set', () {
    final build = baseBuild();
    final response = runWeaponOptimizeForBuild(
      build: build,
      weaponInventory: weapons(),
      hasWeaponsCsv: false,
    );
    expect(response.combinations, hasLength(1));
    final combo = response.combinations.single;
    expect(combo.isSubstitute, isTrue);
    expect(combo.isOptimized, isFalse);
    expect(combo.reason, kWeaponOptimizeNoCsvReason);
    for (final p in combo.picks) {
      expect(p.sourceLabel, kWeaponOptimizeSubstituteLabel);
      expect(p.sourceLabel, isNot(kWeaponOptimizeOptimizedLabel));
    }

    final merged = applyWeaponOptimizeCombination(
      build: build,
      combination: combo,
      existingPlan: null,
    );
    // Build isOptimized flag unchanged by substitute.
    expect(merged.build.isOptimized, build.isOptimized);
    for (final row in merged.plan.rows) {
      if (row.slotWire == 'primary' ||
          row.slotWire == 'special' ||
          row.slotWire == 'heavy') {
        expect(row.state, 'proposed');
      }
    }
  });
}
