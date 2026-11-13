import 'dart:io';

import 'package:test/test.dart';

/// Apply-to-character path must never reference dismantle/delete/destroy
/// or transfer-to-delete style APIs. Equip + vault transfer for equip remain OK.
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
];

/// Exact apply-path sources (posix-ish relative to packages/app).
///
/// Includes the host Builds mock Apply wiring — the only non-package caller of
/// a Bungie write. Exact list (not a glob) so a missing file fails loudly.
const List<String> kApplyPathRelativeFiles = <String>[
  'lib/src/equip/apply_to_character.dart',
  '../bungie/lib/src/write/equip_orchestrator.dart',
  '../bungie/lib/src/write/write_client.dart',
  '../../apps/windows_host/lib/builds_mock/builds_mock_apply.dart',
];

void main() {
  test('apply path sources never reference dismantle/delete/destroy', () {
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
        if (text.contains(pattern)) {
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

  test('BungieWriteClient surface has only transfer/equip/artifact/fashion',
      () {
    final appRoot = _findAppPackageRoot();
    final file = File(
      '${appRoot.path}/../bungie/lib/src/write/write_client.dart',
    );
    final text = file.readAsStringSync();
    expect(text, contains('transferItem'));
    expect(text, contains('equipItem'));
    expect(text, contains('applyArtifactConfig'));
    expect(text, contains('applyFashionSlot'));
    expect(text.contains('dismantleItem'), isFalse);
    expect(text.contains('DismantleItem'), isFalse);
    expect(text.contains('destroyItem'), isFalse);
    expect(text.contains('/Destiny2/Actions/Items/Dismantle'), isFalse);
    expect(text.contains('transferToDelete'), isFalse);
  });
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
