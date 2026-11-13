import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('equipmentSlotFromDimItemType', () {
    test('maps armor and weapon bucket labels', () {
      expect(equipmentSlotFromDimItemType('Helmet'), EquipmentSlot.helmet);
      expect(equipmentSlotFromDimItemType('Gauntlets'), EquipmentSlot.arms);
      expect(equipmentSlotFromDimItemType('Chest Armor'), EquipmentSlot.chest);
      expect(equipmentSlotFromDimItemType('Leg Armor'), EquipmentSlot.legs);
      expect(equipmentSlotFromDimItemType('Class Item'), EquipmentSlot.classItem);
      expect(equipmentSlotFromDimItemType('Class Armor'), EquipmentSlot.classItem);
      expect(
        equipmentSlotFromDimItemType('Kinetic Weapon'),
        EquipmentSlot.primary,
      );
      expect(
        equipmentSlotFromDimItemType('Energy Weapon'),
        EquipmentSlot.special,
      );
      expect(
        equipmentSlotFromDimItemType('Power Weapon'),
        EquipmentSlot.heavy,
      );
      // Bungie / compiled DIM display labels are plural.
      expect(
        equipmentSlotFromDimItemType('Kinetic Weapons'),
        EquipmentSlot.primary,
      );
      expect(
        equipmentSlotFromDimItemType('Energy Weapons'),
        EquipmentSlot.special,
      );
      expect(
        equipmentSlotFromDimItemType('Power Weapons'),
        EquipmentSlot.heavy,
      );
      expect(equipmentSlotFromDimItemType('Kinetic'), EquipmentSlot.primary);
      expect(equipmentSlotFromDimItemType('Energy'), EquipmentSlot.special);
      expect(equipmentSlotFromDimItemType('Power'), EquipmentSlot.heavy);
    });

    test('weapon type alone does not map a combat slot', () {
      expect(equipmentSlotFromDimItemType('Hand Cannon'), isNull);
      expect(equipmentSlotFromDimItemType('Auto Rifle'), isNull);
    });
  });

  group('extractFillInPiecesFromDimLoadout', () {
    test('reads exotic armor name used by details EXOTIC line', () {
      const loadout = CachedDimLoadout(
        shareId: 'syn-swarmers',
        name: 'Strand Swarmers',
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
            itemType: 'Kinetic Weapon',
            tier: 'Exotic',
          ),
          CachedDimItem(
            hash: 8002,
            name: 'Funnelweb',
            itemType: 'Energy Weapon',
            tier: 'Legendary',
          ),
          CachedDimItem(
            hash: 8003,
            name: 'Cataclysmic',
            itemType: 'Power Weapon',
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

      final pieces = extractFillInPiecesFromDimLoadout(loadout);
      expect(pieces.exoticArmorName, 'Swarmers');
      expect(pieces.exoticArmorHash, 7001);
      expect(pieces.exoticArmorSlot, EquipmentSlot.legs);
      expect(pieces.armorBySlot[EquipmentSlot.legs]?.name, 'Swarmers');
      expect(pieces.weaponsBySlot.keys, {
        EquipmentSlot.primary,
        EquipmentSlot.special,
        EquipmentSlot.heavy,
      });
      expect(pieces.weaponsBySlot[EquipmentSlot.primary]?.name, 'Barrow-Dyad');
      expect(pieces.weaponsBySlot[EquipmentSlot.primary]?.isExotic, isTrue);
      expect(pieces.weaponsBySlot[EquipmentSlot.special]?.isExotic, isFalse);
    });

    test('exotic summary alone keeps name without inventing a class-item slot', () {
      const loadout = CachedDimLoadout(
        shareId: 'syn-exo-only',
        name: 'Exo only',
        classType: 2,
        items: [],
        subclassPlugs: [],
        mods: [],
        artifactPerks: [],
        exotic: CachedDimExotic(
          hash: 42,
          name: 'Swarmers',
          description: '',
        ),
      );
      final pieces = extractFillInPiecesFromDimLoadout(loadout);
      expect(pieces.exoticArmorName, 'Swarmers');
      expect(pieces.exoticArmorHash, 42);
      expect(pieces.exoticArmorSlot, isNull);
      expect(pieces.armorBySlot, isEmpty);
    });

    test('plural Kinetic Weapons puts Barrow-Dyad in primary bucket', () {
      const loadout = CachedDimLoadout(
        shareId: 'syn-plural-buckets',
        name: 'Plural buckets',
        classType: 2,
        items: [
          CachedDimItem(
            hash: 7001,
            name: 'Swarmers',
            itemType: 'Leg Armor',
            tier: 'Exotic',
          ),
          CachedDimItem(
            hash: 9001,
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
          description: '',
        ),
      );
      final pieces = extractFillInPiecesFromDimLoadout(loadout);
      expect(pieces.exoticArmorSlot, EquipmentSlot.legs);
      expect(pieces.armorBySlot[EquipmentSlot.legs]?.name, 'Swarmers');
      expect(
        pieces.armorBySlot[EquipmentSlot.classItem]?.name,
        "Apostate's Blade Bond",
      );
      expect(pieces.armorBySlot[EquipmentSlot.classItem]?.isExotic, isFalse);
      expect(pieces.weaponsBySlot[EquipmentSlot.primary]?.name, 'Barrow-Dyad');
      expect(pieces.weaponsBySlot[EquipmentSlot.primary]?.isExotic, isTrue);
      expect(pieces.weaponsBySlot[EquipmentSlot.special]?.name, 'Funnelweb');
      expect(pieces.weaponsBySlot[EquipmentSlot.heavy]?.name, 'Cataclysmic');
    });
  });
}
