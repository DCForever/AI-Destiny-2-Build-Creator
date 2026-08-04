import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:test/test.dart';

void main() {
  group('columnIndexToLabel', () {
    test('maps standard indexes', () {
      expect(columnIndexToLabel(0), 'Barrel');
      expect(columnIndexToLabel(1), 'Magazine');
      expect(columnIndexToLabel(2), 'Trait 1');
      expect(columnIndexToLabel(3), 'Trait 2');
    });
  });

  group('weaponPerkColumnsToSocketPlugs', () {
    test('projects curated selected + randomized pool', () {
      const cols = [
        WeaponPerkColumn(
          column: 0,
          curated: [10],
          randomized: [10, 11, 12],
        ),
        WeaponPerkColumn(
          column: 1,
          curated: [20],
          randomized: [20, 21],
        ),
      ];
      final plugs = weaponPerkColumnsToSocketPlugs(cols);
      expect(plugs.length, 2);
      expect(plugs[0]['equippedPlugHash'], 10);
      expect(plugs[0]['columnLabel'], 'Barrel');
      final re0 = plugs[0]['reusablePlugHashes'] as List;
      expect(re0, containsAll([10, 11, 12]));
      expect(plugs[1]['equippedPlugHash'], 20);
      expect(plugs[1]['columnLabel'], 'Magazine');
    });

    test('includeRandomized false keeps curated only', () {
      const cols = [
        WeaponPerkColumn(column: 0, curated: [1], randomized: [1, 2, 3]),
      ];
      final plugs =
          weaponPerkColumnsToSocketPlugs(cols, includeRandomized: false);
      expect(plugs.single['reusablePlugHashes'], [1]);
    });
  });

  group('mergeDefinitionPoolsIntoSockets', () {
    test('expands reusables on non-meta columns', () {
      final instance = [
        {
          'columnKind': 'intrinsic',
          'columnLabel': 'Intrinsic',
          'equippedPlugHash': 1,
          'reusablePlugHashes': [1],
        },
        {
          'columnKind': 'barrel',
          'columnLabel': 'Barrel',
          'equippedPlugHash': 10,
          'reusablePlugHashes': [10],
        },
      ];
      const def = [
        WeaponPerkColumn(column: 0, curated: [10], randomized: [10, 11]),
      ];
      final merged = mergeDefinitionPoolsIntoSockets(instance, def);
      expect(merged[0]['reusablePlugHashes'], [1]); // intrinsic untouched
      final barrel = merged[1]['reusablePlugHashes'] as List;
      expect(barrel, containsAll([10, 11]));
    });
  });
}
