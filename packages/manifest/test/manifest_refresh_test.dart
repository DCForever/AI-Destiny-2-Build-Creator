import 'dart:convert';
import 'dart:io';

import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:test/test.dart';

import 'fixtures/raw_tables.dart';

const refreshVersion = 'refresh.fixture.v1';

ManifestHttpGet fixtureAwareHttpGet(String version) {
  return (Uri uri, {Map<String, String>? headers}) async {
    final url = uri.toString();
    if (url.contains('/Platform/Destiny2/Manifest')) {
      final en = <String, String>{
        for (final t in downloadRawTables)
          t: '/common/destiny2/content/json/en/$t.json',
      };
      return ManifestHttpResponse(
        statusCode: 200,
        body: jsonEncode({
          'Response': {
            'version': version,
            'jsonWorldComponentContentPaths': {'en': en},
          },
        }),
      );
    }
    for (final table in downloadRawTables) {
      if (url.endsWith('$table.json')) {
        final fixture = fixtureRawTables[table];
        final body = fixture != null ? fixture : <String, dynamic>{};
        return ManifestHttpResponse(
          statusCode: 200,
          body: jsonEncode(body),
        );
      }
    }
    return const ManifestHttpResponse(statusCode: 404, body: 'not found');
  };
}

void main() {
  late Directory tmp;
  late StorageRoot root;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('dart-018-refresh-');
    root = StorageRoot(basePath: tmp.path);
    await root.ensureLayout();
  });

  tearDown(() async {
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  });

  group('WindowsManifestRefresh', () {
    test('status and isStale mirror service', () async {
      final api = WindowsManifestRefresh(
        storageRoot: root,
        apiKey: 'k',
        httpGet: fixtureAwareHttpGet(refreshVersion),
      );
      expect(await api.isStale(), isTrue);
      final status = await api.status();
      expect(status.isStale, isTrue);
      expect(status.remoteVersion, refreshVersion);
    });

    test('refresh downloads, isolate-rebuilds, returns status with meta',
        () async {
      final api = WindowsManifestRefresh(
        storageRoot: root,
        apiKey: 'test-key',
        httpGet: fixtureAwareHttpGet(refreshVersion),
      );

      final status = await api.refresh(rebuildInIsolate: true);

      expect(status.cachedVersion, refreshVersion);
      expect(status.remoteVersion, refreshVersion);
      expect(status.isStale, isFalse);
      expect(status.entityCache, isNotNull);
      expect(status.entityCache!.manifestVersion, refreshVersion);
      expect(status.entityCache!.counts.containsKey('weapons'), isTrue);
      expect(status.entityCache!.counts['weapons'], greaterThan(0));
      expect(status.entityCache!.counts['aspects'], greaterThan(0));

      // Stores readable offline via FileEntityCache
      final cache = FileEntityCache(
        storageRoot: root,
        version: refreshVersion,
      );
      final weapons = await cache.getStore<WeaponRecord>(MvpStoreName.weapons);
      expect(weapons, isNotEmpty);
      expect(weapons.any((w) => w.name == 'Chattering Bone'), isTrue);

      final metaFile = File(root.entityCacheMetaPath(refreshVersion));
      expect(await metaFile.exists(), isTrue);
    });

    test('refresh with rebuildInIsolate false also rebuilds', () async {
      final api = WindowsManifestRefresh(
        storageRoot: root,
        apiKey: 'test-key',
        httpGet: fixtureAwareHttpGet(refreshVersion),
      );

      final status = await api.refresh(rebuildInIsolate: false);
      expect(status.entityCache?.counts['mods'], greaterThan(0));
    });

    test('isolate rebuild entry works with pre-written raw tables', () async {
      // Write fixture tables only (no network)
      for (final entry in fixtureRawTables.entries) {
        final path = root.rawTablePath(refreshVersion, entry.key);
        await File(path).parent.create(recursive: true);
        await File(path).writeAsString(jsonEncode(entry.value));
      }

      final meta = await rebuildEntityCacheInIsolate(
        basePath: root.basePath,
        version: refreshVersion,
        builtAtIso: '2026-07-24T12:00:00.000Z',
      );
      expect(meta.manifestVersion, refreshVersion);
      expect(meta.builtAt, '2026-07-24T12:00:00.000Z');
      expect(meta.counts['exotic-armor'], 1);
    });
  });
}
