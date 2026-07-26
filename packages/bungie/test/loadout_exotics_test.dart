import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

void main() {
  group('resolveLoadoutExoticsFromInstances', () {
    final catalog = buildExoticCatalogIndex(
      exoticArmor: [(hash: 100, name: 'Synthoceps')],
      exoticWeapons: [(hash: 200, name: 'Tractor Cannon')],
    );

    test('resolves first exotic armor and weapon', () {
      final r = resolveLoadoutExoticsFromInstances(
        itemInstanceIds: ['a', 'b', 'c'],
        instanceIdToHash: {'a': 1, 'b': 100, 'c': 200},
        catalog: catalog,
      );
      expect(r.exoticArmorHash, 100);
      expect(r.exoticArmorName, 'Synthoceps');
      expect(r.exoticWeaponHash, 200);
      expect(r.exoticWeaponName, 'Tractor Cannon');
    });

    test('skips missing instance ids', () {
      final r = resolveLoadoutExoticsFromInstances(
        itemInstanceIds: ['missing', '0', ''],
        instanceIdToHash: {'other': 100},
        catalog: catalog,
      );
      expect(r.exoticArmorHash, isNull);
      expect(r.exoticWeaponHash, isNull);
    });
  });

  group('enrichLoadoutsWithExotics', () {
    test('copyWith exotic names onto loadouts', () {
      const lo = BungieInGameLoadout(
        id: 'char:0',
        characterId: 'char',
        className: 'Titan',
        characterLight: 2000,
        index: 0,
        name: 'Alpha',
        iconHash: 1,
        colorHash: 2,
        nameHash: 3,
        itemInstanceIds: ['i1'],
        empty: false,
      );
      final catalog = buildExoticCatalogIndex(
        exoticArmor: [(hash: 50, name: 'Cuirass')],
        exoticWeapons: const [],
      );
      final enriched = enrichLoadoutsWithExotics(
        [lo],
        instanceIdToHash: {'i1': 50},
        catalog: catalog,
      );
      expect(enriched.single.exoticArmorName, 'Cuirass');
      expect(enriched.single.exoticArmorHash, 50);
    });
  });

  group('instanceHashMapFromInventory', () {
    test('maps instance to hash', () {
      final map = instanceHashMapFromInventory([
        (instanceId: 'x', itemHash: 9),
        (instanceId: '', itemHash: 1),
      ]);
      expect(map, {'x': 9});
    });
  });
}
