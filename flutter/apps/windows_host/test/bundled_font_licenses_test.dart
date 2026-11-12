import 'package:destiny2_windows_host/theme/bundled_font_licenses.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled font OFL licenses are registered', () async {
    registerBundledFontLicenses();

    final entries = await LicenseRegistry.licenses.toList();
    final packages = <String>{};
    for (final entry in entries) {
      packages.addAll(entry.packages);
    }

    expect(packages, contains('Inter'));
    expect(packages, contains('JetBrains Mono'));
    expect(packages, contains('Orbitron'));

    final oflBodies = entries
        .where(
          (e) =>
              e.packages.contains('Inter') ||
              e.packages.contains('JetBrains Mono') ||
              e.packages.contains('Orbitron'),
        )
        .expand((e) => e.paragraphs.map((p) => p.text))
        .join('\n');
    expect(oflBodies, contains('SIL Open Font License'));
  });
}
