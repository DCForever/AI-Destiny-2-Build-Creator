import 'dart:convert';
import 'dart:io';

import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late StorageRoot root;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('dart-020-catalog-');
    root = StorageRoot(basePath: tmp.path);
    await root.ensureLayout();
  });

  tearDown(() async {
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  });

  Future<void> writeEntityFixtures(String version) async {
    await File(root.currentVersionPath).writeAsString(
      jsonEncode({'version': version}),
    );
    final weapons = [
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
    ];
    final armor = [
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
    ];
    await File(root.entityStorePath(version, 'weapons')).parent
        .create(recursive: true);
    await File(root.entityStorePath(version, 'weapons'))
        .writeAsString(jsonEncode(weapons));
    await File(root.entityStorePath(version, 'exotic-armor'))
        .writeAsString(jsonEncode(armor));
    await File(root.entityCacheMetaPath(version)).writeAsString(
      jsonEncode({
        'manifestVersion': version,
        'builtAt': '2026-07-24T00:00:00.000Z',
        'counts': {'weapons': 2, 'exotic-armor': 1},
      }),
    );
  }

  group('OfflineCatalog', () {
    test('no version → empty with noVersion reason', () async {
      final catalog = OfflineCatalog(storageRoot: root);
      final result = await catalog.loadBase();
      expect(result.ok, isTrue);
      expect(result.items, isEmpty);
      expect(result.emptyReason, CatalogEmptyReason.noVersion);
      expect(catalog.browse(), isEmpty);
    });

    test('loads fixture entities and filters without inventory', () async {
      const version = 'offline-cat-1';
      await writeEntityFixtures(version);

      final catalog = OfflineCatalog(storageRoot: root);
      final result = await catalog.loadBase();
      expect(result.ok, isTrue);
      expect(result.version, version);
      expect(result.items, hasLength(3));
      expect(result.items.every((i) => i.owned == false), isTrue);
      expect(result.items.every((i) => i.ownedCount == 0), isTrue);

      final solar = catalog.browse(
        const CatalogClientFilters(
          elements: FacetFilter(include: ['Solar']),
        ),
      );
      expect(solar.map((i) => i.hash), [101]);

      final exotic = catalog.browse(
        const CatalogClientFilters(exotic: true),
      );
      expect(exotic.map((i) => i.hash), [200]);
      expect(exotic.single.isExotic, isTrue);

      final text = catalog.browse(
        const CatalogClientFilters(query: 'void'),
      );
      expect(text.map((i) => i.hash), [100]);
    });

    test('explicit version override without current-version file', () async {
      const version = 'fixed-ver';
      await writeEntityFixtures(version);
      // Remove current-version so only explicit version works
      final cv = File(root.currentVersionPath);
      if (await cv.exists()) await cv.delete();

      final catalog = OfflineCatalog(storageRoot: root, version: version);
      final result = await catalog.loadBase();
      expect(result.items, hasLength(3));
    });

    test('missing stores for version → empty noStores', () async {
      await File(root.currentVersionPath).writeAsString(
        jsonEncode({'version': 'ghost'}),
      );
      final catalog = OfflineCatalog(storageRoot: root);
      final result = await catalog.loadBase();
      expect(result.ok, isTrue);
      expect(result.items, isEmpty);
      expect(result.emptyReason, CatalogEmptyReason.noStores);
    });
  });
}
