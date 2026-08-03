import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:test/test.dart';

void main() {
  group('sortCatalogWeapons', () {
    test('orders slot → exotic → ammo → archetype → name', () {
      final items = [
        const CatalogItem(
          hash: 1,
          name: 'Zulu Heavy',
          slot: 'Power',
          ammo: 'Heavy',
          itemTypeName: 'Rocket Launcher',
          isExotic: false,
        ),
        const CatalogItem(
          hash: 2,
          name: 'Alpha Kinetic',
          slot: 'Kinetic',
          ammo: 'Primary',
          itemTypeName: 'Hand Cannon',
          isExotic: false,
        ),
        const CatalogItem(
          hash: 3,
          name: 'Exotic Kinetic',
          slot: 'Kinetic',
          ammo: 'Primary',
          itemTypeName: 'Hand Cannon',
          isExotic: true,
        ),
        const CatalogItem(
          hash: 4,
          name: 'Energy Special SMG',
          slot: 'Energy',
          ammo: 'Special',
          itemTypeName: 'Submachine Gun',
          isExotic: false,
        ),
        const CatalogItem(
          hash: 5,
          name: 'Energy Primary Auto',
          slot: 'Energy',
          ammo: 'Primary',
          itemTypeName: 'Auto Rifle',
          isExotic: false,
        ),
        const CatalogItem(
          hash: 6,
          name: 'Energy Primary Pulse',
          slot: 'Energy',
          ammo: 'Primary',
          itemTypeName: 'Pulse Rifle',
          isExotic: false,
        ),
        const CatalogItem(
          hash: 7,
          name: 'Beta Kinetic',
          slot: 'Kinetic',
          ammo: 'Primary',
          itemTypeName: 'Hand Cannon',
          isExotic: false,
        ),
      ];

      final sorted = sortCatalogWeapons(items);
      expect(sorted.map((i) => i.hash).toList(), [
        3, // Kinetic exotic first
        2, // Kinetic legendary Alpha before Beta
        7, // Kinetic legendary Beta
        5, // Energy Primary Auto before Pulse
        6, // Energy Primary Pulse
        4, // Energy Special
        1, // Power
      ]);
    });

    test('does not mutate input list', () {
      final items = [
        const CatalogItem(
          hash: 1,
          name: 'B',
          slot: 'Power',
          isExotic: false,
        ),
        const CatalogItem(
          hash: 2,
          name: 'A',
          slot: 'Kinetic',
          isExotic: false,
        ),
      ];
      final copy = List<CatalogItem>.from(items);
      sortCatalogWeapons(items);
      expect(items.map((i) => i.hash).toList(), copy.map((i) => i.hash).toList());
    });

    test('unknown slots sort after known order', () {
      final sorted = sortCatalogWeapons([
        const CatalogItem(hash: 1, name: 'X', slot: 'Weird', isExotic: false),
        const CatalogItem(hash: 2, name: 'Y', slot: 'Kinetic', isExotic: false),
      ]);
      expect(sorted.first.hash, 2);
      expect(sorted.last.hash, 1);
    });
  });

  group('compareCatalogWeapons', () {
    test('exotics before legendaries in same slot', () {
      const exotic = CatalogItem(
        hash: 1,
        name: 'Z',
        slot: 'Kinetic',
        isExotic: true,
      );
      const leg = CatalogItem(
        hash: 2,
        name: 'A',
        slot: 'Kinetic',
        isExotic: false,
      );
      expect(compareCatalogWeapons(exotic, leg), lessThan(0));
    });
  });
}
