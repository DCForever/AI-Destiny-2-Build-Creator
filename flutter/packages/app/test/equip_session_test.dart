import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Directory _flutterRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = Directory(p.join(dir.path, 'packages', 'app'));
    if (candidate.existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  // When cwd is packages/app, parent is flutter/
  final up = Directory(p.normalize(p.join(Directory.current.path, '..', '..')));
  if (Directory(p.join(up.path, 'packages', 'app')).existsSync()) return up;
  return Directory.current;
}

void main() {
  test('EquipSession retired; Apply path kept', () {
    final root = _flutterRoot();
    final missing = <String>[
      'packages/app/lib/src/equip/equip_session.dart',
      'packages/app/lib/src/dim_export/dim_export_session.dart',
      'packages/app/lib/src/presentation/dim_export_format.dart',
      'apps/web_host/lib/equip/equip_controller.dart',
      'apps/web_host/lib/equip/equip_format.dart',
      'apps/windows_host/lib/equip/equip_panel.dart',
      'apps/windows_host/lib/equip/equip_controller.dart',
      'apps/windows_host/lib/equip/equip_format.dart',
    ];
    for (final rel in missing) {
      final f = File(p.join(root.path, rel));
      expect(f.existsSync(), isFalse, reason: rel);
    }
    final barrel = File(p.join(root.path, 'packages/app/lib/destiny2_app.dart')).readAsStringSync();
    expect(barrel.contains('equip_session'), isFalse);
    expect(barrel.contains('apply_to_character'), isTrue);
    expect(File(p.join(root.path, 'packages/app/lib/src/equip/apply_to_character.dart')).existsSync(), isTrue);
    expect(File(p.join(root.path, 'packages/app/lib/src/equip/apply_sockets.dart')).existsSync(), isTrue);
  });
}
