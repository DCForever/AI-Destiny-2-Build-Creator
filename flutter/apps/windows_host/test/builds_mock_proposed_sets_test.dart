import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_proposed_sets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MockBuild bare({
    List<MockSetBonus> setBonuses = const [],
    List<MockSlotAssignment> slots = const [],
  }) {
    return MockBuild(
      id: 'b1',
      name: 'Test',
      subclass: 'Strand',
      exoticArmor: 'Swarmers',
      exoticWeapon: '',
      slots: slots,
      loop: '',
      artifact: const MockArtifact(name: '—', season: '—'),
      setBonuses: setBonuses,
      stats: const [],
    );
  }

  test('setBonuses 4pc → one 4pc goal', () {
    final build = bare(
      setBonuses: const [
        MockSetBonus(
          setId: 'Techsec',
          setName: 'Techsec',
          pieces: 2,
          tier: '2pc',
          text: '2pc text',
        ),
        MockSetBonus(
          setId: 'Techsec',
          setName: 'Techsec',
          pieces: 4,
          tier: '4pc',
          text: '4pc text',
        ),
      ],
    );
    final bonuses = proposedSetBonusesFor(build: build);
    expect(bonuses, hasLength(1));
    expect(bonuses.single.tier, '4pc');
    final goals = proposedSetBonusGoalsFor(build: build);
    expect(goals, [
      const SetBonusCoverageGoal(setBonusKey: 'Techsec', minPieces: 4),
    ]);
  });

  test('empty setBonuses + 2+2 slots → two 2pc goals', () {
    final build = bare(
      slots: const [
        MockSlotAssignment(slot: 'helmet', setId: 'Alpha', pieceName: 'H'),
        MockSlotAssignment(slot: 'arms', setId: 'Alpha', pieceName: 'A'),
        MockSlotAssignment(slot: 'chest', setId: 'Beta', pieceName: 'C'),
        MockSlotAssignment(slot: 'legs', setId: 'Beta', pieceName: 'L'),
        MockSlotAssignment(
          slot: 'class_item',
          setId: 'exotic',
          pieceName: 'Swarmers',
          isExoticSlot: true,
        ),
      ],
    );
    final bonuses = proposedSetBonusesFor(build: build);
    expect(bonuses.map((b) => b.setId).toSet(), {'Alpha', 'Beta'});
    expect(bonuses.every((b) => b.tier == '2pc'), isTrue);
    final goals = proposedSetBonusGoalsFor(build: build);
    expect(goals, hasLength(2));
    expect(goals.every((g) => g.minPieces == 2), isTrue);
  });

  test('no proposed sets → empty goals (regression)', () {
    final build = bare();
    expect(proposedSetBonusesFor(build: build), isEmpty);
    expect(proposedSetBonusGoalsFor(build: build), isEmpty);
  });

  test('Fill In proposed rows resolve set keys via inventory', () {
    final build = bare();
    final plan = FillInSavedBuildPlan(
      buildId: 'b1',
      missing: const [],
      rows: const [
        FillInSavedSlotRow(
          slotWire: 'helmet',
          slotLabel: 'Helmet',
          state: 'proposed',
          itemName: 'Techsec Helm',
        ),
        FillInSavedSlotRow(
          slotWire: 'arms',
          slotLabel: 'Gauntlets',
          state: 'proposed',
          itemName: 'Techsec Arms',
        ),
        FillInSavedSlotRow(
          slotWire: 'chest',
          slotLabel: 'Chest',
          state: 'proposed',
          itemName: 'Techsec Chest',
        ),
        FillInSavedSlotRow(
          slotWire: 'legs',
          slotLabel: 'Legs',
          state: 'proposed',
          itemName: 'Techsec Legs',
        ),
      ],
    );
    final named = [
      FillInInventoryItem(
        instanceId: 'i-h',
        itemHash: 1001,
        slot: EquipmentSlot.helmet,
        isExotic: false,
        guardianClass: GuardianClass.warlock,
        name: 'Techsec Helm',
        location: 'vault',
      ),
      FillInInventoryItem(
        instanceId: 'i-a',
        itemHash: 1002,
        slot: EquipmentSlot.arms,
        isExotic: false,
        guardianClass: GuardianClass.warlock,
        name: 'Techsec Arms',
        location: 'vault',
      ),
      FillInInventoryItem(
        instanceId: 'i-c',
        itemHash: 1003,
        slot: EquipmentSlot.chest,
        isExotic: false,
        guardianClass: GuardianClass.warlock,
        name: 'Techsec Chest',
        location: 'vault',
      ),
      FillInInventoryItem(
        instanceId: 'i-l',
        itemHash: 1004,
        slot: EquipmentSlot.legs,
        isExotic: false,
        guardianClass: GuardianClass.warlock,
        name: 'Techsec Legs',
        location: 'vault',
      ),
    ];
    final keyByHash = {
      for (final item in named) item.itemHash: 'Techsec',
    };
    final bonuses = proposedSetBonusesFor(
      build: build,
      plan: plan,
      armorItems: named,
      setBonusKeyByItemHash: keyByHash,
    );
    expect(bonuses, hasLength(1));
    expect(bonuses.single.tier, '4pc');
    expect(bonuses.single.setId, 'Techsec');
  });
}
