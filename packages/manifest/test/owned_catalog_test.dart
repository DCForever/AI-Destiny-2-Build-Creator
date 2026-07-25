import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:test/test.dart';

const base = <CatalogItem>[
  CatalogItem(
    hash: 1,
    name: 'Edge Transit',
    slot: 'Energy',
    element: 'Void',
    isExotic: false,
  ),
  CatalogItem(
    hash: 2,
    name: "Dragon's Breath",
    slot: 'Power',
    element: 'Solar',
    isExotic: true,
  ),
  CatalogItem(
    hash: 3,
    name: 'Arc Logic',
    slot: 'Energy',
    element: 'Arc',
    isExotic: false,
  ),
];

void main() {
  group('countOwnedByItemHash', () {
    test('counts copies per hash', () {
      final counts = countOwnedByItemHash([1, 1, 2, 1]);
      expect(counts[1], 3);
      expect(counts[2], 1);
      expect(counts.containsKey(3), isFalse);
    });

    test('empty input → empty map', () {
      expect(countOwnedByItemHash(const []), isEmpty);
    });
  });

  group('annotateCatalogWithOwned', () {
    test('sets owned and ownedCount from map', () {
      final annotated = annotateCatalogWithOwned(base, {1: 2, 2: 1});
      expect(annotated[0].owned, isTrue);
      expect(annotated[0].ownedCount, 2);
      expect(annotated[1].owned, isTrue);
      expect(annotated[1].ownedCount, 1);
      expect(annotated[2].owned, isFalse);
      expect(annotated[2].ownedCount, 0);
    });

    test('empty map clears ownership', () {
      final pre = annotateCatalogWithOwned(base, {1: 5});
      final cleared = annotateCatalogWithOwned(pre, const {});
      expect(cleared.every((i) => !i.owned && i.ownedCount == 0), isTrue);
    });
  });

  group('filterCatalogClient scope owned', () {
    test('owned scope keeps only ownedCount > 0', () {
      final annotated = annotateCatalogWithOwned(base, {1: 2, 2: 1});
      final owned = filterCatalogClient(
        annotated,
        const CatalogClientFilters(scope: CatalogScope.owned),
      );
      expect(owned.map((i) => i.hash), [1, 2]);
    });

    test('owned + facet AND', () {
      final annotated = annotateCatalogWithOwned(base, {1: 1, 2: 1, 3: 1});
      final solarOwned = filterCatalogClient(
        annotated,
        const CatalogClientFilters(
          scope: CatalogScope.owned,
          elements: ['Solar'],
        ),
      );
      expect(solarOwned.single.hash, 2);
    });

    test('owned empty inventory → empty list', () {
      final annotated = annotateCatalogWithOwned(base, const {});
      final owned = filterCatalogClient(
        annotated,
        const CatalogClientFilters(scope: CatalogScope.owned),
      );
      expect(owned, isEmpty);
    });

    test('all scope retains unowned', () {
      final annotated = annotateCatalogWithOwned(base, {1: 1});
      final all = filterCatalogClient(
        annotated,
        const CatalogClientFilters(scope: CatalogScope.all),
      );
      expect(all.length, 3);
    });
  });
}
