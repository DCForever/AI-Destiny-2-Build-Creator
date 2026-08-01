import 'package:destiny2_db/destiny2_db.dart';
import 'package:test/test.dart';

InventoryItemRecord _item({
  required String instanceId,
  required int itemHash,
  int power = 0,
  String location = 'vault',
  String? characterId,
  bool isMasterwork = false,
  bool isCrafted = false,
  List<int> plugHashes = const [],
  List<String> rollTags = const [],
}) {
  return InventoryItemRecord(
    instanceId: instanceId,
    itemHash: itemHash,
    bucket: 'Kinetic',
    location: location,
    characterId: characterId,
    power: power,
    isMasterwork: isMasterwork,
    isCrafted: isCrafted,
    plugHashes: plugHashes,
    rollTags: rollTags,
    syncedAt: '2026-07-24T00:00:00.000Z',
  );
}

void main() {
  group('ownedHashCountsFromInventory', () {
    test('counts by itemHash', () {
      final counts = ownedHashCountsFromInventory([
        _item(instanceId: 'a', itemHash: 10, power: 1800),
        _item(instanceId: 'b', itemHash: 10, power: 1810),
        _item(instanceId: 'c', itemHash: 20, power: 1700),
      ]);
      expect(counts[10], 2);
      expect(counts[20], 1);
    });
  });

  group('projectInstancesForHash', () {
    test('returns copies sorted power desc', () {
      final rows = [
        _item(instanceId: 'low', itemHash: 10, power: 1700),
        _item(instanceId: 'high', itemHash: 10, power: 1900),
        _item(instanceId: 'mid', itemHash: 10, power: 1800),
        _item(instanceId: 'other', itemHash: 99, power: 2000),
      ];
      final proj = projectInstancesForHash(rows, 10);
      expect(proj.map((p) => p.instanceId), ['high', 'mid', 'low']);
      expect(proj.every((p) => p.itemHash == 10), isTrue);
    });

    test('empty when no copies', () {
      expect(projectInstancesForHash([_item(instanceId: 'a', itemHash: 1)], 99), isEmpty);
    });

    test('preserves flags and plugs', () {
      final proj = projectInstancesForHash(
        [
          _item(
            instanceId: 'mw',
            itemHash: 5,
            power: 1810,
            location: 'equipped',
            characterId: 'c1',
            isMasterwork: true,
            isCrafted: true,
            plugHashes: [11, 22],
            rollTags: ['god'],
          ),
        ],
        5,
      );
      final p = proj.single;
      expect(p.isMasterwork, isTrue);
      expect(p.isCrafted, isTrue);
      expect(p.plugHashes, [11, 22]);
      expect(p.rollTags, ['god']);
      expect(p.location, 'equipped');
      expect(p.characterId, 'c1');
    });
  });
}
