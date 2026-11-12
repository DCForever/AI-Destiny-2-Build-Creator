import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late StorageRoot root;
  late DimArmorCsvImporter importer;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dim-armor-import-');
    root = StorageRoot(basePath: tempDir.path);
    importer = DimArmorCsvImporter(root: root);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('import leaves the source file byte-for-byte unchanged', () async {
    final source = await _copyFixture(tempDir, 'destiny-armor.csv');
    final before = sha256.convert(await source.readAsBytes());

    final result = await importer.importFromPath(source.path);
    expect(result.isOk, isTrue, reason: result.error);

    final after = sha256.convert(await source.readAsBytes());
    expect(after.toString(), before.toString());
    expect(await source.readAsBytes(), await File(_fixturePath()).readAsBytes());
  });

  test('import leaves Mario files in the same folder unchanged', () async {
    final source = await _copyFixture(tempDir, 'destiny-armor.csv');
    final mario = <String, List<int>>{
      'warlock-matrix.json': [1, 2, 3],
      'personalize-queue.csv': [4, 5],
      'dim-icons.json': [6, 7, 8, 9],
    };
    for (final entry in mario.entries) {
      await File(p.join(tempDir.path, entry.key)).writeAsBytes(entry.value);
    }
    final hashesBefore = {
      for (final name in mario.keys)
        name: sha256.convert(
          await File(p.join(tempDir.path, name)).readAsBytes(),
        ),
    };

    final result = await importer.importFromPath(source.path);
    expect(result.isOk, isTrue, reason: result.error);

    for (final name in mario.keys) {
      final after = sha256.convert(
        await File(p.join(tempDir.path, name)).readAsBytes(),
      );
      expect(after.toString(), hashesBefore[name].toString());
      expect(
        await File(p.join(tempDir.path, name)).readAsBytes(),
        mario[name],
      );
    }
  });

  test('cache lives under StorageRoot fill_in and survives reload', () async {
    final source = await _copyFixture(tempDir, 'destiny-armor.csv');
    expect(
      importer.cachePath,
      p.join(tempDir.path, 'fill_in', 'dim_armor_inventory.csv'),
    );

    final first = await importer.importFromPath(source.path);
    expect(first.isOk, isTrue, reason: first.error);
    expect(File(importer.cachePath).existsSync(), isTrue);

    final reloaded = await importer.loadCache();
    expect(reloaded.isOk, isTrue, reason: reloaded.error);
    expect(reloaded.items!.length, first.items!.length);
  });

  test('refuses Mario filenames as the import source', () async {
    final mario = File(p.join(tempDir.path, 'warlock-matrix.json'));
    await mario.writeAsString('{}');
    final result = await importer.importFromPath(mario.path);
    expect(result.isOk, isFalse);
    expect(result.error, contains('Mario'));
  });

  test('failed parse does not create a cache file', () async {
    final bad = File(p.join(tempDir.path, 'bad.csv'));
    await bad.writeAsString('Foo,Bar\n1,2\n');
    final result = await importer.importFromPath(bad.path);
    expect(result.isOk, isFalse);
    expect(File(importer.cachePath).existsSync(), isFalse);
  });

  test('StorageRoot documents the cache path segments', () {
    expect(root.fillInCacheDir, p.join(tempDir.path, 'fill_in'));
    expect(
      root.dimArmorInventoryCachePath,
      p.join(tempDir.path, 'fill_in', 'dim_armor_inventory.csv'),
    );
  });
}

Future<File> _copyFixture(Directory dir, String name) async {
  final bytes = await File(_fixturePath()).readAsBytes();
  final out = File(p.join(dir.path, name));
  await out.writeAsBytes(bytes, flush: true);
  return out;
}

String _fixturePath() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File(
      '${dir.path}/../domain/test/fixtures/dim_armor_min.csv',
    );
    if (candidate.existsSync()) return candidate.path;
    final nested = File(
      '${dir.path}/packages/domain/test/fixtures/dim_armor_min.csv',
    );
    if (nested.existsSync()) return nested.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'dim_armor_min.csv not found from ${Directory.current.path}',
  );
}
