import 'dart:math';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/fill_in/fill_in_cache_loader.dart';
import 'package:destiny2_windows_host/fill_in/fill_in_weapon_apply.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FillInInventoryItem weapon({
    required String id,
    required String name,
    required EquipmentSlot slot,
    int hash = 1,
    bool exotic = false,
  }) {
    return FillInInventoryItem(
      instanceId: id,
      itemHash: hash,
      name: name,
      guardianClass: GuardianClass.warlock,
      slot: slot,
      isExotic: exotic,
    );
  }

  test('keeps saved Fill In weapon pins across weapon pass re-rolls', () async {
    const build = MockBuild(
      id: 'b1',
      name: 'Source',
      subclass: 'Strand',
      exoticArmor: 'Swarmers',
      exoticWeapon: '',
      slots: [
        MockSlotAssignment(
          slot: 'helmet',
          setId: 'a',
          pieceName: 'Helm',
          filledIn: true,
        ),
        MockSlotAssignment(
          slot: 'arms',
          setId: 'a',
          pieceName: 'Arms',
          filledIn: true,
        ),
        MockSlotAssignment(
          slot: 'chest',
          setId: 'a',
          pieceName: 'Chest',
          filledIn: true,
        ),
        MockSlotAssignment(
          slot: 'legs',
          setId: 'exotic',
          pieceName: 'Swarmers',
          isExoticSlot: true,
          filledIn: true,
        ),
        MockSlotAssignment(
          slot: 'class_item',
          setId: 'a',
          pieceName: 'Bond',
          filledIn: true,
        ),
        MockSlotAssignment(
          slot: 'primary',
          setId: 'weapon',
          pieceName: '',
        ),
        MockSlotAssignment(
          slot: 'special',
          setId: 'weapon',
          pieceName: '',
        ),
        MockSlotAssignment(
          slot: 'heavy',
          setId: 'weapon',
          pieceName: '',
        ),
      ],
      loop: '',
      artifact: MockArtifact(name: '—', season: '—'),
      setBonuses: [],
      stats: [],
    );

    final existing = FillInSavedBuildPlan(
      buildId: 'b1',
      missing: const [],
      applied: const [
        FillInAppliedSlot(
          slotWire: 'primary',
          label: 'Saved Primary',
          originalLabel: '',
          instanceId: 'wp-1',
          itemHash: 101,
        ),
      ],
      rows: const [
        FillInSavedSlotRow(
          slotWire: 'primary',
          slotLabel: 'Kinetic',
          state: 'filled',
          itemName: 'Saved Primary',
        ),
      ],
    );

    final inventory = [
      weapon(
        id: 'wp-1',
        name: 'Saved Primary',
        slot: EquipmentSlot.primary,
        hash: 101,
      ),
      weapon(
        id: 'wp-2',
        name: 'Other Primary',
        slot: EquipmentSlot.primary,
        hash: 102,
      ),
      weapon(
        id: 'ws-1',
        name: 'Energy A',
        slot: EquipmentSlot.special,
        hash: 201,
      ),
      weapon(
        id: 'wh-1',
        name: 'Power A',
        slot: EquipmentSlot.heavy,
        hash: 301,
      ),
    ];

    Future<FillInCacheLoadResult> loader() async =>
        FillInCacheLoadResult.ok(inventory);

    final first = await applyWeaponFillInAfterOptimize(
      build: build,
      loadCaches: loader,
      existingPlan: existing,
      random: Random(1),
    );
    final second = await applyWeaponFillInAfterOptimize(
      build: build,
      loadCaches: loader,
      existingPlan: existing,
      random: Random(99),
    );

    expect(first, isNotNull);
    expect(second, isNotNull);
    String? primaryLabel(WeaponFillInApplyResult r) {
      for (final a in r.plan.applied) {
        if (a.slotWire == 'primary') return a.label;
      }
      return null;
    }

    expect(primaryLabel(first!), 'Saved Primary');
    expect(primaryLabel(second!), 'Saved Primary');
  });
}
