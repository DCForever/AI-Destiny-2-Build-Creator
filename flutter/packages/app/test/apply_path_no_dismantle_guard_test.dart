import 'dart:io';

import 'package:test/test.dart';

/// Apply-to-character path must never reference dismantle/delete/destroy,
/// paid insert-plug, InsertPlug, or pull-from-postmaster APIs.
///
/// CHANGED (InsertSocketPlugFree): the previous ban on the substring
/// `InsertSocketPlug` / `/Destiny2/Actions/Items/InsertSocketPlug` also
/// matched the Free endpoint. Guard now allows exactly
/// `/Destiny2/Actions/Items/InsertSocketPlugFree/` and still bans the paid
/// `/Destiny2/Actions/Items/InsertSocketPlug/` (and InsertPlug / dismantle /
/// delete / postmaster / lock / track).
const List<String> kBannedApplyPatterns = <String>[
  'dismantleItem',
  'DismantleItem',
  'Dismantle',
  '/Destiny2/Actions/Items/Dismantle',
  'destroyItem',
  'DestroyItem',
  'deleteItem(',
  'DeleteItem',
  'transferToDelete',
  'TransferToDelete',
  'transfer_to_delete',
  'TransferToVaultToDelete',
  'InsertPlug',
  'insertPlug',
  'PullFromPostmaster',
  'pullFromPostmaster',
  '/Destiny2/Actions/Items/PullFromPostmaster',
  '/Destiny2/Actions/Items/InsertSocketPlug/',
  'SetLockState',
  'setLockState',
  '/Destiny2/Actions/Items/SetLockState',
  'SetTrackedState',
  'setTrackedState',
  '/Destiny2/Actions/Items/SetTrackedItem',
  '/Destiny2/Actions/Items/SetTrackedState',
];

/// Exact Free endpoint that Apply may call (must appear when Free is wired).
const String kAllowedInsertSocketPlugFreePath =
    '/Destiny2/Actions/Items/InsertSocketPlugFree/';

/// Exact paid endpoint that must never appear anywhere under packages/*/lib.
const String kBannedPaidInsertSocketPlugPath =
    '/Destiny2/Actions/Items/InsertSocketPlug/';

/// Exact apply-path sources (posix-ish relative to packages/app).
///
/// Includes the host Builds mock Apply wiring — the only non-package caller of
/// a Bungie write. Exact list (not a glob) so a missing file fails loudly.
/// Dry-run confirm dialog was removed (Apply itself confirms); list stays
/// exact and still bans dismantle/delete/plug/postmaster.
const List<String> kApplyPathRelativeFiles = <String>[
  'lib/src/equip/apply_to_character.dart',
  'lib/src/equip/apply_sockets.dart',
  'lib/src/equip/apply_socket_plan.dart',
  '../bungie/lib/src/write/equip_orchestrator.dart',
  '../bungie/lib/src/write/write_client.dart',
  '../../apps/windows_host/lib/builds_mock/builds_mock_apply.dart',
];

void main() {
  test('apply path sources never reference dismantle/delete/paid plug', () {
    final appRoot = _findAppPackageRoot();
    final violations = <String>[];
    final scanned = <String>[];
    for (final rel in kApplyPathRelativeFiles) {
      final file = File('${appRoot.path}/$rel');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'apply-path guard file missing (must exist + be scanned): '
            '${file.path}',
      );
      scanned.add(file.path.replaceAll('\\', '/'));
      final text = file.readAsStringSync();
      for (final pattern in kBannedApplyPatterns) {
        if (_containsBannedPattern(text, pattern)) {
          violations.add('${file.path}: contains "$pattern"');
        }
      }
    }
    expect(
      scanned,
      hasLength(kApplyPathRelativeFiles.length),
      reason: 'expected every listed apply-path file to be scanned',
    );
    expect(
      scanned.any((p) => p.endsWith('builds_mock_apply.dart')),
      isTrue,
      reason: 'builds_mock_apply.dart must be on the exact scan list',
    );
    expect(
      violations,
      isEmpty,
      reason: 'Apply path must never dismantle/delete:\n${violations.join('\n')}',
    );
  });

  test('write client allows InsertSocketPlugFree and bans paid InsertSocketPlug',
      () {
    final appRoot = _findAppPackageRoot();
    final file = File(
      '${appRoot.path}/../bungie/lib/src/write/write_client.dart',
    );
    final text = file.readAsStringSync();
    expect(text, contains('transferItem'));
    expect(text, contains('equipItem'));
    expect(text, contains('equipItems'));
    expect(text, contains('insertSocketPlugFree'));
    expect(text, contains(kAllowedInsertSocketPlugFreePath));
    expect(text, contains('applyArtifactConfig'));
    expect(text, contains('applyFashionSlot'));
    expect(text.contains('dismantleItem'), isFalse);
    expect(text.contains('DismantleItem'), isFalse);
    expect(text.contains('destroyItem'), isFalse);
    expect(text.contains('/Destiny2/Actions/Items/Dismantle'), isFalse);
    expect(text.contains('transferToDelete'), isFalse);
    // Bare InsertPlug (AWA paid helper name) must not appear; Free method names
    // use InsertSocketPlugFree and are allowed.
    expect(
      RegExp(r'(?<![A-Za-z])InsertPlug(?![A-Za-z])').hasMatch(text),
      isFalse,
    );
    expect(text.contains('PullFromPostmaster'), isFalse);
    expect(text.contains('/Destiny2/Actions/Items/PullFromPostmaster'), isFalse);
    expect(text.contains('SetLockState'), isFalse);
    expect(text.contains('SetTrackedState'), isFalse);
    expect(text.contains('/Destiny2/Actions/Items/SetLockState'), isFalse);
    // Paid path string may appear only inside a ban/comment about never calling
    // it; the POST path must be Free. Fail if a postJson targets the paid path.
    expect(
      RegExp(
        "postJson\\(\\s*['\"]/Destiny2/Actions/Items/InsertSocketPlug/['\"]",
      ).hasMatch(text),
      isFalse,
      reason: 'HttpBungieWriteClient must never POST the paid InsertSocketPlug',
    );
  });

  test('paid InsertSocketPlug path never appears under packages/*/lib', () {
    final appRoot = _findAppPackageRoot();
    final packagesRoot = Directory('${appRoot.path}/..');
    final violations = <String>[];
    for (final entity in packagesRoot.listSync(followLinks: false)) {
      if (entity is! Directory) continue;
      final libDir = Directory('${entity.path}/lib');
      if (!libDir.existsSync()) continue;
      for (final file in libDir.listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        final text = file.readAsStringSync();
        if (_containsPaidInsertSocketPlugCall(text)) {
          violations.add(file.path.replaceAll('\\', '/'));
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason: 'paid InsertSocketPlug must not appear in lib/:\n'
          '${violations.join('\n')}',
    );
  });
}

/// True when [text] contains [pattern], except the paid InsertSocketPlug path
/// is allowed only as a documented ban (never as a postJson target). Free
/// endpoint containing the paid prefix is not a hit for the paid pattern.
bool _containsBannedPattern(String text, String pattern) {
  if (pattern != kBannedPaidInsertSocketPlugPath) {
    return text.contains(pattern);
  }
  return _containsPaidInsertSocketPlugCall(text);
}

/// Paid path hits that are not the Free endpoint suffix.
bool _containsPaidInsertSocketPlugCall(String text) {
  var start = 0;
  while (true) {
    final idx = text.indexOf(kBannedPaidInsertSocketPlugPath, start);
    if (idx < 0) return false;
    final after = idx + kBannedPaidInsertSocketPlugPath.length;
    // Free path is `...InsertSocketPlug/` + `Free/` — skip those.
    if (after + 4 <= text.length && text.substring(after, after + 4) == 'Free') {
      start = after;
      continue;
    }
    return true;
  }
}

Directory _findAppPackageRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${dir.path}/lib/src/equip/apply_to_character.dart');
    if (candidate.existsSync()) return dir;
    final nested = File(
      '${dir.path}/packages/app/lib/src/equip/apply_to_character.dart',
    );
    if (nested.existsSync()) return Directory('${dir.path}/packages/app');
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError('packages/app not found from ${Directory.current.path}');
}
