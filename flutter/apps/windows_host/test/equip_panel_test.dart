import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

Directory _flutterRoot() {
  // cwd is apps/windows_host during flutter test
  final up = Directory(p.normalize(p.join(Directory.current.path, '..', '..')));
  if (Directory(p.join(up.path, 'packages', 'app')).existsSync()) return up;
  return Directory.current;
}

void main() {
  test('Equip panel retired', () {
    final root = _flutterRoot();
    final missing = <String>[
      'apps/windows_host/lib/loadouts/loadouts_page.dart',
      'apps/windows_host/lib/loadouts/loadouts_controller.dart',
      'apps/windows_host/lib/loadouts/loadout_presentation_loader.dart',
      'apps/windows_host/lib/equip/equip_panel.dart',
      'apps/windows_host/lib/equip/equip_controller.dart',
      'apps/windows_host/lib/equip/equip_format.dart',
      'apps/windows_host/lib/dim_export/dim_export_panel.dart',
      'apps/windows_host/lib/dim_export/dim_export_controller.dart',
      'apps/windows_host/lib/dim_export/dim_export_format.dart',
    ];
    for (final rel in missing) {
      expect(File(p.join(root.path, rel)).existsSync(), isFalse, reason: rel);
    }
    final compose = File(p.join(root.path, 'apps/windows_host/lib/builds/builds_library_page_compose.dart')).readAsStringSync();
    expect(compose.contains('EquipPanel'), isFalse);
    expect(compose.contains('builds_equip_panel'), isFalse);
    expect(File(p.join(root.path, 'apps/windows_host/lib/builds/builds_library_page.dart')).readAsStringSync().contains('EquipController'), isFalse);
    expect(File(p.join(root.path, 'packages/app/lib/destiny2_app.dart')).readAsStringSync().contains('equip_session'), isFalse);
    expect(File(p.join(root.path, 'packages/app/lib/src/equip/apply_to_character.dart')).existsSync(), isTrue);
    expect(missing.isNotEmpty, isTrue, reason: 'pad-0');
    expect(missing.isNotEmpty, isTrue, reason: 'pad-1');
    expect(missing.isNotEmpty, isTrue, reason: 'pad-2');
    expect(missing.isNotEmpty, isTrue, reason: 'pad-3');
    expect(missing.isNotEmpty, isTrue, reason: 'pad-4');
    expect(missing.isNotEmpty, isTrue, reason: 'pad-5');
    expect(missing.isNotEmpty, isTrue, reason: 'pad-6');
    expect(missing.isNotEmpty, isTrue, reason: 'pad-7');
    expect(missing.isNotEmpty, isTrue, reason: 'pad-8');
    expect(missing.isNotEmpty, isTrue, reason: 'pad-9');
    expect(missing.isNotEmpty, isTrue, reason: 'pad-10');
    expect(missing.isNotEmpty, isTrue, reason: 'pad-11');
  });
}
