import 'dart:io';

import 'package:destiny2_web_host/pages/settings_page.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('SettingsPage', () {
    testComponents('renders Hello Settings copy', (tester) async {
      tester.pumpComponent(const SettingsPage());

      expect(find.text(SettingsPage.titleText), findsOneComponent);
      expect(find.text(SettingsPage.helloText), findsOneComponent);
      expect(find.textContaining('No Next.js'), findsOneComponent);
      expect(find.textContaining('Jaspr'), findsComponents);
      expect(find.textContaining('Public+PKCE'), findsComponents);
    });

    testComponents('does not expose confidential secret identifiers as config',
        (tester) async {
      tester.pumpComponent(const SettingsPage());

      // Subtitle mentions that there is no confidential secret — OK.
      // Must not show a value assignment path for secrets.
      expect(find.textContaining('BUNGIE_CLIENT_SECRET='), findsNothing);
      expect(find.textContaining('SESSION_SECRET='), findsNothing);
    });
  });

  group('pubspec no Next dependency', () {
    test('web_host pubspec has jaspr + bungie + tokens; no next package dep', () {
      final pubspecFile = File(
        p.join(Directory.current.path, 'pubspec.yaml'),
      );
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
      expect(lower, contains('destiny2_bungie:'));
      expect(lower, contains('mode: client'));
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
