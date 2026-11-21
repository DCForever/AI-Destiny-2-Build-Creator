import 'dart:io';

import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

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
    'Skeptic #2: symlink that escapes systemTemp fails closed',
    () async {
      final temp = await Directory.systemTemp.createTemp('skeptic_link_');
      // Outside systemTemp on purpose (repo/workspace path, not /tmp).
      final outside = Directory(
        p.join(Directory.current.path, '.skeptic_outside_path_guard'),
      );
      await outside.create(recursive: true);
      addTearDown(() async {
        if (await temp.exists()) await temp.delete(recursive: true);
        if (await outside.exists()) await outside.delete(recursive: true);
      });
      expect(
        p.isWithin(Directory.systemTemp.path, outside.path),
        isFalse,
        reason: 'fixture must resolve outside systemTemp',
      );
      final link = Link(p.join(temp.path, 'escape'));
      await link.create(outside.path, recursive: false);
      expect(
        () => assertResolvedPathIsUnderSystemTemp(link.path),
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
}
