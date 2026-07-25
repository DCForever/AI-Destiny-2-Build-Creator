import 'dart:io';

import 'package:destiny2_web_host/pages/settings_page.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('SettingsPage', () {
    testComponents('renders Hello Settings copy', (tester) async {
      tester.pumpComponent(const SettingsPage());

      expect(find.text(SettingsPage.titleText), findsOneComponent);
      expect(find.text(SettingsPage.helloText), findsOneComponent);
      expect(find.textContaining('No Next.js'), findsOneComponent);
      expect(find.textContaining('Jaspr'), findsComponents);
    });

    testComponents('does not expose sign-in CTA or secret copy', (tester) async {
      tester.pumpComponent(const SettingsPage());

      expect(find.textContaining('CLIENT_SECRET'), findsNothing);
      expect(find.textContaining('Sign in'), findsNothing);
      expect(find.textContaining('BUNGIE_CLIENT_SECRET'), findsNothing);
    });
  });

  group('pubspec no Next dependency', () {
    test('web_host pubspec has jaspr + tokens; no next package dep', () {
      final pubspecFile = File(
        p.join(Directory.current.path, 'pubspec.yaml'),
      );
      // When run from workspace root, resolve package path.
      final file = pubspecFile.existsSync()
          ? pubspecFile
          : File(
              p.join(
                Directory.current.path,
                'apps',
                'web_host',
                'pubspec.yaml',
              ),
            );
      final text = file.readAsStringSync();
      final lower = text.toLowerCase();
      expect(lower, contains('jaspr:'));
      expect(lower, contains('destiny2_ui_tokens:'));
      expect(lower, contains('mode: client'));
      // Dependency keys only (description may mention Next.js as a non-goal).
      expect(
        RegExp(r'^\s+next\s*:', multiLine: true, caseSensitive: false)
            .hasMatch(text),
        isFalse,
      );
      expect(
        RegExp(r'^\s+react\s*:', multiLine: true, caseSensitive: false)
            .hasMatch(text),
        isFalse,
      );
    });
  });
}
