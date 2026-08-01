import 'dart:convert';
import 'dart:io';

import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:test/test.dart';

const testVersion = 'test.manifest.version';
const otherVersion = 'other.manifest.version';
const tableFixture = {'123': {'hash': 123}};

Map<String, dynamic> buildManifestResponse(
  String version, {
  List<String>? tables,
}) {
  final list = tables ?? downloadRawTables;
  final en = <String, String>{
    for (final t in list) t: '/common/destiny2/content/json/en/$t.json',
  };
  return {
    'Response': {
      'version': version,
      'jsonWorldComponentContentPaths': {'en': en},
    },
  };
}

ManifestHttpGet createTableFetchMock(
  String version, {
  List<String>? tables,
  void Function(String url)? onCall,
}) {
  final tableList = tables ?? downloadRawTables;
  return (Uri uri, {Map<String, String>? headers}) async {
    onCall?.call(uri.toString());
    final url = uri.toString();
    if (url == kManifestUrl || url.contains('/Platform/Destiny2/Manifest')) {
      return ManifestHttpResponse(
        statusCode: 200,
        body: jsonEncode(buildManifestResponse(version, tables: tableList)),
      );
    }
    for (final table in tableList) {
      if (url.endsWith('$table.json')) {
        return ManifestHttpResponse(
          statusCode: 200,
          body: jsonEncode(tableFixture),
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
    tmp = await Directory.systemTemp.createTemp('dart-018-manifest-');
    root = StorageRoot(basePath: tmp.path);
    await root.ensureLayout();
  });

  tearDown(() async {
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  });

  group('BungieManifestService ensureCurrent', () {
    test('downloads all tables and writes version file', () async {
      final urls = <String>[];
      final service = BungieManifestService(
        storageRoot: root,
        apiKey: 'test-api-key',
        httpGet: createTableFetchMock(testVersion, onCall: urls.add),
      );

      final version = await service.ensureCurrent();
      expect(version, testVersion);

      // 1 metadata + N tables
      expect(urls.length, 1 + downloadRawTables.length);

      for (final table in downloadRawTables) {
        final file = File(root.rawTablePath(testVersion, table));
        expect(await file.exists(), isTrue, reason: table);
        expect(jsonDecode(await file.readAsString()), tableFixture);
      }

      final versionFile = jsonDecode(
        await File(root.currentVersionPath).readAsString(),
      ) as Map;
      expect(versionFile['version'], testVersion);
    });

    test('partial skips tables already on disk', () async {
      for (final table in downloadRawTables) {
        final path = root.rawTablePath(testVersion, table);
        await File(path).parent.create(recursive: true);
        await File(path).writeAsString(jsonEncode(tableFixture));
      }

      var calls = 0;
      final service = BungieManifestService(
        storageRoot: root,
        apiKey: 'test-api-key',
        httpGet: (uri, {headers}) async {
          calls++;
          return ManifestHttpResponse(
            statusCode: 200,
            body: jsonEncode(buildManifestResponse(testVersion)),
          );
        },
      );

      final version = await service.ensureCurrent();
      expect(version, testVersion);
      expect(calls, 1); // metadata only
    });

    test('full re-download overwrites existing tables', () async {
      for (final table in downloadRawTables) {
        final path = root.rawTablePath(testVersion, table);
        await File(path).parent.create(recursive: true);
        await File(path).writeAsString(jsonEncode({'old': true}));
      }

      var tableDownloads = 0;
      final service = BungieManifestService(
        storageRoot: root,
        apiKey: 'test-api-key',
        httpGet: (uri, {headers}) async {
          final url = uri.toString();
          if (url.contains('/Platform/Destiny2/Manifest')) {
            return ManifestHttpResponse(
              statusCode: 200,
              body: jsonEncode(buildManifestResponse(testVersion)),
            );
          }
          tableDownloads++;
          return ManifestHttpResponse(
            statusCode: 200,
            body: jsonEncode(tableFixture),
          );
        },
      );

      await service.ensureCurrent(forceFullDownload: true);
      expect(tableDownloads, downloadRawTables.length);
      final sample = jsonDecode(
        await File(
          root.rawTablePath(testVersion, downloadRawTables.first),
        ).readAsString(),
      );
      expect(sample, tableFixture);
    });

    test('throws without apiKey', () async {
      final service = BungieManifestService(
        storageRoot: root,
        apiKey: null,
      );
      expect(
        () => service.ensureCurrent(),
        throwsA(
          isA<ManifestServiceException>().having(
            (e) => e.message,
            'message',
            contains('BUNGIE_API_KEY'),
          ),
        ),
      );
    });
  });

  group('BungieManifestService getStatus', () {
    test('isStale=true when versions differ', () async {
      await File(root.currentVersionPath).writeAsString(
        jsonEncode({'version': testVersion}),
      );
      final service = BungieManifestService(
        storageRoot: root,
        apiKey: 'k',
        httpGet: createTableFetchMock(otherVersion),
      );
      final status = await service.getStatus();
      expect(status.cachedVersion, testVersion);
      expect(status.remoteVersion, otherVersion);
      expect(status.isStale, isTrue);
    });

    test('isStale=true when nothing is cached', () async {
      final service = BungieManifestService(
        storageRoot: root,
        apiKey: 'k',
        httpGet: createTableFetchMock(testVersion),
      );
      final status = await service.getStatus();
      expect(status.cachedVersion, isNull);
      expect(status.remoteVersion, testVersion);
      expect(status.isStale, isTrue);
    });

    test('isStale=false when versions match', () async {
      await File(root.currentVersionPath).writeAsString(
        jsonEncode({'version': testVersion}),
      );
      final service = BungieManifestService(
        storageRoot: root,
        apiKey: 'k',
        httpGet: createTableFetchMock(testVersion),
      );
      final status = await service.getStatus();
      expect(status.isStale, isFalse);
    });

    test('remoteVersion null when fetch rejects; no cache → still stale',
        () async {
      final service = BungieManifestService(
        storageRoot: root,
        apiKey: 'k',
        httpGet: (uri, {headers}) async {
          throw Exception('network down');
        },
      );
      final status = await service.getStatus();
      expect(status.remoteVersion, isNull);
      expect(status.cachedVersion, isNull);
      expect(status.isStale, isTrue);
    });

    test('remoteVersion null with cache → isStale false', () async {
      await File(root.currentVersionPath).writeAsString(
        jsonEncode({'version': testVersion}),
      );
      final service = BungieManifestService(
        storageRoot: root,
        apiKey: 'k',
        httpGet: (uri, {headers}) async {
          throw Exception('network down');
        },
      );
      final status = await service.getStatus();
      expect(status.remoteVersion, isNull);
      expect(status.cachedVersion, testVersion);
      expect(status.isStale, isFalse);
    });

    test('returns entity cache meta when present', () async {
      await File(root.currentVersionPath).writeAsString(
        jsonEncode({'version': testVersion}),
      );
      final metaPath = root.entityCacheMetaPath(testVersion);
      await File(metaPath).parent.create(recursive: true);
      await File(metaPath).writeAsString(
        jsonEncode({
          'manifestVersion': testVersion,
          'builtAt': '2026-06-12T00:00:00.000Z',
          'counts': {'weapons': 3, 'aspects': 7},
        }),
      );
      final service = BungieManifestService(
        storageRoot: root,
        apiKey: 'k',
        httpGet: createTableFetchMock(testVersion),
      );
      final status = await service.getStatus();
      expect(status.entityCache?.manifestVersion, testVersion);
      expect(status.entityCache?.counts['weapons'], 3);
    });
  });

  group('loadRawTable', () {
    test('round-trips written JSON', () async {
      final table = downloadRawTables.first;
      final path = root.rawTablePath(testVersion, table);
      await File(path).parent.create(recursive: true);
      await File(path).writeAsString(jsonEncode(tableFixture));

      final service = BungieManifestService(
        storageRoot: root,
        apiKey: 'k',
      );
      final loaded = await service.loadRawTable(testVersion, table);
      expect(loaded, tableFixture);
    });

    test('memoizes within a service instance', () async {
      final table = downloadRawTables.first;
      final path = root.rawTablePath(testVersion, table);
      await File(path).parent.create(recursive: true);
      await File(path).writeAsString(jsonEncode(tableFixture));

      final service = BungieManifestService(
        storageRoot: root,
        apiKey: 'k',
      );
      final a = await service.loadRawTable(testVersion, table);
      final b = await service.loadRawTable(testVersion, table);
      expect(identical(a, b), isTrue);
    });

    test('throws when file missing', () async {
      final service = BungieManifestService(
        storageRoot: root,
        apiKey: 'k',
      );
      expect(
        () => service.loadRawTable(testVersion, downloadRawTables.first),
        throwsA(
          isA<ManifestServiceException>().having(
            (e) => e.message,
            'message',
            contains('ensureCurrent()'),
          ),
        ),
      );
    });
  });

  group('computeIsStale', () {
    test('rules', () {
      expect(computeIsStale(null, 'v'), isTrue);
      expect(computeIsStale(null, null), isTrue);
      expect(computeIsStale('v1', null), isFalse);
      expect(computeIsStale('v1', 'v1'), isFalse);
      expect(computeIsStale('v1', 'v2'), isTrue);
    });
  });
}
