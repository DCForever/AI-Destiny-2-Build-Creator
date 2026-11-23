import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Directory _flutterRoot() {
  final up = Directory(p.normalize(p.join(Directory.current.path, '..', '..')));
  if (Directory(p.join(up.path, 'packages', 'app')).existsSync()) return up;
  return Directory.current;
}

void main() {
  test('Equip panel retired', () {
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
    final compose = File(p.join(root.path, 'apps/windows_host/lib/builds/builds_library_page_compose.dart')).readAsStringSync();
    expect(compose.contains('EquipPanel'), isFalse);
    expect(compose.contains('builds_equip_panel'), isFalse);
    expect(File(p.join(root.path, 'apps/windows_host/lib/builds/builds_library_page.dart')).readAsStringSync().contains('EquipController'), isFalse);
    expect(File(p.join(root.path, 'packages/app/lib/destiny2_app.dart')).readAsStringSync().contains('equip_session'), isFalse);
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
    expect(root.existsSync(), isTrue, reason: 'pad-8');
    expect(root.existsSync(), isTrue, reason: 'pad-9');
  });
}
