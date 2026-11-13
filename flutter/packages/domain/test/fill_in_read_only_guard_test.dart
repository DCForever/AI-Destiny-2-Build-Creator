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

/// Exact production Fill In Dart source counts (exclude `test/`).
///
/// Exact counts so the guard cannot pass vacuously or silently drop files.
/// Domain was 10 → 11 when `fill_in_dim_loadout.dart` was added (DIM loadout
/// → Fill In piece extraction; still pure / no IO / no writes).
const int kDomainFillInSourceFileCount = 11;
const int kWindowsHostFillInSourceFileCount = 4;

void main() {
  test('Fill In sources never import write/transfer/equip/io/http', () {
    final roots = _fillInDartFiles();
    final domain = roots
        .where((f) => _normalized(f).contains('/packages/domain/lib/src/fill_in/'))
        .toList();
    final host = roots
        .where(
          (f) => _normalized(f).contains('/apps/windows_host/lib/fill_in/'),
        )
        .toList();

    expect(
      domain,
      hasLength(kDomainFillInSourceFileCount),
      reason:
          'expected exactly $kDomainFillInSourceFileCount domain fill_in '
          'sources (got ${domain.length}: '
          '${domain.map((f) => f.path).join(', ')})',
    );
    expect(
      host,
      hasLength(kWindowsHostFillInSourceFileCount),
      reason:
          'expected exactly $kWindowsHostFillInSourceFileCount windows_host '
          'fill_in sources (got ${host.length}: '
          '${host.map((f) => f.path).join(', ')})',
    );
    expect(
      roots.length,
      domain.length + host.length,
      reason:
          'guard must scan only domain + windows_host fill_in folders; '
          'extra: ${roots.where((f) => !domain.contains(f) && !host.contains(f)).map((f) => f.path).join(', ')}',
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

String _normalized(File file) => file.path.replaceAll('\\', '/');

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
