import 'dart:io';

import 'package:test/test.dart';

/// Banned symbols for any Fill In surface (matcher, parser, later UI).
///
/// Structural read-only gate: Fill In must never import or construct Bungie
/// write clients, transfer, or equip, and must stay free of `dart:io` /
/// `package:http`. Extends automatically to any `**/fill_in/**/*.dart`
/// under the Flutter workspace (excluding tests).
const List<String> kFillInBannedPatterns = <String>[
  'BungieWriteClient',
  'HttpBungieWriteClient',
  'MockBungieWriteClient',
  'TransferItem',
  'EquipItem',
  'transferItem',
  'equipItem',
  'dismantleItem',
  'DismantleItem',
  'package:destiny2_bungie',
  'dart:io',
  'package:http',
];

/// Exact count of production Fill In Dart sources under `**/fill_in/`.
///
/// Bump when adding a real fill_in library file (not tests).
const int kExpectedFillInSourceFileCount = 6;

void main() {
  test('Fill In sources never import write/transfer/equip/io/http', () {
    final roots = _fillInDartFiles();
    expect(
      roots,
      hasLength(kExpectedFillInSourceFileCount),
      reason:
          'expected exactly $kExpectedFillInSourceFileCount fill_in Dart '
          'sources under flutter/ (got ${roots.length}: '
          '${roots.map((f) => f.path).join(', ')})',
    );

    final violations = <String>[];
    for (final file in roots) {
      final text = file.readAsStringSync();
      for (final pattern in kFillInBannedPatterns) {
        if (text.contains(pattern)) {
          violations.add('${file.path}: contains "$pattern"');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Fill In must stay read-only:\n${violations.join('\n')}',
    );
  });
}

List<File> _fillInDartFiles() {
  final flutterRoot = _findFlutterRoot();
  final files = <File>[];
  for (final entity in flutterRoot.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    final normalized = entity.path.replaceAll('\\', '/');
    if (!normalized.contains('/fill_in/')) continue;
    // Tests may mention banned names while asserting absence — skip test/.
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
