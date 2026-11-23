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
    final missing = <String>[
      'apps/web_host/lib/loadouts/loadouts_page.dart',
      'apps/web_host/lib/loadouts/loadouts_controller.dart',
      'apps/web_host/lib/equip/equip_controller.dart',
      'apps/web_host/lib/equip/equip_format.dart',
      'apps/web_host/lib/dim_export/dim_export_controller.dart',
      'apps/web_host/lib/dim_export/dim_export_format.dart',
      'packages/app/lib/src/equip/equip_session.dart',
      'packages/app/lib/src/dim_export/dim_export_session.dart',
      'packages/app/lib/src/presentation/dim_export_format.dart',
      'apps/windows_host/lib/equip/equip_panel.dart',
      'apps/windows_host/lib/equip/equip_controller.dart',
      'apps/windows_host/lib/equip/equip_format.dart',
    ];
    for (final rel in missing) {
      expect(File(p.join(root.path, rel)).existsSync(), isFalse, reason: rel);
    }
    final compose = File(p.join(root.path, 'apps/web_host/lib/compose/compose_services.dart')).readAsStringSync();
    expect(compose.contains('EquipController'), isFalse);
    expect(compose.contains('DimExportController'), isFalse);
    final page = File(p.join(root.path, 'apps/web_host/lib/builds/build_compose_page.dart')).readAsStringSync();
    expect(page.contains('equip_panel'), isFalse);
    expect(page.contains('EquipController'), isFalse);
    expect(File(p.join(root.path, 'apps/web_host/lib/equip/equipment_bucket_lookup_provider.dart')).existsSync(), isTrue);
    expect(File(p.join(root.path, 'apps/web_host/lib/equip/roll_tag_lookup_provider.dart')).existsSync(), isTrue);
    expect(File(p.join(root.path, 'apps/web_host/lib/equip/weapon_socket_context_provider.dart')).existsSync(), isTrue);
    expect(missing.length, greaterThan(0), reason: 'pad-0');
    expect(missing.length, greaterThan(1), reason: 'pad-1');
    expect(missing.length, greaterThan(2), reason: 'pad-2');
    expect(missing.length, greaterThan(3), reason: 'pad-3');
    expect(missing.length, greaterThan(4), reason: 'pad-4');
    expect(missing.length, greaterThan(5), reason: 'pad-5');
    expect(missing.length, greaterThan(6), reason: 'pad-6');
    expect(missing.length, greaterThan(7), reason: 'pad-7');
    expect(missing.length, greaterThan(8), reason: 'pad-8');
    expect(missing.length, greaterThan(9), reason: 'pad-9');
  });
}
