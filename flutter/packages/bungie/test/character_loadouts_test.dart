import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

void main() {
  const characters = <CharacterSummary>[
    CharacterSummary(
      characterId: 'char1',
      classType: 'Titan',
      light: 2000,
      emblemPath: '/common/emblem.png',
      dateLastPlayed: '2026-01-01',
    ),
  ];

  final tables = presentationTablesFromRaw(
    icons: {
      '111': {'iconImagePath': '/common/destiny2_content/icons/loadout_a.png'},
    },
    colors: {
      '222': {'colorImagePath': '/common/destiny2_content/icons/color_a.png'},
    },
    names: {
      '333': {'name': 'Pyre Onslaught'},
    },
  );

  group('resolveLoadoutPresentation', () {
    test('maps hashes to CDN URLs and names', () {
      final p = resolveLoadoutPresentation(
        iconHash: 111,
        colorHash: 222,
        nameHash: 333,
        tables: tables,
        fallbackName: 'Fallback',
      );
      expect(p.name, 'Pyre Onslaught');
      expect(
        p.iconUrl,
        'https://www.bungie.net/common/destiny2_content/icons/loadout_a.png',
      );
      expect(
        p.colorUrl,
        'https://www.bungie.net/common/destiny2_content/icons/color_a.png',
      );
    });

    test('uses fallback name when nameHash unknown', () {
      final p = resolveLoadoutPresentation(
        iconHash: 0,
        colorHash: 0,
        nameHash: 0,
        tables: tables,
        fallbackName: 'Loadout 2',
      );
      expect(p.name, 'Loadout 2');
      expect(p.iconUrl, isNull);
    });
  });

  group('isEmptyLoadoutItems', () {
    test('treats zero instance ids as empty', () {
      expect(isEmptyLoadoutItems(const []), isTrue);
      expect(
        isEmptyLoadoutItems(const [
          RawLoadoutSlotItem(itemInstanceId: '0'),
        ]),
        isTrue,
      );
      expect(
        isEmptyLoadoutItems(const [
          RawLoadoutSlotItem(itemInstanceId: '123'),
        ]),
        isFalse,
      );
    });
  });

  group('parseCharacterLoadoutsResponse', () {
    test('parses component 206 characterLoadouts data', () {
      final response = {
        'characterLoadouts': {
          'data': {
            'char1': {
              'loadouts': [
                {
                  'iconHash': 111,
                  'colorHash': 222,
                  'nameHash': 333,
                  'items': [
                    {'itemInstanceId': '999', 'plugItemHashes': <int>[]},
                    {'itemInstanceId': '0', 'plugItemHashes': <int>[]},
                  ],
                },
                {
                  'iconHash': 0,
                  'colorHash': 0,
                  'nameHash': 0,
                  'items': <Object>[],
                },
              ],
            },
          },
        },
      };

      final list = parseCharacterLoadoutsResponse(
        response,
        characters,
        tables: tables,
      );
      expect(list, hasLength(2));
      expect(list[0].id, 'char1:0');
      expect(list[0].name, 'Pyre Onslaught');
      expect(list[0].iconUrl, contains('loadout_a.png'));
      expect(list[0].empty, isFalse);
      expect(list[0].itemInstanceIds, ['999']);
      expect(list[0].className, 'Titan');
      expect(list[0].characterLight, 2000);
      expect(list[1].name, 'Loadout 2');
      expect(list[1].empty, isTrue);
    });

    test('empty when characterLoadouts missing', () {
      expect(parseCharacterLoadoutsResponse({}, characters), isEmpty);
      expect(parseCharacterLoadoutsResponse(null, characters), isEmpty);
    });

    test('skips characters not in summary list', () {
      final response = {
        'characterLoadouts': {
          'data': {
            'unknown-char': {
              'loadouts': [
                {
                  'iconHash': 0,
                  'colorHash': 0,
                  'nameHash': 0,
                  'items': [
                    {'itemInstanceId': '1'},
                  ],
                },
              ],
            },
          },
        },
      };
      expect(
        parseCharacterLoadoutsResponse(response, characters, tables: tables),
        isEmpty,
      );
    });
  });

  group('filterInGameLoadouts', () {
    final rows = [
      const BungieInGameLoadout(
        id: 'c:0',
        characterId: 'c',
        className: 'Titan',
        characterLight: 1,
        index: 0,
        name: 'A',
        iconHash: 0,
        colorHash: 0,
        nameHash: 0,
        empty: false,
        itemInstanceIds: ['1'],
      ),
      const BungieInGameLoadout(
        id: 'c:1',
        characterId: 'c',
        className: 'Titan',
        characterLight: 1,
        index: 1,
        name: 'B',
        iconHash: 0,
        colorHash: 0,
        nameHash: 0,
        empty: true,
      ),
      const BungieInGameLoadout(
        id: 'h:0',
        characterId: 'h',
        className: 'Hunter',
        characterLight: 2,
        index: 0,
        name: 'C',
        iconHash: 0,
        colorHash: 0,
        nameHash: 0,
        empty: false,
        itemInstanceIds: ['2'],
      ),
    ];

    test('hides empty by default', () {
      final filtered = filterInGameLoadouts(rows);
      expect(filtered.map((e) => e.id), ['c:0', 'h:0']);
    });

    test('class filter', () {
      final filtered = filterInGameLoadouts(
        rows,
        classFilter: 'Hunter',
        hideEmpty: false,
      );
      expect(filtered.single.id, 'h:0');
    });
  });

  group('kCharacterLoadoutsProfileComponents', () {
    test('includes 200 and 206', () {
      expect(kCharacterLoadoutsProfileComponents, contains('200'));
      expect(kCharacterLoadoutsProfileComponents, contains('206'));
    });
  });
}
