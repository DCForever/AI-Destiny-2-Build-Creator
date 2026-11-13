import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('planFillInSubstitutes', () {
    test('held slot pins instance without substitute change', () {
      final inventory = [
        const FillInInventoryItem(
          instanceId: 'h1',
          itemHash: 10,
          name: 'Helmet A',
          slot: EquipmentSlot.helmet,
          isExotic: false,
          guardianClass: GuardianClass.warlock,
          armorSetHash: 100,
        ),
      ];
      final requirement = FillInBuildRequirement(
        buildId: 'b1',
        guardianClass: GuardianClass.warlock,
        subclassKey: 'prismatic',
        slots: const [
          FillInSlotRequirement(
            slot: EquipmentSlot.helmet,
            isExotic: false,
            armorSetHash: 100,
          ),
        ],
      );
      final match = matchFillIn(
        inventory: inventory,
        builds: [requirement],
      ).builds.single;

      final diffs = planFillInSubstitutes(
        match: match,
        requirement: requirement,
        inventory: inventory,
        currentLabels: const {EquipmentSlot.helmet: 'Helmet A'},
      );

      expect(diffs, hasLength(1));
      expect(diffs.single.isHeld, isTrue);
      expect(diffs.single.wouldSubstitute, isFalse);
      expect(diffs.single.heldInstanceId, 'h1');
      expect(diffs.single.applyInstanceId, 'h1');
    });

    test('missing weapon proposes similar substitute', () {
      final inventory = [
        const FillInInventoryItem(
          instanceId: 'w1',
          itemHash: 99,
          name: "Zaouli's Bane",
          slot: EquipmentSlot.special,
          isExotic: true,
          guardianClass: null,
          weaponType: 'Hand Cannon',
          damageType: 'Solar',
        ),
      ];
      final requirement = const FillInBuildRequirement(
        buildId: 'b1',
        guardianClass: GuardianClass.warlock,
        subclassKey: 'solar',
        slots: [
          FillInSlotRequirement(
            slot: EquipmentSlot.special,
            isExotic: true,
            exoticItemHash: 1,
          ),
        ],
      );
      final match = matchFillIn(
        inventory: inventory,
        builds: [requirement],
      ).builds.single;
      expect(match.slots.single.isHeld, isFalse);

      final diffs = planFillInSubstitutes(
        match: match,
        requirement: requirement,
        inventory: inventory,
        currentLabels: const {EquipmentSlot.special: 'Sunshot'},
        weaponNeed: const FillInWeaponNeed(
          name: 'Sunshot',
          slot: EquipmentSlot.special,
          weaponType: 'Hand Cannon',
          damageType: 'Solar',
        ),
      );

      expect(diffs.single.wouldSubstitute, isTrue);
      expect(diffs.single.substituteLabel, "Zaouli's Bane");
      expect(diffs.single.substituteInstanceId, 'w1');
      expect(diffs.single.isExotic, isTrue);
    });

    test('empty weapon current label is No weapon in DIM link not wire name', () {
      final inventory = <FillInInventoryItem>[];
      final requirement = const FillInBuildRequirement(
        buildId: 'b1',
        guardianClass: GuardianClass.warlock,
        subclassKey: 'strand',
        slots: [
          FillInSlotRequirement(
            slot: EquipmentSlot.primary,
            isExotic: true,
            exoticItemHash: 1,
          ),
          FillInSlotRequirement(
            slot: EquipmentSlot.heavy,
            isExotic: false,
          ),
        ],
      );
      final match = matchFillIn(
        inventory: inventory,
        builds: [requirement],
      ).builds.single;

      final diffs = planFillInSubstitutes(
        match: match,
        requirement: requirement,
        inventory: inventory,
        currentLabels: const {},
      );

      expect(diffs, hasLength(2));
      expect(
        diffs.map((d) => d.currentLabel).toSet(),
        {kFillInNoWeaponInDimLink},
      );
      expect(
        diffs.every((d) => !const {'primary', 'special', 'heavy'}
            .contains(d.currentLabel.toLowerCase())),
        isTrue,
      );
    });

    test('similar weapon only proposed for the need slot', () {
      final inventory = [
        const FillInInventoryItem(
          instanceId: 'w1',
          itemHash: 99,
          name: 'Qua Nilus II',
          slot: EquipmentSlot.primary,
          isExotic: false,
          guardianClass: null,
          weaponType: 'Sidearm',
          damageType: 'Strand',
        ),
      ];
      final requirement = const FillInBuildRequirement(
        buildId: 'b1',
        guardianClass: GuardianClass.warlock,
        subclassKey: 'strand',
        slots: [
          FillInSlotRequirement(
            slot: EquipmentSlot.primary,
            isExotic: true,
            exoticItemHash: 8001,
          ),
          FillInSlotRequirement(
            slot: EquipmentSlot.special,
            isExotic: false,
          ),
        ],
      );
      final match = matchFillIn(
        inventory: inventory,
        builds: [requirement],
      ).builds.single;

      final diffs = planFillInSubstitutes(
        match: match,
        requirement: requirement,
        inventory: inventory,
        currentLabels: const {
          EquipmentSlot.primary: 'Barrow-Dyad',
        },
        weaponNeed: const FillInWeaponNeed(
          name: 'Barrow-Dyad',
          slot: EquipmentSlot.primary,
          weaponType: 'Sidearm',
          damageType: 'Strand',
        ),
      );

      final primary = diffs.singleWhere((d) => d.slot == EquipmentSlot.primary);
      final energy = diffs.singleWhere((d) => d.slot == EquipmentSlot.special);
      expect(primary.substituteLabel, 'Qua Nilus II');
      expect(energy.substituteLabel, isNull);
      expect(energy.currentLabel, kFillInNoWeaponInDimLink);
    });

    test('empty armor current label is blank not helmet wire name', () {
      final requirement = const FillInBuildRequirement(
        buildId: 'b1',
        guardianClass: GuardianClass.warlock,
        subclassKey: 'strand',
        slots: [
          FillInSlotRequirement(
            slot: EquipmentSlot.helmet,
            isExotic: false,
          ),
        ],
      );
      final match = matchFillIn(
        inventory: const [],
        builds: [requirement],
      ).builds.single;
      final diffs = planFillInSubstitutes(
        match: match,
        requirement: requirement,
        inventory: const [],
        currentLabels: const {},
      );
      expect(diffs.single.currentLabel, isEmpty);
      expect(diffs.single.currentLabel.toLowerCase(), isNot('helmet'));
    });

    test('exotic armor never substitutes a legendary cover', () {
      final inventory = [
        const FillInInventoryItem(
          instanceId: 'legs-leg',
          itemHash: 9999,
          name: 'Per Audacia Boots',
          slot: EquipmentSlot.legs,
          isExotic: false,
          guardianClass: GuardianClass.warlock,
          armorSetHash: 1,
        ),
      ];
      final requirement = const FillInBuildRequirement(
        buildId: 'b1',
        guardianClass: GuardianClass.warlock,
        subclassKey: 'strand',
        exoticArmorName: 'Swarmers',
        slots: [
          FillInSlotRequirement(
            slot: EquipmentSlot.legs,
            isExotic: true,
            exoticItemHash: 7001,
          ),
        ],
      );
      final match = matchFillIn(
        inventory: inventory,
        builds: [requirement],
      ).builds.single;
      expect(match.slots.single.isHeld, isFalse);

      final diffs = planFillInSubstitutes(
        match: match,
        requirement: requirement,
        inventory: inventory,
        currentLabels: const {EquipmentSlot.legs: 'Swarmers'},
      );
      expect(diffs.single.substituteLabel, isNull);
      expect(diffs.single.wouldSubstitute, isFalse);
    });

    test('missing armor proposes same-slot held substitute', () {
      final inventory = [
        const FillInInventoryItem(
          instanceId: 'a1',
          itemHash: 5,
          name: 'Spare Arms',
          slot: EquipmentSlot.arms,
          isExotic: false,
          guardianClass: GuardianClass.warlock,
          armorSetHash: 200,
        ),
      ];
      final requirement = const FillInBuildRequirement(
        buildId: 'b1',
        guardianClass: GuardianClass.warlock,
        subclassKey: 'void',
        slots: [
          FillInSlotRequirement(
            slot: EquipmentSlot.arms,
            isExotic: false,
            armorSetHash: 100,
          ),
        ],
      );
      final match = matchFillIn(
        inventory: inventory,
        builds: [requirement],
      ).builds.single;

      final diffs = planFillInSubstitutes(
        match: match,
        requirement: requirement,
        inventory: inventory,
        currentLabels: const {EquipmentSlot.arms: 'Needed Arms'},
      );

      expect(diffs.single.wouldSubstitute, isTrue);
      expect(diffs.single.substituteLabel, 'Spare Arms');
      expect(diffs.single.substituteInstanceId, 'a1');
    });
  });
}
