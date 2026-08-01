import 'dart:convert';
import 'dart:io';

import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'fixtures/raw_tables.dart';

void main() {
  late Directory tmp;
  late StorageRoot root;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('dart-017-entity-');
    root = StorageRoot(basePath: tmp.path);
    await root.ensureLayout();
  });

  tearDown(() async {
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  });

  group('FileEntityCache offline read', () {
    test('reads fixture entity JSON without rebuild', () async {
      const version = 'offline-1';
      final aspects = [
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
      ];
      final path = root.entityStorePath(version, 'aspects');
      await File(path).parent.create(recursive: true);
      await File(path).writeAsString(jsonEncode(aspects));
      await File(root.entityCacheMetaPath(version)).writeAsString(
        jsonEncode({
          'manifestVersion': version,
          'builtAt': '2026-07-24T00:00:00.000Z',
          'counts': {'aspects': 1},
        }),
      );

      final cache = FileEntityCache(storageRoot: root, version: version);
      final meta = await cache.getMeta();
      expect(meta?.manifestVersion, version);
      expect(meta?.counts['aspects'], 1);

      final store = await cache.getStore<AspectRecord>(MvpStoreName.aspects);
      expect(store, hasLength(1));
      expect(store.single.fragmentCapacity, 4);
      expect(store.single.name, 'Touch of Thunder');
    });

    test('throws when version is null', () async {
      final cache = FileEntityCache(storageRoot: root);
      expect(
        () => cache.getStore<ModRecord>(MvpStoreName.mods),
        throwsA(isA<EntityCacheException>()),
      );
    });

    test('throws when store file missing', () async {
      final cache = FileEntityCache(storageRoot: root, version: 'missing');
      expect(
        () => cache.getStore<WeaponRecord>(MvpStoreName.weapons),
        throwsA(
          isA<EntityCacheException>().having(
            (e) => e.message,
            'message',
            contains('weapons'),
          ),
        ),
      );
    });
  });

  group('FileEntityCache rebuild', () {
    test('writes meta and stores then reads back', () async {
      const version = 'test-1.0';
      final cache = FileEntityCache(storageRoot: root);
      final meta = await cache.rebuild(
        version: version,
        loadRawTable: loadFixtureRawTable,
        builtAt: DateTime.utc(2026, 7, 24),
      );

      expect(meta.manifestVersion, version);
      expect(meta.counts['exotic-armor'], 1);
      expect(meta.counts['weapons'], 1);
      expect(meta.counts['aspects'], 2);
      expect(meta.counts['fragments'], 2);
      expect(meta.counts['abilities'], greaterThanOrEqualTo(5));
      expect(meta.counts['mods'], greaterThan(0));

      expect(File(root.entityCacheMetaPath(version)).existsSync(), isTrue);
      expect(
        File(root.entityStorePath(version, 'weapons')).existsSync(),
        isTrue,
      );

      // Fresh cache instance reads offline JSON.
      final reader = FileEntityCache(storageRoot: root, version: version);
      final weapons =
          await reader.getStore<WeaponRecord>(MvpStoreName.weapons);
      expect(weapons.single.name, 'Chattering Bone');

      final mods = await reader.getStore<ModRecord>(MvpStoreName.mods);
      expect(mods, isNotEmpty);

      // Layout under entities/<version>/ not repo .cache
      expect(p.isWithin(root.entitiesDir, root.entityStorePath(version, 'mods')),
          isTrue);
    });
  });
}
