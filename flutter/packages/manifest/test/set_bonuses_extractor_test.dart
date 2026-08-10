import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:test/test.dart';

void main() {
  group('SetBonusesExtractor', () {
    test('extracts named equipable item sets', () async {
      final extractor = SetBonusesExtractor();
      final rows = await extractor.extract((table) async {
        if (table == 'DestinyEquipableItemSetDefinition') {
          return {
            '1': {
              'hash': 1,
              'redacted': false,
              'displayProperties': {
                'name': 'Terminal Excess',
                'description': '',
                'icon': '/common/icon.png',
              },
              'setItems': [101, 102],
              'setPerks': [
                {'requiredSetCount': 2, 'sandboxPerkHash': 9001},
                {'requiredSetCount': 4, 'sandboxPerkHash': 9002},
              ],
            },
            '2': {
              'hash': 2,
              'displayProperties': {'name': '', 'description': ''},
              'setItems': [],
              'setPerks': [],
            },
            '3': {
              'hash': 3,
              'redacted': true,
              'displayProperties': {'name': 'Hidden', 'description': ''},
              'setItems': [1],
              'setPerks': [],
            },
          };
        }
        if (table == 'DestinySandboxPerkDefinition') {
          return {
            '9001': {
              'hash': 9001,
              'displayProperties': {
                'name': '2pc perk',
                'description': 'Two piece',
              },
            },
            '9002': {
              'hash': 9002,
              'displayProperties': {
                'name': '4pc perk',
                'description': 'Four piece',
              },
            },
          };
        }
        return {};
      });

      expect(rows, hasLength(1));
      final rec = rows.single as SetBonusCatalogRecord;
      expect(rec.name, 'Terminal Excess');
      expect(rec.perks, hasLength(2));
      expect(rec.perks.first.requiredCount, 2);
      expect(rec.perks.first.name, '2pc perk');
      expect(rec.itemHashes, [101, 102]);
    });
  });

  group('setBonusFamilyNamesFromRawTable', () {
    test('lists sorted unique names', () {
      final names = setBonusFamilyNamesFromRawTable({
        '1': {
          'hash': 1,
          'displayProperties': {'name': 'Zebra Set', 'description': ''},
          'setItems': [],
          'setPerks': [],
        },
        '2': {
          'hash': 2,
          'displayProperties': {'name': 'Alpha Set', 'description': ''},
          'setItems': [],
          'setPerks': [],
        },
      });
      expect(names, ['Alpha Set', 'Zebra Set']);
    });
  });
}
