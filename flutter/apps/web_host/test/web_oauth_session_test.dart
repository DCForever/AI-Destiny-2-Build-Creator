import 'dart:convert';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_web_host/auth/pending_auth_store.dart';
import 'package:destiny2_web_host/auth/token_store.dart';
import 'package:destiny2_web_host/auth/web_auth_navigator.dart';
import 'package:destiny2_web_host/auth/web_oauth_config.dart';
import 'package:destiny2_web_host/auth/web_oauth_session.dart';
import 'package:test/test.dart';

BungieTokens _tokens({String membership = 'M999'}) {
  final now = DateTime.utc(2026, 7, 25, 12);
  return BungieTokens(
    accessToken: 'at-$membership',
    refreshToken: 'rt-$membership',
    expiresAt: now.add(const Duration(hours: 1)),
    refreshExpiresAt: now.add(const Duration(days: 30)),
    bungieMembershipId: membership,
  );
}

BungieHttpTransport _tokenExchangeTransport({
  required void Function(BungieHttpRequest request) onRequest,
  Map<String, dynamic>? responseBody,
  int statusCode = 200,
}) {
  return (request) async {
    onRequest(request);
    final body = responseBody ??
        {
          'access_token': 'at-new',
          'refresh_token': 'rt-new',
          'expires_in': 3600,
          'refresh_expires_in': 7776000,
          'membership_id': 'M777',
          'token_type': 'Bearer',
        };
    return BungieHttpResponse(
      statusCode: statusCode,
      body: jsonEncode(body),
    );
  };
}

void main() {
  const clientId = 'public-client-id';
  const redirect = 'https://127.0.0.1:8080/auth/callback';
  const config = WebOAuthConfig(
    clientId: clientId,
    redirectUri: redirect,
  );

  group('WebOAuthSession US2 sign-in', () {
    test('signIn navigates to authorize URL with PKCE S256 and no secret',
        () async {
      final nav = MemoryWebAuthNavigator(origin: 'https://127.0.0.1:8080');
      final pending = MemoryPendingAuthStore();
      final store = MemoryTokenStore();
      BungieHttpRequest? seen;
      final client = BungieOAuthClient(
        clientId: clientId,
        redirectUri: redirect,
        transport: _tokenExchangeTransport(onRequest: (r) => seen = r),
      );
      final session = WebOAuthSession(
        config: config,
        tokenStore: store,
        oauthClient: client,
        navigator: nav,
        pendingAuthStore: pending,
      );

      await session.signIn();

      expect(session.status, OAuthSessionStatus.signingIn);
      expect(nav.assigned, hasLength(1));
      final authUri = Uri.parse(nav.assigned.single);
      expect(authUri.host, 'www.bungie.net');
      expect(authUri.path, contains('oauth/authorize'));
      expect(authUri.queryParameters['client_id'], clientId);
      expect(authUri.queryParameters['response_type'], 'code');
      expect(authUri.queryParameters['redirect_uri'], redirect);
      expect(authUri.queryParameters['code_challenge_method'], 'S256');
      expect(authUri.queryParameters['code_challenge'], isNotEmpty);
      expect(authUri.queryParameters['state'], isNotEmpty);
      expect(authUri.queryParameters.containsKey('client_secret'), isFalse);
      expect(authUri.toString().contains('client_secret'), isFalse);

      final pendingAuth = await pending.read();
      expect(pendingAuth, isNotNull);
      expect(pendingAuth!.state, authUri.queryParameters['state']);
      expect(seen, isNull); // no token call until callback
    });

    test('completeCallback exchanges code and stores tokens', () async {
      final nav = MemoryWebAuthNavigator(origin: 'https://127.0.0.1:8080');
      final pending = MemoryPendingAuthStore();
      final store = MemoryTokenStore();
      BungieHttpRequest? tokenReq;
      final client = BungieOAuthClient(
        clientId: clientId,
        redirectUri: redirect,
        transport: _tokenExchangeTransport(onRequest: (r) => tokenReq = r),
      );
      final session = WebOAuthSession(
        config: config,
        tokenStore: store,
        oauthClient: client,
        navigator: nav,
        pendingAuthStore: pending,
      );

      await pending.write(
        const OAuthPendingAuth(
          state: 'csrf-state-ok',
          codeVerifier: 'verifier-abcdefghijklmnopqrstuvwxyz0123456789',
          redirectUri: redirect,
        ),
      );

      await session.completeCallback(
        callbackUri: Uri.parse(
          '$redirect?code=auth-code-1&state=csrf-state-ok',
        ),
      );

      expect(session.isSignedIn, isTrue);
      expect(session.membershipId, 'M777');
      expect(await store.read(), isNotNull);
      expect(await pending.read(), isNull);
      expect(tokenReq, isNotNull);
      expect(tokenReq!.body, isNotNull);
      expect(tokenReq!.body!.contains('grant_type=authorization_code'), isTrue);
      expect(tokenReq!.body!.contains('code_verifier='), isTrue);
      expect(tokenReq!.body!.contains('client_id=$clientId'), isTrue);
      expect(tokenReq!.body!.contains('client_secret'), isFalse);
      expect(
        tokenReq!.headers['Authorization'] ?? '',
        isNot(contains('Basic')),
      );
      expect(nav.assigned.last, '/settings');
    });

    test('state mismatch fails without storing tokens', () async {
      final nav = MemoryWebAuthNavigator();
      final pending = MemoryPendingAuthStore();
      final store = MemoryTokenStore();
      var exchanges = 0;
      final client = BungieOAuthClient(
        clientId: clientId,
        redirectUri: redirect,
        transport: _tokenExchangeTransport(onRequest: (_) => exchanges++),
      );
      final session = WebOAuthSession(
        config: config,
        tokenStore: store,
        oauthClient: client,
        navigator: nav,
        pendingAuthStore: pending,
      );
      await pending.write(
        const OAuthPendingAuth(
          state: 'expected-state',
          codeVerifier: 'verifier-abcdefghijklmnopqrstuvwxyz0123456789',
          redirectUri: redirect,
        ),
      );

      await session.completeCallback(
        callbackUri: Uri.parse('$redirect?code=c1&state=wrong-state-xx'),
      );

      expect(session.isSignedIn, isFalse);
      expect(session.status, OAuthSessionStatus.error);
      expect(await store.read(), isNull);
      expect(exchanges, 0);
    });

    test('Bungie error query yields error status', () async {
      final session = WebOAuthSession(
        config: config,
        tokenStore: MemoryTokenStore(),
        oauthClient: BungieOAuthClient(
          clientId: clientId,
          redirectUri: redirect,
          transport: _tokenExchangeTransport(onRequest: (_) {}),
        ),
        navigator: MemoryWebAuthNavigator(),
        pendingAuthStore: MemoryPendingAuthStore(),
      );

      await session.completeCallback(
        callbackUri: Uri.parse(
          '$redirect?error=access_denied&error_description=User+denied',
        ),
      );

      expect(session.isSignedIn, isFalse);
      expect(session.status, OAuthSessionStatus.error);
      expect(session.errorMessage, contains('denied'));
    });
  });

  group('WebOAuthSession US3 sign-out + restore', () {
    test('restore loads tokens; signOut clears', () async {
      final store = MemoryTokenStore();
      await store.write(_tokens(membership: 'M123'));
      final session = WebOAuthSession(
        config: config,
        tokenStore: store,
        oauthClient: BungieOAuthClient(
          clientId: clientId,
          redirectUri: redirect,
          transport: _tokenExchangeTransport(onRequest: (_) {}),
        ),
        navigator: MemoryWebAuthNavigator(),
      );

      await session.restore();
      expect(session.isSignedIn, isTrue);
      expect(session.membershipId, 'M123');

      await session.signOut();
      expect(session.isSignedIn, isFalse);
      expect(session.status, OAuthSessionStatus.signedOut);
      expect(await store.read(), isNull);
    });

    test('missing client id → signIn error / not configured', () async {
      final session = WebOAuthSession(
        config: const WebOAuthConfig(clientId: '', redirectUri: redirect),
        tokenStore: MemoryTokenStore(),
        oauthClient: BungieOAuthClient(
          clientId: 'placeholder',
          redirectUri: redirect,
          transport: _tokenExchangeTransport(onRequest: (_) {}),
        ),
        navigator: MemoryWebAuthNavigator(),
      );

      expect(session.isConfigured, isFalse);
      await session.signIn();
      expect(session.status, OAuthSessionStatus.error);
      expect(session.errorMessage, contains('BUNGIE_CLIENT_ID'));
    });
  });

  group('WebOAuthConfig', () {
    test('default redirect uses origin + /auth/callback', () {
      final c = WebOAuthConfig.resolve(
        clientId: 'cid',
        redirectUriOverride: '',
        origin: 'https://app.example',
      );
      expect(c.redirectUri, 'https://app.example/auth/callback');
      expect(c.isConfigured, isTrue);
    });

    test('override wins', () {
      final c = WebOAuthConfig.resolve(
        clientId: 'cid',
        redirectUriOverride: 'https://127.0.0.1:8443/auth/callback',
        origin: 'https://ignored.example',
      );
      expect(c.redirectUri, 'https://127.0.0.1:8443/auth/callback');
    });
  });
}
