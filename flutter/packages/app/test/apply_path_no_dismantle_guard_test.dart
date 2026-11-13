import 'dart:io';

import 'package:test/test.dart';

/// Apply-to-character path must never reference dismantle/delete/destroy.
const List<String> kBannedApplyPatterns = <String>[
  'dismantleItem',
  'DismantleItem',
  'Dismantle',
  '/Destiny2/Actions/Items/Dismantle',
  'destroyItem',
  'DestroyItem',
  'deleteItem(',
  'DeleteItem',
];

const List<String> kApplyPathRelativeFiles = <String>[
  'lib/src/equip/apply_to_character.dart',
  '../bungie/lib/src/write/equip_orchestrator.dart',
  '../bungie/lib/src/write/write_client.dart',
];

void main() {
  test('apply path sources never reference dismantle/delete/destroy', () {
    final appRoot = _findAppPackageRoot();
    final violations = <String>[];
    for (final rel in kApplyPathRelativeFiles) {
      final file = File('${appRoot.path}/$rel');
      expect(file.existsSync(), isTrue, reason: 'missing ${file.path}');
      final text = file.readAsStringSync();
      for (final pattern in kBannedApplyPatterns) {
        if (text.contains(pattern)) {
          violations.add('${file.path}: contains "$pattern"');
        }
      }
    }
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
