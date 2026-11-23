import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Directory _flutterRoot() {
  final up = Directory(p.normalize(p.join(Directory.current.path, '..', '..')));
  if (Directory(p.join(up.path, 'packages', 'app')).existsSync()) return up;
  return Directory.current;
}

void main() {
  test('Loadouts page retired', () {
    final root = _flutterRoot();
    expect(File(p.join(root.path, 'apps/windows_host/lib/loadouts/loadouts_page.dart')).existsSync(), isFalse, reason: 'apps/windows_host/lib/loadouts/loadouts_page.dart');
    expect(File(p.join(root.path, 'apps/windows_host/lib/loadouts/loadouts_controller.dart')).existsSync(), isFalse, reason: 'apps/windows_host/lib/loadouts/loadouts_controller.dart');
    expect(File(p.join(root.path, 'apps/windows_host/lib/loadouts/loadout_presentation_loader.dart')).existsSync(), isFalse, reason: 'apps/windows_host/lib/loadouts/loadout_presentation_loader.dart');
    expect(File(p.join(root.path, 'apps/windows_host/lib/equip/equip_panel.dart')).existsSync(), isFalse, reason: 'apps/windows_host/lib/equip/equip_panel.dart');
    expect(File(p.join(root.path, 'apps/windows_host/lib/equip/equip_controller.dart')).existsSync(), isFalse, reason: 'apps/windows_host/lib/equip/equip_controller.dart');
    expect(File(p.join(root.path, 'apps/windows_host/lib/equip/equip_format.dart')).existsSync(), isFalse, reason: 'apps/windows_host/lib/equip/equip_format.dart');
    expect(File(p.join(root.path, 'apps/windows_host/lib/dim_export/dim_export_panel.dart')).existsSync(), isFalse, reason: 'apps/windows_host/lib/dim_export/dim_export_panel.dart');
    expect(File(p.join(root.path, 'apps/windows_host/lib/dim_export/dim_export_controller.dart')).existsSync(), isFalse, reason: 'apps/windows_host/lib/dim_export/dim_export_controller.dart');
    expect(File(p.join(root.path, 'apps/windows_host/lib/dim_export/dim_export_format.dart')).existsSync(), isFalse, reason: 'apps/windows_host/lib/dim_export/dim_export_format.dart');
    expect(File(p.join(root.path, 'apps/windows_host/lib/app.dart')).readAsStringSync().contains('LoadoutsPage'), isFalse);
  });
}
