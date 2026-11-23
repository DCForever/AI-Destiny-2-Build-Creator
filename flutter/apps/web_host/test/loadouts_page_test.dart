import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Directory _flutterRoot() {
  final up = Directory(p.normalize(p.join(Directory.current.path, '..', '..')));
  if (Directory(p.join(up.path, 'packages', 'app')).existsSync()) return up;
  return Directory.current;
}

void main() {
  test('Loadouts page retired', () {
    final root = _flutterRoot();
    final missing = <String>[
      'apps/web_host/lib/loadouts/loadouts_page.dart',
      'apps/web_host/lib/loadouts/loadouts_controller.dart',
      'apps/web_host/lib/equip/equip_controller.dart',
      'apps/web_host/lib/equip/equip_format.dart',
      'apps/web_host/lib/dim_export/dim_export_controller.dart',
      'apps/web_host/lib/dim_export/dim_export_format.dart',
      'apps/windows_host/lib/loadouts/loadouts_page.dart',
      'apps/windows_host/lib/loadouts/loadouts_controller.dart',
      'apps/windows_host/lib/loadouts/loadout_presentation_loader.dart',
    ];
    for (final rel in missing) {
      expect(File(p.join(root.path, rel)).existsSync(), isFalse, reason: rel);
    }
    final header = File(p.join(root.path, 'apps/web_host/lib/components/shell_header.dart')).readAsStringSync();
    expect(header.contains("/loadouts"), isFalse);
    expect(header.contains('Loadouts'), isFalse);
    final app = File(p.join(root.path, 'apps/web_host/lib/app.dart')).readAsStringSync();
    expect(app.contains('LoadoutsPage'), isFalse);
    expect(app.contains("path: '/loadouts'"), isFalse);
  });
}
