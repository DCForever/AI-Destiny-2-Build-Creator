import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

void main() {
  group('ProdPublicOAuthMatrix (DART-058 / US1)', () {
    test('covers windows, web, android, ios with non-empty redirects', () {
      const origin = 'https://app.example';
      for (final platform in ProdPublicOAuthMatrix.platforms) {
        final uri = ProdPublicOAuthMatrix.redirectUri(
          platform,
          webOrigin: origin,
        );
        expect(uri, isNotEmpty, reason: platform.name);
        expect(uri.trim(), uri);
      }
    });

    test('Windows prod redirect is exact HTTPS loopback', () {
      expect(
        ProdPublicOAuthMatrix.redirectUri(OAuthRedirectPlatform.windows),
        'https://127.0.0.1:8765/callback',
      );
      expect(kProdWindowsRedirectUri, startsWith('https://'));
      expect(kProdWindowsRedirectUri, isNot(contains('http://127.0.0.1:3000')));
      expect(kProdWindowsRedirectUri, isNot(contains('/api/auth/callback')));
    });

    test('web redirect is origin + /auth/callback', () {
      expect(
        ProdPublicOAuthMatrix.redirectUri(
          OAuthRedirectPlatform.web,
          webOrigin: 'https://app.example',
        ),
        'https://app.example/auth/callback',
      );
      expect(
        prodWebRedirectUri('https://app.example/'),
        'https://app.example/auth/callback',
      );
      expect(kProdWebOAuthCallbackPath, '/auth/callback');
    });

    test('mobile schemes are custom scheme OAuth callbacks', () {
      expect(
        ProdPublicOAuthMatrix.redirectUri(OAuthRedirectPlatform.android),
        'd2buildcreator://oauth/callback',
      );
      expect(
        ProdPublicOAuthMatrix.redirectUri(OAuthRedirectPlatform.ios),
        'd2buildcreator://oauth/callback',
      );
      expect(kProdMobileRedirectUri, kProdAndroidRedirectUri);
    });

    test('web without origin throws', () {
      expect(
        () => ProdPublicOAuthMatrix.redirectUri(OAuthRedirectPlatform.web),
        throwsA(isA<BungieConfigException>()),
      );
      expect(
        () => prodWebRedirectUri('  '),
        throwsA(isA<BungieConfigException>()),
      );
    });

    test('asPlatformConfig resolves all platforms', () {
      final config = ProdPublicOAuthMatrix.asPlatformConfig(
        webOrigin: 'https://prod.example',
      );
      expect(
        config.resolve(OAuthRedirectPlatform.windows),
        kProdWindowsRedirectUri,
      );
      expect(
        config.resolve(OAuthRedirectPlatform.web),
        'https://prod.example/auth/callback',
      );
      expect(
        config.resolve(OAuthRedirectPlatform.android),
        kProdAndroidRedirectUri,
      );
      expect(config.resolve(OAuthRedirectPlatform.ios), kProdIosRedirectUri);
    });

    test('cutover-required platforms are windows + web only', () {
      expect(
        isCutoverRequiredOAuthPlatform(OAuthRedirectPlatform.windows),
        isTrue,
      );
      expect(isCutoverRequiredOAuthPlatform(OAuthRedirectPlatform.web), isTrue);
      expect(
        isCutoverRequiredOAuthPlatform(OAuthRedirectPlatform.android),
        isFalse,
      );
      expect(
        isCutoverRequiredOAuthPlatform(OAuthRedirectPlatform.ios),
        isFalse,
      );
    });

    test('rows expose four platforms and never mention secrets', () {
      final rows = ProdPublicOAuthMatrix.rows();
      expect(rows, hasLength(4));
      for (final row in rows) {
        expect(row.redirectUri, isNotEmpty);
        expect(row.redirectUri.toLowerCase(), isNot(contains('client_secret')));
        expect(row.notes.toLowerCase(), isNot(contains('session_secret')));
      }
      expect(kProdPublicBungieAppName, isNotEmpty);
    });

    test('authorize URL with matrix redirect omits client_secret', () {
      final client = BungieOAuthClient(
        clientId: 'public-client-id',
        redirectUri: kProdWindowsRedirectUri,
      );
      final pair = generatePkcePair();
      final state = generateOAuthState();
      final url = client.buildAuthorizeUrl(
        state: state,
        codeChallenge: pair.codeChallenge,
      );
      final uri = Uri.parse(url);
      expect(uri.queryParameters['redirect_uri'], kProdWindowsRedirectUri);
      expect(uri.queryParameters.containsKey('client_secret'), isFalse);
      expect(url.toLowerCase(), isNot(contains('client_secret')));
    });
  });
}
