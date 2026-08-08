import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('CatalogFilterCollection model', () {
    test('filtersToJson / fromJson round-trip', () {
      const original = CatalogFilterCollection(
        id: 'c1',
        userId: '7',
        name: 'Solar specials',
        browseMode: kCatalogBrowseModeWeapons,
        scope: kCatalogScopeOwned,
        query: 'adept',
        exotic: false,
        elements: CatalogFacetSelection(include: ['Solar']),
        ammos: CatalogFacetSelection(exclude: ['Heavy']),
        slots: CatalogFacetSelection(include: ['Energy']),
        archetypes: CatalogFacetSelection(include: ['Hand Cannon']),
        classNames: CatalogFacetSelection(),
        synergies: CatalogFacetSelection(include: ['syn-1']),
        sortKeys: ['slot', 'name'],
        groupBy: ['element', 'ammo'],
        createdAtMs: 100,
        updatedAtMs: 200,
      );

      final json = original.toJson();
      final restored = CatalogFilterCollection.fromJson(json);
      expect(restored, original);
    });

    test('filtersFromJson ignores identity and restores criteria', () {
      final c = CatalogFilterCollection.filtersFromJson(
        {
          'scope': 'owned',
          'query': 'void',
          'exotic': true,
          'elements': {
            'include': ['Void'],
            'exclude': <String>[],
          },
          'sortKeys': ['exotic', 'name'],
        },
        id: 'x',
        userId: '1',
        name: 'Void exo',
        browseMode: kCatalogBrowseModeArmor,
      );
      expect(c.scope, kCatalogScopeOwned);
      expect(c.query, 'void');
      expect(c.exotic, isTrue);
      expect(c.elements.include, ['Void']);
      expect(c.sortKeys, ['exotic', 'name']);
      expect(c.browseMode, kCatalogBrowseModeArmor);
    });

    test('unknown scope falls back to all', () {
      final c = CatalogFilterCollection.filtersFromJson(
        {'scope': 'nope'},
        id: 'x',
        userId: '1',
        name: 'n',
        browseMode: kCatalogBrowseModeWeapons,
      );
      expect(c.scope, kCatalogScopeAll);
    });
  });

  group('validateCatalogFilterCollection', () {
    test('accepts valid weapons collection', () {
      expect(
        () => validateCatalogFilterCollection(
          const CatalogFilterCollection(
            id: '1',
            userId: '1',
            name: 'Raid',
            browseMode: kCatalogBrowseModeWeapons,
          ),
        ),
        returnsNormally,
      );
    });

    test('rejects empty name', () {
      expect(
        () => validateCatalogFilterCollection(
          const CatalogFilterCollection(
            id: '1',
            userId: '1',
            name: '   ',
            browseMode: kCatalogBrowseModeWeapons,
          ),
        ),
        throwsA(
          isA<CatalogFilterCollectionValidationException>().having(
            (e) => e.code,
            'code',
            'FILTER_COLLECTION_NAME_REQUIRED',
          ),
        ),
      );
    });

    test('rejects unknown browse mode', () {
      expect(
        () => validateCatalogFilterCollection(
          const CatalogFilterCollection(
            id: '1',
            userId: '1',
            name: 'x',
            browseMode: 'pets',
          ),
        ),
        throwsA(
          isA<CatalogFilterCollectionValidationException>().having(
            (e) => e.code,
            'code',
            'FILTER_COLLECTION_BROWSE_MODE_INVALID',
          ),
        ),
      );
    });

    test('rejects unknown scope', () {
      expect(
        () => validateCatalogFilterCollection(
          const CatalogFilterCollection(
            id: '1',
            userId: '1',
            name: 'x',
            browseMode: kCatalogBrowseModeUniversal,
            scope: 'vault',
          ),
        ),
        throwsA(
          isA<CatalogFilterCollectionValidationException>().having(
            (e) => e.code,
            'code',
            'FILTER_COLLECTION_SCOPE_INVALID',
          ),
        ),
      );
    });
  });

  test('soft max constant is 20', () {
    expect(kMaxCatalogFilterCollectionsPerUserMode, 20);
  });
}
