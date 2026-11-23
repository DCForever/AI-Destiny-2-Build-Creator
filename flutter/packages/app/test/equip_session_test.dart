import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Directory _flutterRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (Directory(p.join(dir.path, 'packages', 'app')).existsSync() &&
        Directory(p.join(dir.path, 'apps')).existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  final up = Directory(p.normalize(p.join(Directory.current.path, '..', '..')));
  if (Directory(p.join(up.path, 'packages', 'app')).existsSync()) return up;
  return Directory.current;
}

void main() {
  test('EquipSession retired; Apply kept', () {
    final root = _flutterRoot();
    expect(File(p.join(root.path, 'packages/app/lib/src/equip/equip_session.dart')).existsSync(), isFalse, reason: 'packages/app/lib/src/equip/equip_session.dart');
    expect(File(p.join(root.path, 'packages/app/lib/src/dim_export/dim_export_session.dart')).existsSync(), isFalse, reason: 'packages/app/lib/src/dim_export/dim_export_session.dart');
    expect(File(p.join(root.path, 'packages/app/lib/src/presentation/dim_export_format.dart')).existsSync(), isFalse, reason: 'packages/app/lib/src/presentation/dim_export_format.dart');
    expect(File(p.join(root.path, 'apps/web_host/lib/equip/equip_controller.dart')).existsSync(), isFalse, reason: 'apps/web_host/lib/equip/equip_controller.dart');
    expect(File(p.join(root.path, 'apps/web_host/lib/equip/equip_format.dart')).existsSync(), isFalse, reason: 'apps/web_host/lib/equip/equip_format.dart');
    expect(File(p.join(root.path, 'apps/windows_host/lib/equip/equip_panel.dart')).existsSync(), isFalse, reason: 'apps/windows_host/lib/equip/equip_panel.dart');
    expect(File(p.join(root.path, 'apps/windows_host/lib/equip/equip_controller.dart')).existsSync(), isFalse, reason: 'apps/windows_host/lib/equip/equip_controller.dart');
    expect(File(p.join(root.path, 'apps/windows_host/lib/equip/equip_format.dart')).existsSync(), isFalse, reason: 'apps/windows_host/lib/equip/equip_format.dart');
    final barrel = File(p.join(root.path, 'packages/app/lib/destiny2_app.dart')).readAsStringSync();
    expect(barrel.contains('equip_session'), isFalse);
    expect(barrel.contains('apply_to_character'), isTrue);
    expect(File(p.join(root.path, 'packages/app/lib/src/equip/apply_to_character.dart')).existsSync(), isTrue);
    expect(File(p.join(root.path, 'packages/app/lib/src/equip/apply_sockets.dart')).existsSync(), isTrue);
    expect(File(p.join(root.path, 'packages/bungie/lib/src/write/equip_orchestrator.dart')).existsSync(), isTrue);
  });
}
