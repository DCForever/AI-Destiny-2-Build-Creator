import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

void main() {
  const kinetic = 1498876634;
  const helmet = 3448274439;
  const shaderBucket = 18606351;

  group('buildEquipmentBucketLookup', () {
    test('reads inventory.bucketTypeHash for equipment only', () {
      final table = <String, dynamic>{
        '100': {
          'hash': 100,
          'inventory': {'bucketTypeHash': kinetic},
        },
        '200': {
          'hash': 200,
          'inventory': {'bucketTypeHash': shaderBucket},
        },
        '300': {
          'hash': 300,
          'inventory': {'bucketTypeHash': helmet},
        },
      };

      final lookup = buildEquipmentBucketLookup(table, [100, 200, 300, 999]);

      expect(lookup[100], kinetic);
      expect(lookup[300], helmet);
      expect(lookup.containsKey(200), isFalse);
      expect(lookup.containsKey(999), isFalse);
    });

    test('accepts int keys on raw table', () {
      final table = <int, dynamic>{
        42: {
          'hash': 42,
          'inventory': {'bucketTypeHash': kinetic},
        },
      };
      final lookup = buildEquipmentBucketLookup(table, [42]);
      expect(lookup[42], kinetic);
    });

    test('empty itemHashes returns empty map', () {
      expect(buildEquipmentBucketLookup({'1': {}}, const []), isEmpty);
    });
  });

  group('buildEquipmentBucketLookupFromSlots', () {
    test('maps slot labels to equipment bucket hashes', () {
      final lookup = buildEquipmentBucketLookupFromSlots({
        1: 'Kinetic',
        2: 'Helmet',
        3: 'NotASlot',
      });
      expect(lookup[1], kinetic);
      expect(lookup[2], helmet);
      expect(lookup.containsKey(3), isFalse);
    });

    test('onlyHashes filters entries', () {
      final lookup = buildEquipmentBucketLookupFromSlots(
        {1: 'Kinetic', 2: 'Energy'},
        onlyHashes: [2],
      );
      expect(lookup.keys, [2]);
      expect(lookup[2], 2465295065);
    });
  });

  group('parseWeaponStatValues', () {
    test('maps combat stat hashes', () {
      final values = parseWeaponStatValues([
        (statHash: 4284893193, value: 260),
        (statHash: 4043523819, value: 80),
        (statHash: 999, value: 1),
      ]);
      expect(values?['RPM'], 260);
      expect(values?['Impact'], 80);
      expect(values?.containsKey('Health'), isFalse);
    });
  });
}
