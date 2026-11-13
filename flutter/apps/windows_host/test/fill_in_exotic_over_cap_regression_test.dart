import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_models.dart';
import 'package:destiny2_windows_host/fill_in/fill_in_build_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression: held exotic armor on Gauntlets (Briarbinds) must not show
/// legendary-pool "3/2 More than 2 held, over cap" when 2+2 also covered arms.
void main() {
  test(
    '2+2 + exotic arms replaces legendary arms need (Briarbinds over-cap)',
    () {
      const briarbindsHash = 991001;
      const setA = 100;
      const setB = 200;

      final inventory = <FillInInventoryItem>[
        // Three Briarbinds copies — exotic pool must still never over-cap.
        for (var i = 0; i < 3; i++)
          FillInInventoryItem(
            instanceId: 'briar-$i',
            itemHash: briarbindsHash,
            name: 'Briarbinds',
            slot: EquipmentSlot.arms,
            isExotic: true,
            guardianClass: GuardianClass.warlock,
          ),
        // Legendary arms over-cap stack for set A (the false signal before fix).
        for (var i = 0; i < 3; i++)
          FillInInventoryItem(
            instanceId: 'leg-arms-$i',
            itemHash: 5000 + i,
            name: 'Techsec Gauntlets $i',
            slot: EquipmentSlot.arms,
            isExotic: false,
            guardianClass: GuardianClass.warlock,
            armorSetHash: setA,
          ),
        FillInInventoryItem(
          instanceId: 'a-h',
          itemHash: 5101,
          name: 'Techsec Cover',
          slot: EquipmentSlot.helmet,
          isExotic: false,
          guardianClass: GuardianClass.warlock,
          armorSetHash: setA,
        ),
        FillInInventoryItem(
          instanceId: 'a-c',
          itemHash: 5102,
          name: 'Techsec Plate',
          slot: EquipmentSlot.chest,
          isExotic: false,
          guardianClass: GuardianClass.warlock,
          armorSetHash: setA,
        ),
        FillInInventoryItem(
          instanceId: 'b-l',
          itemHash: 5201,
          name: 'Walk Boots',
          slot: EquipmentSlot.legs,
          isExotic: false,
          guardianClass: GuardianClass.warlock,
          armorSetHash: setB,
        ),
        FillInInventoryItem(
          instanceId: 'b-ci',
          itemHash: 5202,
          name: 'Walk Bond',
          slot: EquipmentSlot.classItem,
          isExotic: false,
          guardianClass: GuardianClass.warlock,
          armorSetHash: setB,
        ),
      ];

      const build = MockBuild(
        id: 'briarbinds_22',
        name: 'Briarbinds 2+2',
        subclass: 'Strand',
        exoticArmor: 'Briarbinds',
        exoticWeapon: '',
        slots: [
          MockSlotAssignment(
            slot: 'helmet',
            setId: 'set_techsec',
            pieceName: 'Techsec Cover',
          ),
          MockSlotAssignment(
            slot: 'arms',
            setId: 'exotic',
            pieceName: 'Briarbinds',
            isExoticSlot: true,
          ),
          MockSlotAssignment(
            slot: 'chest',
            setId: 'set_techsec',
            pieceName: 'Techsec Plate',
          ),
          MockSlotAssignment(
            slot: 'legs',
            setId: 'set_walk',
            pieceName: 'Walk Boots',
          ),
          MockSlotAssignment(
            slot: 'class_item',
            setId: 'set_walk',
            pieceName: 'Walk Bond',
          ),
        ],
        loop: 'loop',
        artifact: MockArtifact(name: '—', season: '—'),
        setBonuses: [],
        stats: [],
      );

      final mapped = mapMockBuildForFillIn(
        build: build,
        inventory: inventory,
        guardianClass: GuardianClass.warlock,
      );

      final armsNeeds = [
        for (final s in mapped.requirement.slots)
          if (s.slot == EquipmentSlot.arms) s,
      ];
      expect(armsNeeds, hasLength(1), reason: 'exactly one arms need');
      expect(armsNeeds.single.isExotic, isTrue);
      expect(armsNeeds.single.exoticItemHash, briarbindsHash);

      final report = matchFillIn(
        inventory: mapped.inventory,
        builds: [mapped.requirement],
        inventoryCap: 2,
      );
      final arms = report.builds.single.slots
          .where((s) => s.slot == EquipmentSlot.arms)
          .toList();
      expect(arms, hasLength(1));
      expect(arms.single.isHeld, isTrue);
      expect(arms.single.poolHeldCount, 3);
      expect(arms.single.exceedsCap, isFalse);
      expect(arms.single.overCapLabel, isNull);
    },
  );
}
