import 'dart:io';

import 'package:test/test.dart';

import '../client_secret_scan.dart';

void main() {
  group('scanClientSecretText', () {
    test('flags secret assignment and fromEnvironment', () {
      final hits = scanClientSecretText(
        'evil.dart',
        '''
const x = String.fromEnvironment('BUNGIE_CLIENT_SECRET');
final session = SESSION_SECRET = 'abc';
final body = {'client_secret': secret};
''',
      );
      expect(hits, isNotEmpty);
      expect(
        hits.map((h) => h.pattern),
        containsAll(['fromEnvironment-secret', 'secret-assign']),
      );
    });

    test('allows documentation never-pass phrases', () {
      final hits = scanClientSecretText(
        'ok.dart',
        '''
/// Never pass CLIENT_SECRET.
// No CLIENT_SECRET in this client.
const msg = 'Never pass CLIENT_SECRET.';
const msg2 = 'No CLIENT_SECRET in this client.';
final public = String.fromEnvironment('BUNGIE_CLIENT_ID');
''',
      );
      expect(hits, isEmpty);
    });

    test('allows oauth code that mentions client_secret only as absence check', () {
      // Request builders that assert body does not contain client_secret are
      // test-side; production lib should not assign it. A comment-only line:
      final hits = scanClientSecretText(
        'oauth.dart',
        '''
// Public clients: form body only — never client_secret, never Basic secret.
final body = <String, String>{
  'grant_type': 'authorization_code',
  'client_id': clientId,
};
''',
      );
      expect(hits, isEmpty);
    });
  });

  group('scanClientSecrets (repo)', () {
    test('client package and host lib trees are clean', () {
      final findings = scanClientSecrets();
      expect(
        findings,
        isEmpty,
        reason: findings.map((f) => f.toString()).join('\n'),
      );
    });

    test('runClientSecretScan returns 0', () {
      expect(runClientSecretScan(), 0);
    });

    test('negative: planted FAKE secret assignment fails the scan', () {
      // Built at runtime from split parts — committed source must not contain
      // a live-looking BUNGIE_CLIENT_SECRET=… / 'client_secret': … assignment
      // (would trip gitleaks on the repo itself).
      final dir = Directory.systemTemp.createTempSync('client-secret-neg-');
      addTearDown(() {
        try {
          dir.deleteSync(recursive: true);
        } catch (_) {}
      });
      final envKey = ['BUNGIE', 'CLIENT', 'SECRET'].join('_');
      final formKey = ['client', 'secret'].join('_');
      final planted = File('${dir.path}/planted_fake.dart');
      planted.writeAsStringSync(
        "const planted = '$envKey=fake_scan_only_not_a_real_secret';\n"
        "final body = {'$formKey': 'fake_scan_only_value'};\n",
      );
      final findings = scanClientSecretText(
        'planted_fake.dart',
        planted.readAsStringSync(),
      );
      expect(findings, isNotEmpty);
      expect(
        findings.map((f) => f.pattern),
        contains('secret-assign'),
      );
    });
  });

  group('findWorkspaceRoot', () {
    test('finds packages/bungie from tool cwd', () {
      final root = findWorkspaceRoot();
      expect(
        Directory('${root.path}/packages/bungie').existsSync(),
        isTrue,
      );
    });
  });
}
