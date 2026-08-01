import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/sets/set_slot_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('slotsForSetType', () {
    test('weapon slots primary special heavy', () {
      expect(
        slotsForSetType(SetType.weapon),
        ['primary', 'special', 'heavy'],
      );
    });

    test('armor five pieces', () {
      expect(
        slotsForSetType(SetType.armor),
        ['helmet', 'arms', 'chest', 'legs', 'class_item'],
      );
    });

    test('pair exotic slots', () {
      expect(
        slotsForSetType(SetType.pair),
        ['exotic_weapon', 'exotic_armor'],
      );
    });

    test('mod uses armor piece targets', () {
      expect(
        slotsForSetType(SetType.mod),
        slotsForSetType(SetType.armor),
      );
    });

    test('fashion slots non-empty', () {
      expect(slotsForSetType(SetType.fashion), isNotEmpty);
      expect(slotsForSetType(SetType.fashion), contains('ghost'));
    });
  });

  group('isSlotValidForSetType', () {
    test('weapon accepts primary only among combat weapons', () {
      expect(isSlotValidForSetType(SetType.weapon, 'primary'), isTrue);
      expect(isSlotValidForSetType(SetType.weapon, 'helmet'), isFalse);
    });

    test('mod accepts helmet and helmet:hash', () {
      expect(isSlotValidForSetType(SetType.mod, 'helmet'), isTrue);
      expect(isSlotValidForSetType(SetType.mod, 'helmet:42'), isTrue);
      expect(isSlotValidForSetType(SetType.mod, 'mod:9'), isTrue);
      expect(isSlotValidForSetType(SetType.mod, 'primary'), isFalse);
    });
  });

  group('mapCatalogBucketToSetSlot', () {
    test('Kinetic Energy Power → weapon slots', () {
      expect(
        mapCatalogBucketToSetSlot('Kinetic', SetType.weapon),
        'primary',
      );
      expect(
        mapCatalogBucketToSetSlot('Energy', SetType.weapon),
        'special',
      );
      expect(
        mapCatalogBucketToSetSlot('Power', SetType.weapon),
        'heavy',
      );
    });

    test('armor bucket labels', () {
      expect(mapCatalogBucketToSetSlot('Helmet', SetType.armor), 'helmet');
      expect(mapCatalogBucketToSetSlot('Gauntlets', SetType.armor), 'arms');
      expect(mapCatalogBucketToSetSlot('Chest Armor', SetType.armor), 'chest');
      expect(mapCatalogBucketToSetSlot('Class Item', SetType.armor), 'class_item');
    });
  });

  group('catalogItemMatchesSetSlot', () {
    test('Kinetic matches primary', () {
      expect(catalogItemMatchesSetSlot('Kinetic', 'primary'), isTrue);
      expect(catalogItemMatchesSetSlot('Energy', 'primary'), isFalse);
    });

    test('pair exotic slots accept any catalog slot', () {
      expect(catalogItemMatchesSetSlot('Power', 'exotic_weapon'), isTrue);
      expect(catalogItemMatchesSetSlot(null, 'exotic_weapon'), isTrue);
    });
  });
}
