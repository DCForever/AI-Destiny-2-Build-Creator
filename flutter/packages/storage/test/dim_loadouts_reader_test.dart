import 'dart:io';

import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late StorageRoot root;
  late DimLoadoutsReader reader;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dim-loadouts-reader-');
    root = StorageRoot(basePath: tempDir.path);
    reader = DimLoadoutsReader(root: root);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('missing file → notLoaded with empty loadouts', () async {
    expect(await File(root.dimLoadoutsCachePath).exists(), isFalse);
    final result = await reader.load();
    expect(result.status, DimLoadoutsReadStatus.notLoaded);
    expect(result.loadouts, isEmpty);
    expect(result.catalog, isNull);
    // Still must not create the path.
    expect(await File(root.dimLoadoutsCachePath).exists(), isFalse);
    expect(await Directory(root.dimLoadoutsDir).exists(), isFalse);
  });

  test('valid fixture → loaded catalog', () async {
    await _writeFixture(root);
    final result = await reader.load();
    expect(result.status, DimLoadoutsReadStatus.loaded);
    expect(result.loadouts, hasLength(3));
    expect(result.catalog!.schemaVersion, 1);
  });

  test('truncated JSON → unreadable, no partial list', () async {
    await Directory(root.dimLoadoutsDir).create(recursive: true);
    await File(root.dimLoadoutsCachePath).writeAsString('{ "schemaVersion":');
    final result = await reader.load();
    expect(result.status, DimLoadoutsReadStatus.unreadable);
    expect(result.loadouts, isEmpty);
    expect(result.catalog, isNull);
  });

  test('wrong schemaVersion → unreadable, no partial list', () async {
    await _writeFixture(root, schemaVersion: 99);
    final result = await reader.load();
    expect(result.status, DimLoadoutsReadStatus.unreadable);
    expect(result.loadouts, isEmpty);
    expect(result.detail, contains('schemaVersion'));
  });

  test('oversized file → unreadable before content use', () async {
    await Directory(root.dimLoadoutsDir).create(recursive: true);
    await File(root.dimLoadoutsCachePath).writeAsBytes(
      List<int>.filled(64, 7),
      flush: true,
    );
    final capped = DimLoadoutsReader(root: root, maxBytes: 8);
    final result = await capped.load();
    expect(result.status, DimLoadoutsReadStatus.unreadable);
    expect(result.detail, contains('size limit'));
    expect(result.loadouts, isEmpty);
  });

  test('path is a directory → unreadable (not a partial catalog)', () async {
    // File.exists() is false for directories on this host; type check fail-closes.
    await Directory(root.dimLoadoutsCachePath).create(recursive: true);
    final result = await reader.load();
    expect(result.status, DimLoadoutsReadStatus.unreadable);
    expect(result.loadouts, isEmpty);
    expect(result.catalog, isNull);
    expect(result.detail, contains('not a regular file'));
  });

  test('FileSystemException during read → unreadable', () async {
    await Directory(root.dimLoadoutsDir).create(recursive: true);
    await File(root.dimLoadoutsCachePath).writeAsString(
      '{"schemaVersion":1}',
      flush: true,
    );
    final broken = DimLoadoutsReader(
      root: root,
      readBytes: (path, {int? maxBytes}) async {
        throw const FileSystemException('Permission denied', '');
      },
    );
    final result = await broken.load();
    expect(result.status, DimLoadoutsReadStatus.unreadable);
    expect(result.loadouts, isEmpty);
    expect(result.catalog, isNull);
    expect(result.detail, contains('Permission denied'));
  });

  test('StorageRoot documents dim_loadouts path segments', () {
    expect(root.dimLoadoutsDir, p.join(tempDir.path, 'dim_loadouts'));
    expect(
      root.dimLoadoutsCachePath,
      p.join(tempDir.path, 'dim_loadouts', 'dim-loadouts.json'),
    );
  });
}

Future<void> _writeFixture(
  StorageRoot root, {
  int schemaVersion = 1,
}) async {
  await Directory(root.dimLoadoutsDir).create(recursive: true);
  final text = File(_fixturePath()).readAsStringSync().replaceFirst(
        '"schemaVersion": 1',
        '"schemaVersion": $schemaVersion',
      );
  await File(root.dimLoadoutsCachePath).writeAsString(text, flush: true);
}

String _fixturePath() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File(
      '${dir.path}/../domain/test/fixtures/dim_loadouts_min.json',
    );
    if (candidate.existsSync()) return candidate.path;
    final fromFlutter = File(
      '${dir.path}/packages/domain/test/fixtures/dim_loadouts_min.json',
    );
    if (fromFlutter.existsSync()) return fromFlutter.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError('dim_loadouts_min.json not found');
}
