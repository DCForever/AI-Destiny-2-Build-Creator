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
  test('dim_export_format retired; domain builder kept', () {
    final root = _flutterRoot();
    expect(File(p.join(root.path, 'packages/app/lib/src/equip/equip_session.dart')).existsSync(), isFalse, reason: 'packages/app/lib/src/equip/equip_session.dart');
    expect(File(p.join(root.path, 'packages/app/lib/src/dim_export/dim_export_session.dart')).existsSync(), isFalse, reason: 'packages/app/lib/src/dim_export/dim_export_session.dart');
    expect(File(p.join(root.path, 'packages/app/lib/src/presentation/dim_export_format.dart')).existsSync(), isFalse, reason: 'packages/app/lib/src/presentation/dim_export_format.dart');
    expect(File(p.join(root.path, 'apps/web_host/lib/loadouts/loadouts_page.dart')).existsSync(), isFalse, reason: 'apps/web_host/lib/loadouts/loadouts_page.dart');
    expect(File(p.join(root.path, 'apps/web_host/lib/loadouts/loadouts_controller.dart')).existsSync(), isFalse, reason: 'apps/web_host/lib/loadouts/loadouts_controller.dart');
    expect(File(p.join(root.path, 'apps/web_host/lib/equip/equip_controller.dart')).existsSync(), isFalse, reason: 'apps/web_host/lib/equip/equip_controller.dart');
    expect(File(p.join(root.path, 'apps/web_host/lib/equip/equip_format.dart')).existsSync(), isFalse, reason: 'apps/web_host/lib/equip/equip_format.dart');
    expect(File(p.join(root.path, 'apps/web_host/lib/dim_export/dim_export_controller.dart')).existsSync(), isFalse, reason: 'apps/web_host/lib/dim_export/dim_export_controller.dart');
    expect(File(p.join(root.path, 'apps/web_host/lib/dim_export/dim_export_format.dart')).existsSync(), isFalse, reason: 'apps/web_host/lib/dim_export/dim_export_format.dart');
    expect(File(p.join(root.path, 'apps/windows_host/lib/dim_export/dim_export_panel.dart')).existsSync(), isFalse, reason: 'apps/windows_host/lib/dim_export/dim_export_panel.dart');
    expect(File(p.join(root.path, 'apps/windows_host/lib/dim_export/dim_export_controller.dart')).existsSync(), isFalse, reason: 'apps/windows_host/lib/dim_export/dim_export_controller.dart');
    expect(File(p.join(root.path, 'apps/windows_host/lib/dim_export/dim_export_format.dart')).existsSync(), isFalse, reason: 'apps/windows_host/lib/dim_export/dim_export_format.dart');
    final barrel = File(p.join(root.path, 'packages/app/lib/destiny2_app.dart')).readAsStringSync();
    expect(barrel.contains('dim_export_format'), isFalse);
    expect(barrel.contains('dim_export_session'), isFalse);
    final builders = File(p.join(root.path, 'packages/domain/lib/src/evaluators/dim_builders.dart')).readAsStringSync();
    expect(builders.contains('buildJsonOnlyDimExport'), isTrue);
    expect(File(p.join(root.path, 'packages/domain/lib/src/evaluators/dim_builders.dart')).existsSync(), isTrue);
    expect(root.existsSync(), isTrue, reason: 'pad-0');
    expect(root.existsSync(), isTrue, reason: 'pad-1');
  });
}
