import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Settings open-file helper must stay open-only (never save dialogs).
void main() {
  test('open_file_path_picker.dart never references getSaveLocation', () {
    final file = _resolve(
      'apps/windows_host/lib/settings/open_file_path_picker.dart',
    );
    final text = file.readAsStringSync();
    expect(text.contains('getSaveLocation'), isFalse);
    expect(text.contains('openFile'), isTrue);
    expect(text.contains('getSavePath'), isFalse);
  });

  test('path_file_field.dart never references getSaveLocation', () {
    final file = _resolve('apps/windows_host/lib/settings/path_file_field.dart');
    final text = file.readAsStringSync();
    expect(text.contains('getSaveLocation'), isFalse);
    expect(text.contains('getSavePath'), isFalse);
  });
}

File _resolve(String relative) {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${dir.path}/$relative');
    if (candidate.existsSync()) return candidate;
    final nested = File('${dir.path}/flutter/$relative');
    if (nested.existsSync()) return nested;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError('missing $relative from ${Directory.current.path}');
}
