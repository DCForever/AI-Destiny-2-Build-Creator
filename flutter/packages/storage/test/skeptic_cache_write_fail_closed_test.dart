import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Skeptic plan item 4 (2026-11-20): a failed cache write leaves the live
/// file unchanged; no Force overwrite of live data.
void main() {
  late Directory tempDir;
  late StorageRoot root;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('skeptic_cache_');
    assertResolvedPathIsUnderSystemTemp(tempDir.path);
    root = StorageRoot(basePath: tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'Skeptic #4: failed armor cache write leaves live file unchanged',
    () async {
      final importer = DimArmorCsvImporter(root: root);
      final source = await _copyFixture(tempDir, 'destiny-armor.csv');
      final first = await importer.importFromPath(source.path);
      expect(first.isOk, isTrue, reason: first.error);
      final before = await File(importer.cachePath).readAsBytes();
      final beforeHash = sha256.convert(before);

      final failing = DimArmorCsvImporter(
        root: root,
        beforeCacheRename: () async {
          throw StateError('simulated write failure');
        },
      );
      final second = await failing.importFromPath(source.path);
      expect(second.isOk, isFalse);
      expect(second.error, contains("Couldn't write cache"));

      final after = await File(importer.cachePath).readAsBytes();
      expect(sha256.convert(after).toString(), beforeHash.toString());
      expect(after, before);
      expect(
        await File('${importer.cachePath}.tmp').exists(),
        isFalse,
        reason: 'failed rename must not leave a Force-overwrite path',
      );
    },
  );

  test(
    'Skeptic #4: failed weapons cache write leaves live file unchanged',
    () async {
      final importer = DimWeaponsCsvImporter(root: root);
      final source = await _copyWeaponsFixture(tempDir, 'destiny-weapons.csv');
      final first = await importer.importFromPath(source.path);
      expect(first.isOk, isTrue, reason: first.error);
      final before = await File(importer.cachePath).readAsBytes();
      final beforeHash = sha256.convert(before);

      final failing = DimWeaponsCsvImporter(
        root: root,
        beforeCacheRename: () async {
          throw StateError('simulated write failure');
        },
      );
      final second = await failing.importFromPath(source.path);
      expect(second.isOk, isFalse);
      expect(second.error, contains("Couldn't write cache"));

      final after = await File(importer.cachePath).readAsBytes();
      expect(sha256.convert(after).toString(), beforeHash.toString());
      expect(after, before);
    },
  );
}

Future<File> _copyFixture(Directory dir, String name) async {
  final bytes = await File(_armorFixturePath()).readAsBytes();
  final out = File(p.join(dir.path, name));
  await out.writeAsBytes(bytes, flush: true);
  return out;
}

Future<File> _copyWeaponsFixture(Directory dir, String name) async {
  final bytes = await File(_weaponsFixturePath()).readAsBytes();
  final out = File(p.join(dir.path, name));
  await out.writeAsBytes(bytes, flush: true);
  return out;
}

String _armorFixturePath() => _findFixture('dim_armor_min.csv');

String _weaponsFixturePath() => _findFixture('dim_weapons_min.csv');

String _findFixture(String name) {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${dir.path}/../domain/test/fixtures/$name');
    if (candidate.existsSync()) return candidate.path;
    final nested = File('${dir.path}/packages/domain/test/fixtures/$name');
    if (nested.existsSync()) return nested.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError('$name not found from ${Directory.current.path}');
}
