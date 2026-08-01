import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:test/test.dart';

const items = <CatalogItem>[
  CatalogItem(
    hash: 1,
    name: 'Edge Transit',
    slot: 'Energy',
    element: 'Void',
    ammo: 'Special',
    itemTypeName: 'Grenade Launcher',
    isExotic: false,
    linkedSynergyIds: ['syn-void'],
  ),
  CatalogItem(
    hash: 2,
    name: "Dragon's Breath",
    slot: 'Power',
    element: 'Solar',
    ammo: 'Heavy',
    itemTypeName: 'Rocket Launcher',
    isExotic: true,
    linkedSynergyIds: ['syn-solar', 'syn-dps'],
  ),
  CatalogItem(
    hash: 3,
    name: 'Synthoceps',
    slot: 'Gauntlets',
    classType: 'Titan',
    frame: 'Brawler',
    isExotic: true,
    linkedSynergyIds: ['syn-melee'],
  ),
  CatalogItem(
    hash: 4,
    name: 'Arc Logic',
    slot: 'Energy',
    element: 'Arc',
    ammo: 'Primary',
    itemTypeName: 'Auto Rifle',
    isExotic: false,
    linkedSynergyIds: [],
  ),
];

void main() {
  group('facet helpers', () {
    test('cycles off → include → exclude → off', () {
      var f = emptyFacet();
      f = cycleFacetValue(f, 'Solar');
      expect(facetChipState(f, 'Solar'), FacetChipState.include);
      f = cycleFacetValue(f, 'Solar');
      expect(facetChipState(f, 'Solar'), FacetChipState.exclude);
      f = cycleFacetValue(f, 'Solar');
      expect(facetChipState(f, 'Solar'), FacetChipState.off);
    });

    test('matchesFacet: include OR, exclude drops', () {
      expect(
        matchesFacet(
          const FacetFilter(include: ['Solar', 'Arc']),
          'Solar',
        ),
        isTrue,
      );
      expect(
        matchesFacet(
          const FacetFilter(include: ['Solar'], exclude: ['Special']),
          'Solar',
        ),
        isTrue,
      );
      expect(
        matchesFacet(const FacetFilter(exclude: ['Void']), 'Void'),
        isFalse,
      );
      expect(
        matchesFacet(const FacetFilter(exclude: ['Void']), 'Solar'),
        isTrue,
      );
    });
  });

  group('filterCatalogClient', () {
    test('legacy List still includes (OR within dimension), alpha order', () {
      expect(
        filterCatalogClient(
          items,
          const CatalogClientFilters(elements: ['Void', 'Solar']),
        ).map((i) => i.hash).toList(),
        // Dragon's Breath, Edge Transit
        [2, 1],
      );
    });

    test('filters by exotic flag and element include', () {
      expect(
        filterCatalogClient(
          items,
          const CatalogClientFilters(
            onlyExotic: true,
            elements: FacetFilter(include: ['Solar']),
          ),
        ).map((i) => i.hash).toList(),
        [2],
      );
    });

    test('mix-and-match: include Solar OR Arc AND exclude Special ammo', () {
      final hashes = filterCatalogClient(
        items,
        const CatalogClientFilters(
          elements: FacetFilter(include: ['Solar', 'Arc']),
          ammos: FacetFilter(exclude: ['Special']),
        ),
      ).map((i) => i.hash).toList();
      // Arc Logic, Dragon's Breath
      expect(hashes, [4, 2]);
    });

    test('AND across dimensions: include Heavy and exclude Solar', () {
      expect(
        filterCatalogClient(
          items,
          const CatalogClientFilters(
            ammos: FacetFilter(include: ['Heavy']),
            elements: FacetFilter(exclude: ['Solar']),
          ),
        ).map((i) => i.hash).toList(),
        isEmpty,
      );
    });

    test('exclude exotic keeps legendaries (alpha)', () {
      expect(
        filterCatalogClient(
          items,
          const CatalogClientFilters(exotic: false),
        ).map((i) => i.hash).toList(),
        // Arc Logic, Edge Transit
        [4, 1],
      );
    });

    test('free-text after include/exclude', () {
      expect(
        filterCatalogClient(
          items,
          const CatalogClientFilters(
            elements: FacetFilter(include: ['Void', 'Solar', 'Arc']),
            query: 'breath',
          ),
        ).map((i) => i.hash).toList(),
        [2],
      );
    });

    test('filters by ammo and slot (legacy)', () {
      expect(
        filterCatalogClient(
          items,
          const CatalogClientFilters(ammos: ['Heavy'], slot: 'Power'),
        ).map((i) => i.hash).toList(),
        [2],
      );
    });

    test('classNames facet', () {
      expect(
        filterCatalogClient(
          items,
          const CatalogClientFilters(className: 'Titan'),
        ).map((i) => i.hash).toList(),
        [3],
      );
    });

    test('synergy include', () {
      expect(
        filterCatalogClient(
          items,
          const CatalogClientFilters(
            synergies: FacetFilter(include: ['syn-melee']),
          ),
        ).map((i) => i.hash).toList(),
        [3],
      );
    });

    test('itemHashesInclude / exclude (alpha)', () {
      expect(
        filterCatalogClient(
          items,
          const CatalogClientFilters(itemHashesInclude: {1, 4}),
        ).map((i) => i.hash).toList(),
        // Arc Logic, Edge Transit
        [4, 1],
      );
      expect(
        filterCatalogClient(
          items,
          const CatalogClientFilters(itemHashesExclude: {1, 2, 3}),
        ).map((i) => i.hash).toList(),
        [4],
      );
    });

    test('archetype facet on itemTypeName and frame', () {
      expect(
        filterCatalogClient(
          items,
          const CatalogClientFilters(
            archetypes: FacetFilter(include: ['Auto Rifle']),
          ),
        ).map((i) => i.hash).toList(),
        [4],
      );
      expect(
        filterCatalogClient(
          items,
          const CatalogClientFilters(
            archetypes: FacetFilter(include: ['Brawler']),
          ),
        ).map((i) => i.hash).toList(),
        [3],
      );
    });

    test('empty filter alpha-sorts by display name (GAP-UI-CATALOG-07)', () {
      final names = filterCatalogClient(
        items,
        const CatalogClientFilters(),
      ).map((i) => i.name).toList();
      expect(names, [
        'Arc Logic',
        "Dragon's Breath",
        'Edge Transit',
        'Synthoceps',
      ]);
    });
  });
}
