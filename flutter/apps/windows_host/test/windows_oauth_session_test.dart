import 'dart:convert';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/loopback_callback_server.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/auth/windows_oauth_session.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> rawTokenResponse({
  String access = 'acc-secret-111',
  String refresh = 'ref-secret-222',
  String membershipId = 'mem-e2e-42',
}) =>
    {
      'access_token': access,
      'token_type': 'Bearer',
      'expires_in': 3600,
      'refresh_token': refresh,
      'refresh_expires_in': 7776000,
      'membership_id': membershipId,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const clientId = 'public-client-id';
  const redirectUri = 'http://127.0.0.1:8765/callback';

  group('WindowsOAuthSession sign-in/out US2/US3', () {
    test('successful loopback sign-in stores tokens and signs in', () async {
      final store = MemoryTokenStore();
      final browser = FakeBrowserLauncher();
      String? capturedState;

      final oauth = BungieOAuthClient(
        clientId: clientId,
        redirectUri: redirectUri,
        transport: (request) async {
          expect(request.body!.toLowerCase(), isNot(contains('client_secret')));
          return BungieHttpResponse(
            statusCode: 200,
            body: jsonEncode(rawTokenResponse()),
          );
        },
      );

      final session = WindowsOAuthSession(
        clientId: clientId,
        redirectUri: redirectUri,
        tokenStore: store,
        oauthClient: oauth,
        browserLauncher: browser,
        waitForCallbackOverride: () async {
          // Extract state from authorize URL opened by session.
          expect(browser.opened, isNotEmpty);
          final uri = Uri.parse(browser.opened.single);
          capturedState = uri.queryParameters['state'];
          expect(uri.queryParameters['code_challenge_method'], 'S256');
          expect(uri.queryParameters['client_id'], clientId);
          expect(uri.queryParameters['redirect_uri'], redirectUri);
          return LoopbackCallbackResult(
            code: 'auth-code-xyz',
            state: capturedState,
          );
        },
      );

      await session.restore();
      expect(session.isSignedIn, isFalse);

      await session.signIn();

      expect(session.status, OAuthSessionStatus.signedIn);
      expect(session.isSignedIn, isTrue);
      expect(session.membershipId, 'mem-e2e-42');
      expect(await store.read(), isNotNull);
      expect((await store.read())!.accessToken, 'acc-secret-111');
      expect(browser.opened, hasLength(1));
    });

    test('state mismatch leaves signed-out and clears store', () async {
      final store = MemoryTokenStore();
      final browser = FakeBrowserLauncher();
      final oauth = BungieOAuthClient(
        clientId: clientId,
        redirectUri: redirectUri,
        transport: (_) async => BungieHttpResponse(
          statusCode: 200,
          body: jsonEncode(rawTokenResponse()),
        ),
      );

      final session = WindowsOAuthSession(
        clientId: clientId,
        redirectUri: redirectUri,
        tokenStore: store,
        oauthClient: oauth,
        browserLauncher: browser,
        waitForCallbackOverride: () async => const LoopbackCallbackResult(
          code: 'code',
          state: 'totally-wrong-state-value-xxx',
        ),
      );

      await session.signIn();

      expect(session.isSignedIn, isFalse);
      expect(session.status, OAuthSessionStatus.error);
      expect(session.errorMessage, contains('state'));
      expect(await store.read(), isNull);
    });

    test('Bungie error query leaves signed-out', () async {
      final store = MemoryTokenStore();
      final browser = FakeBrowserLauncher();
      final oauth = BungieOAuthClient(
        clientId: clientId,
        redirectUri: redirectUri,
        transport: (_) async => throw StateError('should not exchange'),
      );

      final session = WindowsOAuthSession(
        clientId: clientId,
        redirectUri: redirectUri,
        tokenStore: store,
        oauthClient: oauth,
        browserLauncher: browser,
        waitForCallbackOverride: () async => const LoopbackCallbackResult(
          error: 'access_denied',
          errorDescription: 'User denied',
          state: 'ignored',
        ),
      );

      await session.signIn();
      expect(session.isSignedIn, isFalse);
      expect(session.status, OAuthSessionStatus.error);
      expect(session.errorMessage, contains('User denied'));
      expect(await store.read(), isNull);
    });

    test('signOut clears tokens', () async {
      final store = MemoryTokenStore();
      final now = DateTime.now().toUtc();
      await store.write(
        BungieTokens(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAt: now.add(const Duration(hours: 1)),
          refreshExpiresAt: now.add(const Duration(days: 1)),
          bungieMembershipId: 'm1',
        ),
      );

      final oauth = BungieOAuthClient(
        clientId: clientId,
        redirectUri: redirectUri,
        transport: (_) async => throw StateError('unused'),
      );

      final session = WindowsOAuthSession(
        clientId: clientId,
        redirectUri: redirectUri,
        tokenStore: store,
        oauthClient: oauth,
        browserLauncher: FakeBrowserLauncher(),
      );
      await session.restore();
      expect(session.isSignedIn, isTrue);

      await session.signOut();
      expect(session.isSignedIn, isFalse);
      expect(session.status, OAuthSessionStatus.signedOut);
      expect(await store.read(), isNull);
    });

    test('restore keeps access-only Public session while access valid',
        () async {
      final store = MemoryTokenStore();
      final now = DateTime.now().toUtc();
      await store.write(
        BungieTokens(
          accessToken: 'acc-public-only',
          refreshToken: '',
          expiresAt: now.add(const Duration(minutes: 30)),
          refreshExpiresAt: now.add(const Duration(minutes: 30)),
          bungieMembershipId: 'mem-public',
        ),
      );

      final session = WindowsOAuthSession(
        clientId: clientId,
        redirectUri: redirectUri,
        tokenStore: store,
        oauthClient: BungieOAuthClient(
          clientId: clientId,
          redirectUri: redirectUri,
          transport: (_) async => throw StateError('must not refresh'),
        ),
        browserLauncher: FakeBrowserLauncher(),
      );

      await session.restore();
      expect(session.isSignedIn, isTrue);
      expect(session.membershipId, 'mem-public');
      expect((await store.read())!.accessToken, 'acc-public-only');
    });

    test('restore clears access-only session when access expired', () async {
      final store = MemoryTokenStore();
      final now = DateTime.now().toUtc();
      await store.write(
        BungieTokens(
          accessToken: 'acc-expired',
          refreshToken: '',
          expiresAt: now.subtract(const Duration(minutes: 1)),
          refreshExpiresAt: now.subtract(const Duration(minutes: 1)),
          bungieMembershipId: 'mem-expired',
        ),
      );

      final session = WindowsOAuthSession(
        clientId: clientId,
        redirectUri: redirectUri,
        tokenStore: store,
        oauthClient: BungieOAuthClient(
          clientId: clientId,
          redirectUri: redirectUri,
          transport: (_) async => throw StateError('must not refresh'),
        ),
        browserLauncher: FakeBrowserLauncher(),
      );

      await session.restore();
      expect(session.isSignedIn, isFalse);
      expect(session.status, OAuthSessionStatus.signedOut);
      expect(await store.read(), isNull);
    });

    test('restore keeps store on transient refresh failure', () async {
      final store = MemoryTokenStore();
      final now = DateTime.now().toUtc();
      await store.write(
        BungieTokens(
          accessToken: 'acc-stale',
          refreshToken: 'ref-keep',
          expiresAt: now.subtract(const Duration(minutes: 1)),
          refreshExpiresAt: now.add(const Duration(days: 30)),
          bungieMembershipId: 'mem-keep',
        ),
      );

      final session = WindowsOAuthSession(
        clientId: clientId,
        redirectUri: redirectUri,
        tokenStore: store,
        oauthClient: BungieOAuthClient(
          clientId: clientId,
          redirectUri: redirectUri,
          transport: (_) async => const BungieHttpResponse(
            statusCode: 503,
            body: '{"error":"server_error"}',
          ),
        ),
        browserLauncher: FakeBrowserLauncher(),
      );

      await session.restore();
      // Not signed in, but credentials must remain for next launch.
      expect(session.isSignedIn, isFalse);
      expect(session.status, OAuthSessionStatus.error);
      final kept = await store.read();
      expect(kept, isNotNull);
      expect(kept!.refreshToken, 'ref-keep');
    });

    test('restore refreshes when access expired and refresh present',
        () async {
      final store = MemoryTokenStore();
      final now = DateTime.now().toUtc();
      await store.write(
        BungieTokens(
          accessToken: 'acc-old',
          refreshToken: 'ref-live',
          expiresAt: now.subtract(const Duration(minutes: 1)),
          refreshExpiresAt: now.add(const Duration(days: 1)),
          bungieMembershipId: 'mem-refresh',
        ),
      );

      final session = WindowsOAuthSession(
        clientId: clientId,
        redirectUri: redirectUri,
        tokenStore: store,
        oauthClient: BungieOAuthClient(
          clientId: clientId,
          redirectUri: redirectUri,
          transport: (_) async => BungieHttpResponse(
            statusCode: 200,
            body: jsonEncode(rawTokenResponse(
              access: 'acc-new',
              refresh: 'ref-new',
              membershipId: 'mem-refresh',
            )),
          ),
        ),
        browserLauncher: FakeBrowserLauncher(),
      );

      await session.restore();
      expect(session.isSignedIn, isTrue);
      expect(session.tokens!.accessToken, 'acc-new');
      expect((await store.read())!.accessToken, 'acc-new');
    });

    test('missing client id is not configured', () async {
      final session = WindowsOAuthSession(
        clientId: '',
        redirectUri: redirectUri,
        tokenStore: MemoryTokenStore(),
        oauthClient: BungieOAuthClient(
          clientId: 'placeholder',
          redirectUri: redirectUri,
          transport: (_) async => throw StateError('unused'),
        ),
        browserLauncher: FakeBrowserLauncher(),
      );
      expect(session.isConfigured, isFalse);
      await session.signIn();
      expect(session.status, OAuthSessionStatus.error);
      expect(session.errorMessage, contains('not configured'));
    });
  });

  group('parseLoopbackRedirectUri', () {
    test('parses default Windows HTTPS redirect', () {
      final p = parseLoopbackRedirectUri('https://127.0.0.1:8765/callback');
      expect(p.host, '127.0.0.1');
      expect(p.port, 8765);
      expect(p.path, '/callback');
      expect(p.useTls, isTrue);
    });

    test('parses HTTP loopback without TLS', () {
      final p = parseLoopbackRedirectUri('http://127.0.0.1:8765/callback');
      expect(p.useTls, isFalse);
      expect(p.port, 8765);
    });

    test('rejects non-loopback host', () {
      expect(
        () => parseLoopbackRedirectUri('http://example.com/callback'),
        throwsFormatException,
      );
    });
  });
}
