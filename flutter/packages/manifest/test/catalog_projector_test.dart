import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:test/test.dart';

void main() {
  group('projectMvpStores', () {
    test('projects weapons, exotic weapons, exotic + legendary armor', () {
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
        exoticWeapons: [
          const ExoticWeaponRecord(
            hash: 15,
            name: 'Gjallarhorn',
            searchName: 'gjallarhorn',
            slot: WeaponSlotName.power,
            element: ElementName.solar,
            ammo: AmmoTypeName.heavy,
            frame: 'Wolfpack Rounds',
            intrinsic: NamedDescription(
              name: 'Wolfpack Rounds',
              description: 'Cluster missiles.',
            ),
            itemTypeName: 'Rocket Launcher',
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
        legendaryArmor: [
          const LegendaryArmorRecord(
            hash: 25,
            name: 'Arms of Optimacy',
            searchName: 'arms of optimacy',
            classType: DestinyClassName.titan,
            slot: ArmorSlotName.gauntlets,
            archetype: 'Brawler',
          ),
        ],
      );

      expect(items, hasLength(4));

      final weapon = items.firstWhere((i) => i.hash == 10);
      expect(weapon.slot, 'Kinetic');
      expect(weapon.element, 'Kinetic');
      expect(weapon.ammo, 'Primary');
      expect(weapon.itemTypeName, 'Hand Cannon');
      expect(weapon.isExotic, isFalse);
      expect(weapon.owned, isFalse);
      expect(weapon.ownedCount, 0);
      expect(weapon.sourceStore, 'weapons');

      final exoWeapon = items.firstWhere((i) => i.hash == 15);
      expect(exoWeapon.isExotic, isTrue);
      expect(exoWeapon.slot, 'Power');
      expect(exoWeapon.sourceStore, 'exotic-weapons');
      expect(exoWeapon.intrinsicName, 'Wolfpack Rounds');
      expect(exoWeapon.description, 'Cluster missiles.');
      // Catalyst null when record has none — never invent.
      expect(exoWeapon.catalystName, isNull);

      final armor = items.firstWhere((i) => i.hash == 20);
      expect(armor.slot, 'Helmet');
      expect(armor.classType, 'Hunter');
      expect(armor.isExotic, isTrue);
      expect(armor.frame, 'Specialist');
      expect(armor.sourceStore, 'exotic-armor');

      final legendArmor = items.firstWhere((i) => i.hash == 25);
      expect(legendArmor.isExotic, isFalse);
      expect(legendArmor.classType, 'Titan');
      expect(legendArmor.slot, 'Gauntlets');
      expect(legendArmor.sourceStore, 'legendary-armor');
    });

    test('exotic projector maps intrinsicName + catalyst fields without invent',
        () {
      final items = projectMvpStores(
        exoticWeapons: [
          const ExoticWeaponRecord(
            hash: 77,
            name: 'Gjallarhorn',
            searchName: 'gjallarhorn',
            slot: WeaponSlotName.power,
            element: ElementName.solar,
            ammo: AmmoTypeName.heavy,
            frame: 'Exotic',
            intrinsic: NamedDescription(
              name: 'Wolfpack Rounds',
              description: 'Rockets spawn seekers.',
            ),
            catalyst: NamedDescription(
              name: 'Gjallarhorn Catalyst',
              description: 'More wolfpack.',
            ),
            itemTypeName: 'Rocket Launcher',
          ),
        ],
      );
      final exo = items.single;
      expect(exo.intrinsicName, 'Wolfpack Rounds');
      expect(exo.catalystName, 'Gjallarhorn Catalyst');
      expect(exo.catalystDescription, 'More wolfpack.');
    });

    test('dedupes weapons and exoticWeapons by hash preferring exotic', () {
      // BUG-20260726-002: overlapping store rows must not double the board.
      final items = projectMvpStores(
        weapons: [
          const WeaponRecord(
            hash: 999,
            name: '1000 Yard Stare',
            searchName: '1000 yard stare',
            slot: WeaponSlotName.energy,
            element: ElementName.voidElement,
            ammo: AmmoTypeName.special,
            frame: 'Adaptive Frame',
            itemTypeName: 'Sniper Rifle',
          ),
        ],
        exoticWeapons: [
          const ExoticWeaponRecord(
            hash: 999,
            name: '1000 Yard Stare',
            searchName: '1000 yard stare',
            slot: WeaponSlotName.energy,
            element: ElementName.voidElement,
            ammo: AmmoTypeName.special,
            frame: 'Adaptive Frame',
            intrinsic: NamedDescription(
              name: 'Intrinsic',
              description: 'Exotic path description.',
            ),
            itemTypeName: 'Sniper Rifle',
          ),
        ],
      );

      expect(items.where((i) => i.hash == 999), hasLength(1));
      final row = items.singleWhere((i) => i.hash == 999);
      expect(row.isExotic, isTrue);
      expect(row.sourceStore, 'exotic-weapons');
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

      expect(items.map((i) => i.hash), unorderedEquals([1, 2, 3, 4]));
      expect(items.every((i) => i.owned == false), isTrue);
      expect(items.firstWhere((i) => i.hash == 1).itemTypeName, 'Aspect');
      expect(items.firstWhere((i) => i.hash == 3).itemTypeName, 'super');
      expect(items.firstWhere((i) => i.hash == 4).slot, 'helmet');
    });
  });
}
