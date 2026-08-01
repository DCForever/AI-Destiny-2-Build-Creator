import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('equip/export modules do not reference confidential secrets', () {
    final rootCandidates = [
      Directory(p.join(Directory.current.path, 'lib')),
      Directory(p.join(Directory.current.path, 'apps', 'web_host', 'lib')),
    ];
    final root = rootCandidates.firstWhere(
      (d) => d.existsSync(),
      orElse: () => Directory.current,
    );

    final forbidden = RegExp(
      r'''['"]CLIENT_SECRET|client_secret\s*:|BUNGIE_CLIENT_SECRET|SESSION_SECRET''',
    );
    final hits = <String>[];
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final rel = p.relative(entity.path, from: root.path);
      if (!rel.contains('equip') &&
          !rel.contains('dim_export') &&
          !rel.contains('main.client') &&
          !rel.contains('compose_services') &&
          !rel.contains('build_compose')) {
        continue;
      }
      final text = entity.readAsStringSync();
      final withoutDocs = text
          .replaceAll(RegExp(r'//.*'), '')
          .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
      if (forbidden.hasMatch(withoutDocs)) {
        hits.add(rel);
      }
    }
    expect(hits, isEmpty, reason: 'secret identifiers in $hits');
  });
}
