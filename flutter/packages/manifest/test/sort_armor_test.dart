import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:test/test.dart';

void main() {
  group('sortCatalogArmor', () {
    test('orders slot → exotic → class → tier(when known)', () {
      final items = [
        const CatalogItem(
          hash: 1,
          name: 'Zulu Legs',
          slot: 'Legs',
          classType: 'Titan',
          isExotic: false,
        ),
        const CatalogItem(
          hash: 2,
          name: 'Low Tier Helm',
          slot: 'Helmet',
          classType: 'Titan',
          isExotic: false,
        ),
        const CatalogItem(
          hash: 3,
          name: 'Exotic Helm',
          slot: 'Helmet',
          classType: 'Hunter',
          isExotic: true,
        ),
        const CatalogItem(
          hash: 4,
          name: 'High Tier Helm',
          slot: 'Helmet',
          classType: 'Titan',
          isExotic: false,
        ),
        const CatalogItem(
          hash: 5,
          name: 'Gauntlets',
          slot: 'Gauntlets',
          classType: 'Hunter',
          isExotic: false,
        ),
        const CatalogItem(
          hash: 6,
          name: 'Warlock Helm',
          slot: 'Helmet',
          classType: 'Warlock',
          isExotic: false,
        ),
      ];

      final tierOf = (CatalogItem i) {
        // Same class: higher tier first when both known.
        if (i.hash == 2) return 2;
        if (i.hash == 4) return 5;
        return null;
      };

      final sorted = sortCatalogArmor(items, tierOf: tierOf);
      expect(sorted.map((i) => i.hash).toList(), [
        3, // Helmet exotic first
        4, // Helmet Titan tier 5
        2, // Helmet Titan tier 2
        6, // Helmet Warlock (class after Titan)
        5, // Gauntlets
        1, // Legs
      ]);
    });

    test('unknown tier does not invent order (stable name → hash)', () {
      final sorted = sortCatalogArmor([
        const CatalogItem(
          hash: 20,
          name: 'B Piece',
          slot: 'Helmet',
          classType: 'Titan',
          isExotic: false,
        ),
        const CatalogItem(
          hash: 10,
          name: 'A Piece',
          slot: 'Helmet',
          classType: 'Titan',
          isExotic: false,
        ),
      ]);
      expect(sorted.map((i) => i.hash).toList(), [10, 20]);
    });

    test('one hash stable; does not mutate input', () {
      final items = [
        const CatalogItem(
          hash: 1,
          name: 'B',
          slot: 'Legs',
          classType: 'Hunter',
          isExotic: false,
        ),
        const CatalogItem(
          hash: 2,
          name: 'A',
          slot: 'Helmet',
          classType: 'Titan',
          isExotic: false,
        ),
      ];
      final copy = List<CatalogItem>.from(items);
      final sorted = sortCatalogArmor(items);
      expect(items.map((i) => i.hash).toList(), copy.map((i) => i.hash).toList());
      expect(sorted.map((i) => i.hash).toList(), [2, 1]);
    });

    test('unknown slots sort after known order', () {
      final sorted = sortCatalogArmor([
        const CatalogItem(
          hash: 1,
          name: 'X',
          slot: 'Weird',
          classType: 'Titan',
          isExotic: false,
        ),
        const CatalogItem(
          hash: 2,
          name: 'Y',
          slot: 'Helmet',
          classType: 'Titan',
          isExotic: false,
        ),
      ]);
      expect(sorted.first.hash, 2);
      expect(sorted.last.hash, 1);
    });

    test('class order Titan → Hunter → Warlock within slot', () {
      final sorted = sortCatalogArmor([
        const CatalogItem(
          hash: 1,
          name: 'W',
          slot: 'Chest',
          classType: 'Warlock',
          isExotic: false,
        ),
        const CatalogItem(
          hash: 2,
          name: 'T',
          slot: 'Chest',
          classType: 'Titan',
          isExotic: false,
        ),
        const CatalogItem(
          hash: 3,
          name: 'H',
          slot: 'Chest',
          classType: 'Hunter',
          isExotic: false,
        ),
      ]);
      expect(sorted.map((i) => i.hash).toList(), [2, 3, 1]);
    });
  });
}
