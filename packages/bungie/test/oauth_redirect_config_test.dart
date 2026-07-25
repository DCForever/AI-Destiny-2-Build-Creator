import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

void main() {
  group('US3 PlatformRedirectUriConfig', () {
    test('resolves Windows and web URIs', () {
      final config = PlatformRedirectUriConfig({
        OAuthRedirectPlatform.windows: 'http://127.0.0.1:8765/callback',
        OAuthRedirectPlatform.web: 'https://app.example/auth/callback',
      });

      expect(
        config.resolve(OAuthRedirectPlatform.windows),
        'http://127.0.0.1:8765/callback',
      );
      expect(
        config.resolve(OAuthRedirectPlatform.web),
        'https://app.example/auth/callback',
      );
      expect(config.has(OAuthRedirectPlatform.android), isFalse);
    });

    test('missing platform throws BungieConfigException', () {
      final config = PlatformRedirectUriConfig({
        OAuthRedirectPlatform.windows: 'http://127.0.0.1:8765/callback',
      });

      expect(
        () => config.resolve(OAuthRedirectPlatform.android),
        throwsA(
          isA<BungieConfigException>().having(
            (e) => e.message,
            'message',
            contains('android'),
          ),
        ),
      );
    });

    test('blank or empty map rejected', () {
      expect(
        () => PlatformRedirectUriConfig({}),
        throwsA(isA<BungieConfigException>()),
      );
      expect(
        () => PlatformRedirectUriConfig({
          OAuthRedirectPlatform.ios: '   ',
        }),
        throwsA(isA<BungieConfigException>()),
      );
    });

    test('OAuthPendingAuth holds state verifier redirect for host handoff', () {
      final pending = OAuthPendingAuth(
        state: 's',
        codeVerifier: 'v',
        redirectUri: 'http://127.0.0.1/cb',
        createdAt: DateTime.utc(2026, 7, 24),
      );
      expect(pending.state, 's');
      expect(pending.codeVerifier, 'v');
      expect(pending.redirectUri, 'http://127.0.0.1/cb');
    });
  });
}
