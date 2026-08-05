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

  group('buildPerkIconMapFromItemDefs', () {
    test('reads displayProperties.icon for plug hashes', () {
      final table = <String, dynamic>{
        '5': {
          'hash': 5,
          'displayProperties': {
            'name': 'Fluted Barrel',
            'icon': '/common/destiny2_content/icons/barrel.png',
          },
        },
        '99': {
          'hash': 99,
          'displayProperties': {'name': 'X', 'icon': ''},
        },
      };
      final map = buildPerkIconMapFromItemDefs(table, [5, 99, 1]);
      expect(map, {5: '/common/destiny2_content/icons/barrel.png'});
    });
  });

  group('buildPlugEnhancedMapFromItemDefs', () {
    test('name without Enhanced + category enhancements.v2 → true', () {
      final table = <String, dynamic>{
        '10': {
          'hash': 10,
          'displayProperties': {'name': 'Zen Moment'},
          'plug': {'plugCategoryIdentifier': 'enhancements.v2'},
        },
        '11': {
          'hash': 11,
          'displayProperties': {'name': 'Rapid Hit'},
          'plug': {'plugCategoryIdentifier': 'traits.weapon'},
        },
        '12': {
          'hash': 12,
          'displayProperties': {'name': 'Kill Clip Enhanced'},
          'plug': {'plugCategoryIdentifier': 'traits.weapon'},
        },
      };
      final map = buildPlugEnhancedMapFromItemDefs(table, [10, 11, 12, 99]);
      // Category path (DIM-style base display name + enhancements.v2).
      expect(map[10], isTrue);
      // Plain trait omitted.
      expect(map.containsKey(11), isFalse);
      // Name "Enhanced" still marks true.
      expect(map[12], isTrue);
      // Missing def omitted.
      expect(map.containsKey(99), isFalse);
    });

    test('enhancements.v2_* subcategory and enhanced token mark true', () {
      final table = <String, dynamic>{
        '20': {
          'hash': 20,
          'displayProperties': {'name': 'Hammer-Forged Rifling'},
          'plug': {'plugCategoryIdentifier': 'enhancements.v2_general'},
        },
        '21': {
          'hash': 21,
          'displayProperties': {'name': 'Smallbore'},
          'plug': {'plugCategoryIdentifier': 'enhanced.barrel'},
        },
      };
      final map = buildPlugEnhancedMapFromItemDefs(table, [20, 21]);
      expect(map[20], isTrue);
      expect(map[21], isTrue);
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
