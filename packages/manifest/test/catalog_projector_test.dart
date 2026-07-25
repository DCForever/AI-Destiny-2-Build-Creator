import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:test/test.dart';

void main() {
  group('projectMvpStores', () {
    test('projects weapons and exotic armor with facet fields', () {
      final items = projectMvpStores(
        weapons: [
          const WeaponRecord(
            hash: 10,
            name: 'Test HC',
            searchName: 'test hc',
            slot: WeaponSlotName.kinetic,
            element: ElementName.kinetic,
            ammo: AmmoTypeName.primary,
            frame: 'Adaptive Frame',
            itemTypeName: 'Hand Cannon',
          ),
        ],
        exoticArmor: [
          const ExoticArmorRecord(
            hash: 20,
            name: 'Celestial Nighthawk',
            searchName: 'celestial nighthawk',
            classType: DestinyClassName.hunter,
            slot: ArmorSlotName.helmet,
            intrinsic: NamedDescription(
              name: 'Hawkeye Hack',
              description: 'Precision hits grant Super energy.',
            ),
            archetype: 'Specialist',
          ),
        ],
      );

      expect(items, hasLength(2));

      final weapon = items.firstWhere((i) => i.hash == 10);
      expect(weapon.slot, 'Kinetic');
      expect(weapon.element, 'Kinetic');
      expect(weapon.ammo, 'Primary');
      expect(weapon.itemTypeName, 'Hand Cannon');
      expect(weapon.isExotic, isFalse);
      expect(weapon.owned, isFalse);
      expect(weapon.ownedCount, 0);
      expect(weapon.sourceStore, 'weapons');

      final armor = items.firstWhere((i) => i.hash == 20);
      expect(armor.slot, 'Helmet');
      expect(armor.classType, 'Hunter');
      expect(armor.isExotic, isTrue);
      expect(armor.frame, 'Specialist');
      expect(armor.sourceStore, 'exotic-armor');
    });

    test('projects subclass pieces and mods', () {
      final items = projectMvpStores(
        aspects: [
          const AspectRecord(
            hash: 1,
            name: 'Touch of Thunder',
            searchName: 'touch of thunder',
            description: 'Improves Arc grenades.',
            classType: DestinyClassName.hunter,
            element: ElementName.arc,
            fragmentCapacity: 3,
          ),
        ],
        fragments: [
          const FragmentRecord(
            hash: 2,
            name: 'Spark of Beacons',
            searchName: 'spark of beacons',
            description: 'Blind on grenade.',
            element: ElementName.arc,
          ),
        ],
        abilities: [
          const AbilityRecord(
            hash: 3,
            name: 'Golden Gun',
            searchName: 'golden gun',
            description: 'Fire precise Solar shots.',
            kind: AbilityKind.superAbility,
            classType: DestinyClassName.hunter,
            element: ElementName.solar,
          ),
        ],
        mods: [
          const ModRecord(
            hash: 4,
            name: 'Powerful Friends',
            searchName: 'powerful friends',
            description: '+20 Mobility.',
            slotCategory: ModSlotCategory.helmet,
            energyCost: 4,
          ),
        ],
      );

      expect(items.map((i) => i.hash), [1, 2, 3, 4]);
      expect(items.every((i) => i.owned == false), isTrue);
      expect(items.firstWhere((i) => i.hash == 1).itemTypeName, 'Aspect');
      expect(items.firstWhere((i) => i.hash == 3).itemTypeName, 'super');
      expect(items.firstWhere((i) => i.hash == 4).slot, 'helmet');
    });
  });
}
