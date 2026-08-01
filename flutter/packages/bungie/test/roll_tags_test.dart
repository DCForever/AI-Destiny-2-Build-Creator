import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

/// Golden fixtures mirroring `src/lib/inventory/rollTags.test.ts`.
void main() {
  final perkMap = <int, String>{
    1: 'Pugilist',
    2: 'Swashbuckler',
    3: 'Demolitionist',
    4: 'Adrenaline Junkie',
    5: 'Anti-Barrier Rounds',
    6: 'Firefly',
  };

  RollTagWeaponMeta weapon({
    String frame = 'Adaptive Frame',
    String itemTypeName = 'Hand Cannon',
  }) {
    return RollTagWeaponMeta(frame: frame, itemTypeName: itemTypeName);
  }

  group('computeRollTags', () {
    test('tags MeleeBuildCandidate for Hand Cannon with Pugilist + Swashbuckler',
        () {
      final tags = computeRollTags([1, 2], perkMap, weapon: weapon());
      expect(tags, contains(RollTags.meleeBuildCandidate));
    });

    test('does not tag MeleeBuildCandidate without both perks', () {
      final tags = computeRollTags([1, 6], perkMap, weapon: weapon());
      expect(tags, isNot(contains(RollTags.meleeBuildCandidate)));
    });

    test('tags OrbitBuild for Demolitionist + Adrenaline Junkie', () {
      final tags = computeRollTags(
        [3, 4],
        perkMap,
        weapon: weapon(itemTypeName: 'Auto Rifle'),
      );
      expect(tags, contains(RollTags.orbitBuild));
    });

    test('tags Crafted when isCrafted option is set', () {
      final tags = computeRollTags(
        const [],
        perkMap,
        options: const ComputeRollTagsOptions(isCrafted: true),
      );
      expect(tags, [RollTags.crafted]);
    });

    test('tags champion counter from weapon frame', () {
      final tags = computeRollTags(
        const [],
        perkMap,
        weapon: weapon(frame: 'Adaptive Frame', itemTypeName: 'Scout Rifle'),
      );
      expect(tags, contains(RollTags.championBarrier));
    });

    test('tags champion counter from perk name', () {
      final tags = computeRollTags([5], perkMap);
      expect(tags, contains(RollTags.championBarrier));
    });
  });

  group('buildPerkNameMapFromItemDefs', () {
    test('reads displayProperties.name for plug hashes', () {
      final table = <String, dynamic>{
        '5': {
          'hash': 5,
          'displayProperties': {'name': 'Anti-Barrier Rounds'},
        },
        '99': {
          'hash': 99,
          'displayProperties': {'name': ''},
        },
      };
      final map = buildPerkNameMapFromItemDefs(table, [5, 99, 1]);
      expect(map, {5: 'Anti-Barrier Rounds'});
    });
  });

  group('buildPerkNameMapFromNamedHashes', () {
    test('maps catalog entity names for requested plugs only', () {
      final map = buildPerkNameMapFromNamedHashes(
        [
          (hash: 3, name: 'Demolitionist'),
          (hash: 4, name: 'Adrenaline Junkie'),
          (hash: 9, name: 'Other'),
        ],
        onlyHashes: [3, 4],
      );
      expect(map, {3: 'Demolitionist', 4: 'Adrenaline Junkie'});
    });
  });

  group('buildWeaponRollMetaLookup', () {
    test('keeps legendary weapons with frame + type; skips exotic', () {
      final lookup = buildWeaponRollMetaLookup([
        const WeaponRollMetaSource(
          hash: 10,
          frame: 'Adaptive Frame',
          itemTypeName: 'Scout Rifle',
        ),
        const WeaponRollMetaSource(
          hash: 11,
          frame: 'Exotic Frame',
          itemTypeName: 'Hand Cannon',
          isExotic: true,
        ),
        const WeaponRollMetaSource(
          hash: 12,
          frame: '',
          itemTypeName: 'Bow',
        ),
      ]);
      expect(lookup.keys, [10]);
      expect(lookup[10]!.frame, 'Adaptive Frame');
      expect(lookup[10]!.itemTypeName, 'Scout Rifle');
    });
  });
}
