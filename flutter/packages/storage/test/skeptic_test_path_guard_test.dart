import 'dart:io';

import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support/test_temp_path_guard.dart';

/// Skeptic plan item 2 (2026-11-20): resolved test paths must stay under
/// system temp — not `/opt/cursor/artifacts` or other non-temp roots.
void main() {
  test(
    'Skeptic #2 positive: resolved systemTemp child is allowed',
    () async {
      final dir = await Directory.systemTemp.createTemp('skeptic_path_ok_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      expect(() => assertResolvedPathIsUnderSystemTemp(dir.path), returnsNormally);
      expect(
        () => assertResolvedPathIsUnderSystemTemp(p.join(dir.path, 'cache.csv')),
        returnsNormally,
      );
    },
  );

  test(
    'Skeptic #2: resolved /opt/cursor/artifacts path fails closed',
    () {
      expect(
        () => assertResolvedPathIsUnderSystemTemp('/opt/cursor/artifacts/x'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('outside system temp'),
          ),
        ),
      );
    },
  );

  test(
    'Skeptic #2: symlink escape via non-existent child fails closed',
    () async {
      final varTmp = Directory('/var/tmp');
      final systemTemp = Directory.systemTemp.path;
      final varTmpResolved = varTmp.existsSync()
          ? p.normalize(varTmp.resolveSymbolicLinksSync())
          : '';
      final systemResolved = p.normalize(
        Directory.systemTemp.resolveSymbolicLinksSync(),
      );
      if (!varTmp.existsSync() || varTmpResolved == systemResolved) {
        // Posix hosts where /var/tmp is missing or aliases systemTemp.
        return;
      }

      final temp = await Directory.systemTemp.createTemp('skeptic_link_');
      // Outside systemTemp without touching Directory.current (repo cwd).
      final outside = await varTmp.createTemp('skeptic_outside_');
      addTearDown(() async {
        if (await temp.exists()) await temp.delete(recursive: true);
        if (await outside.exists()) await outside.delete(recursive: true);
      });
      final tempRoot = resolvePathForTempGuard(systemTemp);
      final outsideResolved = resolvePathForTempGuard(outside.path);
      expect(
        outsideResolved == tempRoot || p.isWithin(tempRoot, outsideResolved),
        isFalse,
        reason: 'fixture must resolve outside systemTemp',
      );
      final link = Link(p.join(temp.path, 'escape'));
      await link.create(outside.path, recursive: false);
      // Path does not exist yet under the symlink — nearest-parent resolve.
      final nested = p.join(link.path, 'new', 'cache.csv');
      expect(
        () => assertResolvedPathIsUnderSystemTemp(nested),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('outside system temp'),
          ),
        ),
      );
    },
    testOn: 'posix',
  );

  test(
    'Skeptic #2: dangling symlink that points outside fails closed',
    () async {
      final temp = await Directory.systemTemp.createTemp('skeptic_dangling_');
      addTearDown(() async {
        if (await temp.exists()) await temp.delete(recursive: true);
      });
      final dangling = Link(p.join(temp.path, 'dangling'));
      // Target does not exist — resolveSymbolicLinksSync throws.
      await dangling.create('/opt/cursor/artifacts/no-such-skeptic-target');
      expect(
        () => assertResolvedPathIsUnderSystemTemp(dangling.path),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('could not be resolved'),
          ),
        ),
      );
    },
  );

  test(
    'Skeptic #2: skeptic cache importer root stays under systemTemp',
    () async {
      final dir = await Directory.systemTemp.createTemp('skeptic_cache_root_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      assertResolvedPathIsUnderSystemTemp(dir.path);
      final root = StorageRoot(basePath: dir.path);
      assertResolvedPathIsUnderSystemTemp(root.dimArmorInventoryCachePath);
      assertResolvedPathIsUnderSystemTemp(root.dimWeaponsInventoryCachePath);
    },
  );

  test(
    'Skeptic #2 repo-wide: flutter tests must not reference /opt/cursor/artifacts',
    () {
      final roots = _candidateTestRoots();
      expect(roots, isNotEmpty, reason: 'must locate flutter test trees');

      final violations = <String>[];
      final artifact = RegExp(r'/opt/cursor/artifacts');

      for (final root in roots) {
        for (final entity in root.listSync(recursive: true)) {
          if (entity is! File) continue;
          if (!entity.path.endsWith('_test.dart')) continue;
          if (p.basename(entity.path) == 'skeptic_test_path_guard_test.dart') {
            continue;
          }
          final text = entity.readAsStringSync();
          if (artifact.hasMatch(text)) {
            violations.add(
              '${p.relative(entity.path, from: root.parent.path)} '
              'mentions /opt/cursor/artifacts',
            );
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'forbidden test path usage:\n${violations.join('\n')}',
      );
    },
  );
}

List<Directory> _candidateTestRoots() {
  final out = <Directory>[];
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final flutter = Directory(p.join(dir.path, 'flutter'));
    final packages = Directory(p.join(dir.path, 'packages'));
    final apps = Directory(p.join(dir.path, 'apps'));
    if (flutter.existsSync()) {
      out.add(Directory(p.join(flutter.path, 'packages')));
      out.add(Directory(p.join(flutter.path, 'apps')));
      break;
    }
    if (packages.existsSync() && apps.existsSync()) {
      out.add(packages);
      out.add(apps);
      break;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return [
    for (final d in out)
      if (d.existsSync()) d,
  ];
}
