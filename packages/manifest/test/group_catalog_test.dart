import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:test/test.dart';

const items = <CatalogItem>[
  CatalogItem(
    hash: 1,
    name: 'Zebra',
    slot: 'Energy',
    element: 'Void',
    ammo: 'Special',
    itemTypeName: 'Grenade Launcher',
    isExotic: false,
  ),
  CatalogItem(
    hash: 2,
    name: 'Alpha',
    slot: 'Power',
    element: 'Solar',
    ammo: 'Heavy',
    itemTypeName: 'Rocket Launcher',
    isExotic: true,
  ),
  CatalogItem(
    hash: 3,
    name: 'Beta',
    slot: 'Energy',
    element: 'Solar',
    ammo: 'Primary',
    itemTypeName: 'Auto Rifle',
    isExotic: false,
  ),
  CatalogItem(
    hash: 4,
    name: 'Synthoceps',
    slot: 'Gauntlets',
    classType: 'Titan',
    frame: 'Brawler',
    isExotic: true,
  ),
];

void main() {
  group('groupCatalogItems', () {
    test('empty dimensions → single All results bucket, alpha items', () {
      final groups = groupCatalogItems(items, const []);
      expect(groups, hasLength(1));
      expect(groups.single.key, '__all__');
      expect(groups.single.label, 'All results');
      expect(
        groups.single.items.map((i) => i.name).toList(),
        ['Alpha', 'Beta', 'Synthoceps', 'Zebra'],
      );
    });

    test('group by element partitions without dropping items', () {
      final groups = groupCatalogItems(items, const [
        CatalogGroupDimension.element,
      ]);
      final total = groups.fold<int>(0, (n, g) => n + g.items.length);
      expect(total, items.length);
      final byLabel = {for (final g in groups) g.label: g.items};
      expect(byLabel.keys.toSet(), {
        'Solar',
        'Unknown element',
        'Void',
      });
      expect(byLabel['Solar']!.map((i) => i.name), ['Alpha', 'Beta']);
    });

    test('multi-dim composite keys preserve filter membership', () {
      final groups = groupCatalogItems(items, const [
        CatalogGroupDimension.ammo,
        CatalogGroupDimension.archetype,
      ]);
      final total = groups.fold<int>(0, (n, g) => n + g.items.length);
      expect(total, items.length);
      expect(
        groups.any((g) => g.label == 'Heavy · Rocket Launcher'),
        isTrue,
      );
    });

    test('group labels are alpha-sorted', () {
      final groups = groupCatalogItems(items, const [
        CatalogGroupDimension.element,
      ]);
      final labels = groups.map((g) => g.label).toList();
      final sorted = List<String>.from(labels)
        ..sort((a, b) => compareDisplayName(a, b));
      expect(labels, sorted);
    });
  });

  group('compareDisplayName', () {
    test('case-insensitive', () {
      expect(compareDisplayName('alpha', 'Beta'), lessThan(0));
      expect(compareDisplayName('BETA', 'alpha'), greaterThan(0));
      expect(compareDisplayName('Same', 'same'), 0);
    });
  });
}
