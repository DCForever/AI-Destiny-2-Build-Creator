import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Skeptic plan item 2 (2026-11-20): no writes to `/opt/cursor/artifacts`
/// from tests; skeptic cache fixtures stay under Directory.systemTemp.
///
/// Drive-letter strings may appear as *values* under test (path settings),
/// but the live File IO target for those suites is TempDir — this guard
/// focuses on the Destiny-13 regression: writing agent artifact paths.
void main() {
  test(
    'Skeptic #2: tests must not reference /opt/cursor/artifacts',
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

  test(
    'Skeptic #2: skeptic cache tests use Directory.systemTemp only',
    () async {
      final dir = await Directory.systemTemp.createTemp('skeptic_path_ok_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      expect(
        p.isWithin(Directory.systemTemp.path, dir.path) ||
            dir.path.startsWith(Directory.systemTemp.path),
        isTrue,
      );
      expect(dir.path.contains('/opt/cursor/artifacts'), isFalse);
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
