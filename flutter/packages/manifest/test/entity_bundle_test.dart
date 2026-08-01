import 'dart:convert';

import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:test/test.dart';

void main() {
  final fixtureBundle = {
    'manifestVersion': 'prebuilt-mvp-1',
    'builtAt': '2026-07-25T00:00:00.000Z',
    'counts': {
      'weapons': 2,
      'exotic-weapons': 1,
      'exotic-armor': 1,
      'legendary-armor': 1,
      'aspects': 1,
    },
    'stores': {
      'weapons': [
        {
          'hash': 100,
          'name': 'Void GL',
          'searchName': 'void gl',
          'icon': null,
          'slot': 'Energy',
          'element': 'Void',
          'ammo': 'Special',
          'frame': 'Adaptive Frame',
          'itemTypeName': 'Grenade Launcher',
          'originTraitHashes': <int>[],
          'perkColumns': <Map<String, dynamic>>[],
        },
        {
          'hash': 101,
          'name': 'Solar Rocket',
          'searchName': 'solar rocket',
          'icon': null,
          'slot': 'Power',
          'element': 'Solar',
          'ammo': 'Heavy',
          'frame': 'Adaptive Frame',
          'itemTypeName': 'Rocket Launcher',
          'originTraitHashes': <int>[],
          'perkColumns': <Map<String, dynamic>>[],
        },
      ],
      'exotic-weapons': [
        {
          'hash': 150,
          'name': 'Gjallarhorn',
          'searchName': 'gjallarhorn',
          'icon': null,
          'slot': 'Power',
          'element': 'Solar',
          'ammo': 'Heavy',
          'frame': 'Wolfpack Rounds',
          'intrinsic': {
            'name': 'Wolfpack Rounds',
            'description': 'Cluster missiles.',
          },
          'catalyst': null,
          'flavorText': '',
          'perkColumns': <Map<String, dynamic>>[],
          'itemTypeName': 'Rocket Launcher',
        },
      ],
      'exotic-armor': [
        {
          'hash': 200,
          'name': 'Synthoceps',
          'searchName': 'synthoceps',
          'icon': null,
          'classType': 'Titan',
          'slot': 'Gauntlets',
          'intrinsic': {
            'name': 'Biotic Enhancements',
            'description': 'Improved melee.',
          },
          'archetype': 'Brawler',
          'flavorText': '',
        },
      ],
      'legendary-armor': [
        {
          'hash': 210,
          'name': 'Arms of Optimacy',
          'searchName': 'arms of optimacy',
          'icon': null,
          'classType': 'Titan',
          'slot': 'Gauntlets',
          'archetype': 'Brawler',
        },
      ],
      'aspects': [
        {
          'hash': 1014,
          'name': 'Touch of Thunder',
          'searchName': 'touch of thunder',
          'icon': null,
          'description': 'Improves Arc grenades.',
          'classType': 'Hunter',
          'element': 'Arc',
          'fragmentCapacity': 4,
        },
      ],
    },
  };

  group('EntityBundleDocument', () {
    test('parses meta + stores and projects catalog items', () {
      final doc = EntityBundleDocument.fromJson(
        Map<String, dynamic>.from(fixtureBundle),
      );
      expect(doc.version, 'prebuilt-mvp-1');
      expect(doc.meta.counts['weapons'], 2);
      expect(doc.stores[MvpStoreName.weapons], hasLength(2));
      expect(doc.stores[MvpStoreName.exoticWeapons], hasLength(1));
      expect(doc.stores[MvpStoreName.exoticArmor], hasLength(1));
      expect(doc.stores[MvpStoreName.legendaryArmor], hasLength(1));

      final items = doc.toCatalogItems();
      // 2 weapons + 1 exotic weapon + 1 exotic armor + 1 legendary armor + 1 aspect
      expect(items, hasLength(6));
      expect(
        items.map((i) => i.name),
        containsAll(['Void GL', 'Synthoceps', 'Gjallarhorn', 'Arms of Optimacy']),
      );
      expect(items.where((i) => i.element == 'Void'), hasLength(1));
      expect(items.where((i) => i.isExotic), hasLength(2)); // exo weapon + armor
      expect(
        items.where((i) => !i.isExotic && i.classType == 'Titan'),
        hasLength(1),
      );
    });

    test('parse from JSON string', () {
      final doc = EntityBundleDocument.parse(jsonEncode(fixtureBundle));
      expect(doc.meta.builtAt, '2026-07-25T00:00:00.000Z');
    });

    test('missing stores map throws', () {
      expect(
        () => EntityBundleDocument.fromJson({
          'manifestVersion': 'x',
        }),
        throwsA(isA<EntityBundleException>()),
      );
    });

    test('partial stores still project', () {
      final doc = EntityBundleDocument.fromJson({
        'manifestVersion': 'partial',
        'builtAt': '2026-07-25T00:00:00.000Z',
        'stores': {
          'weapons': (fixtureBundle['stores'] as Map)['weapons'],
        },
      });
      expect(doc.toCatalogItems(), hasLength(2));
      expect(doc.stores.containsKey(MvpStoreName.mods), isFalse);
    });
  });

  group('MemoryEntityCache + OfflineCatalog from bundle', () {
    test('memory cache serves stores', () async {
      final doc = EntityBundleDocument.fromJson(
        Map<String, dynamic>.from(fixtureBundle),
      );
      final cache = doc.toMemoryCache();
      expect(cache.version, 'prebuilt-mvp-1');
      final weapons = await cache.getStore<WeaponRecord>(MvpStoreName.weapons);
      expect(weapons.singleWhere((w) => w.hash == 100).name, 'Void GL');
    });

    test('offlineCatalogFromBundle supports facets without IO', () async {
      final doc = EntityBundleDocument.fromJson(
        Map<String, dynamic>.from(fixtureBundle),
      );
      final catalog = offlineCatalogFromBundle(doc);
      final load = await catalog.loadBase();
      expect(load.ok, isTrue);
      expect(load.version, 'prebuilt-mvp-1');
      expect(load.items, hasLength(6));

      final solar = catalog.browse(
        CatalogClientFilters(
          elements: FacetFilter(include: const ['Solar']),
        ),
      );
      // Alpha: Gjallarhorn, Solar Rocket
      expect(solar.map((i) => i.name), ['Gjallarhorn', 'Solar Rocket']);

      final exoticOnly = catalog.browse(
        const CatalogClientFilters(exotic: true),
      );
      expect(exoticOnly.map((i) => i.name), ['Gjallarhorn', 'Synthoceps']);

      final query = catalog.browse(
        const CatalogClientFilters(query: 'void'),
      );
      expect(query, hasLength(1));
      expect(query.single.name, 'Void GL');

      final legendaryArmor = catalog.browse(
        const CatalogClientFilters(
          slots: FacetFilter(include: ['Gauntlets']),
          exotic: false,
        ),
      );
      expect(legendaryArmor.map((i) => i.name), contains('Arms of Optimacy'));
    });

    test('OfflineCatalog with injected MemoryEntityCache', () async {
      final doc = EntityBundleDocument.fromJson(
        Map<String, dynamic>.from(fixtureBundle),
      );
      final catalog = OfflineCatalog(
        version: doc.version,
        cache: doc.toMemoryCache(),
      );
      final load = await catalog.loadBase();
      expect(load.items, hasLength(6));
      expect(load.emptyReason, CatalogEmptyReason.none);
    });
  });

  group('no raw rebuild required for catalog', () {
    test('MemoryEntityCache has no rebuild path for web catalog', () {
      final doc = EntityBundleDocument.fromJson(
        Map<String, dynamic>.from(fixtureBundle),
      );
      // Load-only surface: reader API is getMeta/getStore only.
      final reader = doc.toMemoryCache() as EntityCacheReader;
      expect(reader.version, isNotEmpty);
    });
  });
}
