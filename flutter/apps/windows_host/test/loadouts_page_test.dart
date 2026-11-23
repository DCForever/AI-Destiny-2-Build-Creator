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
  test('Loadouts page retired', () {
    final root = _flutterRoot();
    final missing = <String>[
      'apps/windows_host/lib/loadouts/loadouts_page.dart',
      'apps/windows_host/lib/loadouts/loadouts_controller.dart',
      'apps/windows_host/lib/loadouts/loadout_presentation_loader.dart',
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
    expect(File(p.join(root.path, 'apps/windows_host/lib/app.dart')).readAsStringSync().contains('LoadoutsPage'), isFalse);
  });
}
