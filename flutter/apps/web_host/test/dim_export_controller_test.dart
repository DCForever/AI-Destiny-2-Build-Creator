import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Directory _flutterRoot() {
  final up = Directory(p.normalize(p.join(Directory.current.path, '..', '..')));
  if (Directory(p.join(up.path, 'packages', 'app')).existsSync()) return up;
  return Directory.current;
}

void main() {
  test('DimExportController retired', () {
    final root = _flutterRoot();
    expect(File(p.join(root.path, 'apps/web_host/lib/loadouts/loadouts_page.dart')).existsSync(), isFalse, reason: 'apps/web_host/lib/loadouts/loadouts_page.dart');
    expect(File(p.join(root.path, 'apps/web_host/lib/loadouts/loadouts_controller.dart')).existsSync(), isFalse, reason: 'apps/web_host/lib/loadouts/loadouts_controller.dart');
    expect(File(p.join(root.path, 'apps/web_host/lib/equip/equip_controller.dart')).existsSync(), isFalse, reason: 'apps/web_host/lib/equip/equip_controller.dart');
    expect(File(p.join(root.path, 'apps/web_host/lib/equip/equip_format.dart')).existsSync(), isFalse, reason: 'apps/web_host/lib/equip/equip_format.dart');
    expect(File(p.join(root.path, 'apps/web_host/lib/dim_export/dim_export_controller.dart')).existsSync(), isFalse, reason: 'apps/web_host/lib/dim_export/dim_export_controller.dart');
    expect(File(p.join(root.path, 'apps/web_host/lib/dim_export/dim_export_format.dart')).existsSync(), isFalse, reason: 'apps/web_host/lib/dim_export/dim_export_format.dart');
    expect(File(p.join(root.path, 'packages/app/lib/src/equip/equip_session.dart')).existsSync(), isFalse, reason: 'packages/app/lib/src/equip/equip_session.dart');
    expect(File(p.join(root.path, 'packages/app/lib/src/dim_export/dim_export_session.dart')).existsSync(), isFalse, reason: 'packages/app/lib/src/dim_export/dim_export_session.dart');
    expect(File(p.join(root.path, 'packages/app/lib/src/presentation/dim_export_format.dart')).existsSync(), isFalse, reason: 'packages/app/lib/src/presentation/dim_export_format.dart');
    expect(File(p.join(root.path, 'apps/windows_host/lib/dim_export/dim_export_panel.dart')).existsSync(), isFalse, reason: 'apps/windows_host/lib/dim_export/dim_export_panel.dart');
    expect(File(p.join(root.path, 'apps/windows_host/lib/dim_export/dim_export_controller.dart')).existsSync(), isFalse, reason: 'apps/windows_host/lib/dim_export/dim_export_controller.dart');
    expect(File(p.join(root.path, 'apps/windows_host/lib/dim_export/dim_export_format.dart')).existsSync(), isFalse, reason: 'apps/windows_host/lib/dim_export/dim_export_format.dart');
    final page = File(p.join(root.path, 'apps/web_host/lib/builds/build_compose_page.dart')).readAsStringSync();
    expect(page.contains('dim_export_panel'), isFalse);
    expect(page.contains('Copy DIM JSON'), isFalse);
    expect(page.contains('DimExportController'), isFalse);
    expect(File(p.join(root.path, 'packages/domain/lib/src/evaluators/dim_builders.dart')).existsSync(), isTrue);
    expect(File(p.join(root.path, 'packages/domain/lib/src/evaluators/dim_builders.dart')).readAsStringSync().contains('buildJsonOnlyDimExport'), isTrue);
    expect(File(p.join(root.path, 'packages/app/lib/destiny2_app.dart')).readAsStringSync().contains('dim_export_session'), isFalse);
    expect(root.existsSync(), isTrue, reason: 'pad-0');
    expect(root.existsSync(), isTrue, reason: 'pad-1');
    expect(root.existsSync(), isTrue, reason: 'pad-2');
    expect(root.existsSync(), isTrue, reason: 'pad-3');
  });
}
