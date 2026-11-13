import 'dart:io';

import 'package:test/test.dart';

/// Banned symbols across every production dim_loadouts source **and** the
/// builds_mock reader-caller files that adopt / match / render the catalog.
/// Networking + writes stay out; fetch lands in a later PR.
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

/// Exact count of guarded production Dart sources.
///
/// - `**/dim_loadouts/**/*.dart` (domain:4 + storage:1 + windows_host panel:1)
/// - builds_mock reader-callers / DIM-link pipeline:
///   page + controller + browse detail + build detail + matrix mapper +
///   matrix loader (=6)
///
/// Bump when adding a real library file (not tests). Was 5 → 9 (PR #21
/// Skeptic), 9 → 10 when Builds mapped real matrix `dim` links, then 10 → 11
/// when the per-build detail screen (DIM panel host) was split out, then
/// 11 → 12 when the matrix loader (read-only Warlock matrix path) was added.
const int kExpectedDimLoadoutsSourceFileCount = 12;

/// Relative paths (posix) of builds_mock files that call the DIM loadouts
/// reader / matcher / panel / supply dim links — included in the exact-count
/// guard.
const List<String> kDimLoadoutsBuildsMockCallerRelativePaths = <String>[
  'apps/windows_host/lib/builds_mock/builds_mock_page.dart',
  'apps/windows_host/lib/builds_mock/builds_mock_controller.dart',
  'apps/windows_host/lib/builds_mock/builds_mock_page_detail.dart',
  'apps/windows_host/lib/builds_mock/builds_mock_page_build_detail.dart',
  'apps/windows_host/lib/builds_mock/builds_mock_matrix.dart',
  'apps/windows_host/lib/builds_mock/builds_mock_matrix_loader.dart',
];

void main() {
  test('dim_loadouts sources stay read-only (exact file count)', () {
    final roots = _guardedDartFiles();
    expect(
      roots,
      hasLength(kExpectedDimLoadoutsSourceFileCount),
      reason:
          'expected exactly $kExpectedDimLoadoutsSourceFileCount '
          'dim_loadouts + builds_mock caller Dart sources under flutter/ '
          '(got ${roots.length}: '
          '${roots.map((f) => f.path).join(', ')})',
    );

    final flutterRoot = _findFlutterRoot();
    final dimOnly = roots
        .where(
          (f) => f.path.replaceAll('\\', '/').contains('/dim_loadouts/'),
        )
        .toList();
    final callers = <File>[
      for (final relative in kDimLoadoutsBuildsMockCallerRelativePaths)
        File('${flutterRoot.path}/$relative'),
    ];
    expect(
      roots.length,
      dimOnly.length + callers.length,
      reason:
          'guard must scan only dim_loadouts folders + listed builds_mock '
          'callers (nothing extra); '
          'dimOnly=${dimOnly.length} callers=${callers.length} '
          'total=${roots.length}',
    );
    expect(
      roots.any(
        (f) => f.path.replaceAll('\\', '/').endsWith('builds_mock_apply.dart'),
      ),
      isFalse,
      reason:
          'builds_mock_apply.dart is the Bungie write path — it must stay '
          'out of this read-only guard (covered by apply_path_no_dismantle)',
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

List<File> _guardedDartFiles() {
  final flutterRoot = _findFlutterRoot();
  final files = <File>[];
  final seen = <String>{};

  void add(File file) {
    final key = file.path.replaceAll('\\', '/');
    if (seen.add(key)) files.add(file);
  }

  for (final entity in flutterRoot.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    final normalized = entity.path.replaceAll('\\', '/');
    if (!normalized.contains('/dim_loadouts/')) continue;
    if (normalized.contains('/test/')) continue;
    add(entity);
  }

  for (final relative in kDimLoadoutsBuildsMockCallerRelativePaths) {
    final file = File('${flutterRoot.path}/$relative');
    if (!file.existsSync()) {
      throw StateError('missing builds_mock caller: ${file.path}');
    }
    add(file);
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
