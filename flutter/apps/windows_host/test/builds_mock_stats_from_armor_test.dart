import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_stats_from_armor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MockBuild bare({
    List<MockSlotAssignment> slots = const [],
    List<MockStatTotal> stats = const [],
  }) {
    return MockBuild(
      id: 'b1',
      name: 'Source',
      subclass: 'Solar',
      exoticArmor: '',
      exoticWeapon: '',
      slots: slots,
      loop: '',
      artifact: const MockArtifact(name: '—', season: '—'),
      setBonuses: const [],
      stats: stats,
    );
  }

  FillInInventoryItem armor({
    required String id,
    required String name,
    required EquipmentSlot slot,
    required Map<ArmorStatName, int> stats,
    int hash = 100,
  }) {
    return FillInInventoryItem(
      instanceId: id,
      itemHash: hash,
      name: name,
      guardianClass: GuardianClass.warlock,
      slot: slot,
      isExotic: false,
      statValues: stats,
    );
  }

  test('sums six Armor 3.0 stats from CSV rows matched by name+slot', () {
    final build = bare(
      slots: const [
        MockSlotAssignment(slot: 'helmet', setId: 'a', pieceName: 'Helm A'),
        MockSlotAssignment(slot: 'arms', setId: 'a', pieceName: 'Arms A'),
        MockSlotAssignment(slot: 'chest', setId: 'a', pieceName: 'Chest A'),
        MockSlotAssignment(slot: 'legs', setId: 'a', pieceName: 'Legs A'),
        MockSlotAssignment(
          slot: 'class_item',
          setId: 'a',
          pieceName: 'Bond A',
        ),
      ],
    );
    final items = [
      armor(
        id: '1',
        name: 'Helm A',
        slot: EquipmentSlot.helmet,
        stats: const {
          ArmorStatName.weapons: 10,
          ArmorStatName.health: 20,
          ArmorStatName.classStat: 5,
          ArmorStatName.grenade: 1,
          ArmorStatName.superStat: 2,
          ArmorStatName.melee: 3,
        },
      ),
      armor(
        id: '2',
        name: 'Arms A',
        slot: EquipmentSlot.arms,
        stats: const {
          ArmorStatName.weapons: 1,
          ArmorStatName.health: 1,
          ArmorStatName.classStat: 1,
          ArmorStatName.grenade: 1,
          ArmorStatName.superStat: 1,
          ArmorStatName.melee: 1,
        },
      ),
      armor(
        id: '3',
        name: 'Chest A',
        slot: EquipmentSlot.chest,
        stats: const {
          ArmorStatName.weapons: 1,
          ArmorStatName.health: 1,
          ArmorStatName.classStat: 1,
          ArmorStatName.grenade: 1,
          ArmorStatName.superStat: 1,
          ArmorStatName.melee: 1,
        },
      ),
      armor(
        id: '4',
        name: 'Legs A',
        slot: EquipmentSlot.legs,
        stats: const {
          ArmorStatName.weapons: 1,
          ArmorStatName.health: 1,
          ArmorStatName.classStat: 1,
          ArmorStatName.grenade: 1,
          ArmorStatName.superStat: 1,
          ArmorStatName.melee: 1,
        },
      ),
      armor(
        id: '5',
        name: 'Bond A',
        slot: EquipmentSlot.classItem,
        stats: const {
          ArmorStatName.weapons: 1,
          ArmorStatName.health: 1,
          ArmorStatName.classStat: 1,
          ArmorStatName.grenade: 1,
          ArmorStatName.superStat: 1,
          ArmorStatName.melee: 1,
        },
      ),
    ];

    final resolved = resolveBuildsMockStats(build: build, armorItems: items);
    expect(resolved.isAvailable, isTrue);
    expect(resolved.unavailableReason, isNull);
    expect(resolved.stats, hasLength(6));
    final byId = {for (final s in resolved.stats) s.id: s.value};
    expect(byId[MockStatId.weapons], 14);
    expect(byId[MockStatId.health], 24);
    expect(byId[MockStatId.classAbility], 9);
    expect(byId[MockStatId.grenade], 5);
    expect(byId[MockStatId.superAbility], 6);
    expect(byId[MockStatId.melee], 7);
  });

  test('prefers existing build.stats over CSV recompute', () {
    final build = bare(
      slots: const [
        MockSlotAssignment(slot: 'helmet', setId: 'a', pieceName: 'Helm A'),
      ],
      stats: const [MockStatTotal(id: MockStatId.health, value: 99)],
    );
    final resolved = resolveBuildsMockStats(
      build: build,
      armorItems: [
        armor(
          id: '1',
          name: 'Helm A',
          slot: EquipmentSlot.helmet,
          stats: const {ArmorStatName.health: 1},
        ),
      ],
    );
    expect(resolved.stats.single.value, 99);
  });

  test('specific reason when CSV missing', () {
    final build = bare(
      slots: const [
        MockSlotAssignment(slot: 'helmet', setId: 'a', pieceName: 'Helm A'),
      ],
    );
    final resolved = resolveBuildsMockStats(build: build, armorItems: const []);
    expect(resolved.isAvailable, isFalse);
    expect(
      resolved.unavailableReason,
      contains('Import a DIM Armor CSV'),
    );
  });

  test('matches Fill In plan instance id before name', () {
    final build = bare(
      slots: const [
        MockSlotAssignment(slot: 'helmet', setId: 'a', pieceName: 'Wrong Name'),
      ],
    );
    final plan = FillInSavedBuildPlan(
      buildId: 'b1',
      missing: const [],
      applied: const [
        FillInAppliedSlot(
          slotWire: 'helmet',
          label: 'Helm Real',
          originalLabel: '',
          instanceId: 'inst-9',
          itemHash: 9,
        ),
      ],
    );
    final resolved = resolveBuildsMockStats(
      build: build,
      fillInPlan: plan,
      armorItems: [
        armor(
          id: 'inst-9',
          name: 'Helm Real',
          slot: EquipmentSlot.helmet,
          hash: 9,
          stats: const {ArmorStatName.weapons: 40},
        ),
      ],
    );
    expect(
      resolved.stats.singleWhere((s) => s.id == MockStatId.weapons).value,
      40,
    );
  });
}
