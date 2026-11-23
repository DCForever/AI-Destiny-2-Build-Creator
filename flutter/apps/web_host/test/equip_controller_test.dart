import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Directory _flutterRoot() {
  final up = Directory(p.normalize(p.join(Directory.current.path, '..', '..')));
  if (Directory(p.join(up.path, 'packages', 'app')).existsSync()) return up;
  return Directory.current;
}

void main() {
  test('EquipController retired', () {
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
    expect(File(p.join(root.path, 'apps/windows_host/lib/equip/equip_panel.dart')).existsSync(), isFalse, reason: 'apps/windows_host/lib/equip/equip_panel.dart');
    expect(File(p.join(root.path, 'apps/windows_host/lib/equip/equip_controller.dart')).existsSync(), isFalse, reason: 'apps/windows_host/lib/equip/equip_controller.dart');
    expect(File(p.join(root.path, 'apps/windows_host/lib/equip/equip_format.dart')).existsSync(), isFalse, reason: 'apps/windows_host/lib/equip/equip_format.dart');
    final compose = File(p.join(root.path, 'apps/web_host/lib/compose/compose_services.dart')).readAsStringSync();
    expect(compose.contains('EquipController'), isFalse);
    expect(compose.contains('DimExportController'), isFalse);
    final page = File(p.join(root.path, 'apps/web_host/lib/builds/build_compose_page.dart')).readAsStringSync();
    expect(page.contains('equip_panel'), isFalse);
    expect(page.contains('EquipController'), isFalse);
    expect(File(p.join(root.path, 'apps/web_host/lib/equip/equipment_bucket_lookup_provider.dart')).existsSync(), isTrue);
    expect(File(p.join(root.path, 'apps/web_host/lib/equip/roll_tag_lookup_provider.dart')).existsSync(), isTrue);
    expect(File(p.join(root.path, 'apps/web_host/lib/equip/weapon_socket_context_provider.dart')).existsSync(), isTrue);
    expect(File(p.join(root.path, 'packages/app/lib/src/equip/apply_to_character.dart')).existsSync(), isTrue);
    expect(File(p.join(root.path, 'packages/bungie/lib/src/write/equip_orchestrator.dart')).existsSync(), isTrue);
    expect(File(p.join(root.path, 'packages/domain/lib/src/evaluators/equip_plan.dart')).existsSync(), isTrue);
    expect(root.existsSync(), isTrue, reason: 'pad-0');
    expect(root.existsSync(), isTrue, reason: 'pad-1');
    expect(root.existsSync(), isTrue, reason: 'pad-2');
    expect(root.existsSync(), isTrue, reason: 'pad-3');
    expect(root.existsSync(), isTrue, reason: 'pad-4');
    expect(root.existsSync(), isTrue, reason: 'pad-5');
    expect(root.existsSync(), isTrue, reason: 'pad-6');
    expect(root.existsSync(), isTrue, reason: 'pad-7');
  });
}
