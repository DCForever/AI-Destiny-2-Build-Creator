import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Scans web_host OAuth sources for confidential secret identifiers (SC-005).
void main() {
  group('no confidential secret in web_host OAuth (US1)', () {
    test('auth lib and main omit client_secret / CLIENT_SECRET / SESSION_SECRET fields',
        () {
      final root = _webHostRoot();
      final files = <File>[
        ..._dartFiles(Directory(p.join(root, 'lib', 'auth'))),
        File(p.join(root, 'lib', 'main.client.dart')),
        File(p.join(root, 'lib', 'components', 'oauth_account_card.dart')),
        File(p.join(root, 'lib', 'pages', 'auth_callback_page.dart')),
        File(p.join(root, 'pubspec.yaml')),
      ];

      // Allowed: documentation that says "Never pass CLIENT_SECRET" or similar.
      final forbiddenAssign = RegExp(
        r'''(?:clientSecret|client_secret|CLIENT_SECRET|SESSION_SECRET)\s*[:=]''',
      );
      final forbiddenEnv = RegExp(
        r'''fromEnvironment\(\s*['"](?:BUNGIE_CLIENT_SECRET|CLIENT_SECRET|SESSION_SECRET)['"]''',
      );

      for (final file in files) {
        if (!file.existsSync()) continue;
        final text = file.readAsStringSync();
        expect(
          forbiddenAssign.hasMatch(text),
          isFalse,
          reason: 'secret field assign in ${file.path}',
        );
        expect(
          forbiddenEnv.hasMatch(text),
          isFalse,
          reason: 'secret dart-define in ${file.path}',
        );
      }
    });

    test('token store does not import destiny2_db / drift', () {
      final root = _webHostRoot();
      final authDir = Directory(p.join(root, 'lib', 'auth'));
      for (final file in _dartFiles(authDir)) {
        final text = file.readAsStringSync();
        expect(
          text.contains('package:destiny2_db/'),
          isFalse,
          reason: 'auth must not use Drift for tokens: ${file.path}',
        );
        expect(
          text.contains('package:drift/'),
          isFalse,
          reason: 'auth must not use Drift for tokens: ${file.path}',
        );
      }
    });
  });
}

String _webHostRoot() {
  final cwd = Directory.current.path;
  final direct = Directory(cwd);
  if (File(p.join(cwd, 'pubspec.yaml')).existsSync() &&
      File(p.join(cwd, 'pubspec.yaml')).readAsStringSync().contains('destiny2_web_host')) {
    return cwd;
  }
  final nested = p.join(cwd, 'apps', 'web_host');
  if (Directory(nested).existsSync()) return nested;
  return direct.path;
}

List<File> _dartFiles(Directory dir) {
  if (!dir.existsSync()) return const [];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();
}
