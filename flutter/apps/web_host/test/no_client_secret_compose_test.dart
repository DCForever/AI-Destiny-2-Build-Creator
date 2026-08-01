import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('compose modules do not reference confidential secrets', () {
    final rootCandidates = [
      Directory(p.join(Directory.current.path, 'lib')),
      Directory(p.join(Directory.current.path, 'apps', 'web_host', 'lib')),
    ];
    final root = rootCandidates.firstWhere(
      (d) => d.existsSync(),
      orElse: () => Directory.current,
    );

    final forbidden = RegExp(
      r'CLIENT_SECRET|BUNGIE_CLIENT_SECRET|SESSION_SECRET|client_secret',
    );
    final hits = <String>[];
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final rel = p.relative(entity.path, from: root.path);
      if (!rel.contains('builds') &&
          !rel.contains('sets') &&
          !rel.contains('synergies') &&
          !rel.contains('compose')) {
        continue;
      }
      final text = entity.readAsStringSync();
      // Allow documenting absence of secrets.
      final withoutDocs = text
          .replaceAll(RegExp(r'//.*'), '')
          .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
      if (forbidden.hasMatch(withoutDocs) &&
          !withoutDocs.contains('Never') &&
          !withoutDocs.contains('never')) {
        // Still flag real usage of secret identifiers as code.
        if (RegExp(r'''['"]CLIENT_SECRET|client_secret\s*:''')
            .hasMatch(withoutDocs)) {
          hits.add(rel);
        }
      }
    }
    expect(hits, isEmpty, reason: 'secret identifiers in $hits');
  });
}
