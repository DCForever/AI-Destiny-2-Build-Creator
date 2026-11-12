import 'dart:io';

import 'package:test/test.dart';

/// Banned symbols across every production `**/dim_loadouts/**/*.dart` file
/// (domain, storage, windows_host). Networking + writes stay out; fetch lands
/// in a later PR.
const List<String> kDimLoadoutsBannedPatterns = <String>[
  'HttpClient',
  'Socket',
  'WebSocket',
  'package:http',
  'BungieWriteClient',
  'url_launcher',
  'writeAsString',
  'writeAsBytes',
  'openWrite',
  'renameSync',
  'deleteSync',
  'FileMode.write',
  '.rename(',
  '.delete(',
  '.create(',
  'createSync',
];

/// Exact count of production dim_loadouts Dart sources under flutter/.
///
/// Bump when adding a real dim_loadouts library file (not tests).
/// domain:3 + storage:1 + windows_host:1 = 5.
const int kExpectedDimLoadoutsSourceFileCount = 5;

void main() {
  test('dim_loadouts sources stay read-only (exact file count)', () {
    final roots = _dimLoadoutsDartFiles();
    expect(
      roots,
      hasLength(kExpectedDimLoadoutsSourceFileCount),
      reason:
          'expected exactly $kExpectedDimLoadoutsSourceFileCount '
          'dim_loadouts Dart sources under flutter/ (got ${roots.length}: '
          '${roots.map((f) => f.path).join(', ')})',
    );

    final violations = <String>[];
    for (final file in roots) {
      final text = file.readAsStringSync();
      for (final pattern in kDimLoadoutsBannedPatterns) {
        if (text.contains(pattern)) {
          violations.add('${file.path}: contains "$pattern"');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'dim_loadouts must stay read-only / offline:\n'
          '${violations.join('\n')}',
    );
  });
}

List<File> _dimLoadoutsDartFiles() {
  final flutterRoot = _findFlutterRoot();
  final files = <File>[];
  for (final entity in flutterRoot.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    final normalized = entity.path.replaceAll('\\', '/');
    if (!normalized.contains('/dim_loadouts/')) continue;
    if (normalized.contains('/test/')) continue;
    files.add(entity);
  }
  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}

Directory _findFlutterRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = Directory('${dir.path}/packages/domain');
    if (candidate.existsSync()) {
      return dir;
    }
    final nested = Directory('${dir.path}/flutter/packages/domain');
    if (nested.existsSync()) {
      return Directory('${dir.path}/flutter');
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'flutter workspace root not found from ${Directory.current.path}',
  );
}
