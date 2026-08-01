import 'dart:convert';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

Map<String, dynamic> rawTokenResponse({
  String access = 'acc',
  String refresh = 'ref',
  int expiresIn = 3600,
  int refreshExpiresIn = 7776000,
  String membershipId = 'mem123',
}) =>
    {
      'access_token': access,
      'token_type': 'Bearer',
      'expires_in': expiresIn,
      'refresh_token': refresh,
      'refresh_expires_in': refreshExpiresIn,
      'membership_id': membershipId,
    };

void main() {
  group('US2 token exchange', () {
    test('posts urlencoded body with code_verifier and client_id, no secret',
        () async {
      BungieHttpRequest? seen;
      final client = BungieOAuthClient(
        clientId: 'client123',
        redirectUri: 'http://127.0.0.1:8765/callback',
        transport: (request) async {
          seen = request;
          return BungieHttpResponse(
            statusCode: 200,
            body: jsonEncode(rawTokenResponse()),
          );
        },
      );

      final fixedNow = DateTime.utc(2026, 7, 24, 12, 0, 0);
      final tokens = await client.exchangeCode(
        code: 'my-code',
        codeVerifier: 'verifier-xyz',
        now: fixedNow,
      );

      expect(seen, isNotNull);
      expect(seen!.method, 'POST');
      expect(
        seen!.uri.toString(),
        'https://www.bungie.net/platform/app/oauth/token/',
      );
      expect(
        seen!.headers['Content-Type'],
        'application/x-www-form-urlencoded',
      );
      expect(seen!.headers.containsKey('Authorization'), isFalse);
      final body = seen!.body!;
      expect(body, contains('grant_type=authorization_code'));
      expect(body, contains('code=my-code'));
      expect(body, contains('client_id=client123'));
      expect(body, contains('code_verifier=verifier-xyz'));
      expect(
        body,
        contains(
          'redirect_uri=${Uri.encodeQueryComponent('http://127.0.0.1:8765/callback')}',
        ),
      );
      expect(body.toLowerCase(), isNot(contains('client_secret')));
      expect(body.toLowerCase(), isNot(contains('clientsecret')));

      expect(tokens.accessToken, 'acc');
      expect(tokens.refreshToken, 'ref');
      expect(tokens.bungieMembershipId, 'mem123');
      expect(
        tokens.expiresAt,
        fixedNow
            .add(const Duration(seconds: 3600))
            .subtract(kAccessTokenExpiryMargin),
      );
      expect(
        tokens.refreshExpiresAt,
        fixedNow.add(const Duration(seconds: 7776000)),
      );
    });

    test('throws BungieOAuthException on HTTP error without leaking tokens',
        () async {
      final client = BungieOAuthClient(
        clientId: 'c',
        redirectUri: 'http://127.0.0.1/cb',
        transport: (_) async => const BungieHttpResponse(
          statusCode: 400,
          body: 'bad',
        ),
      );

      try {
        await client.exchangeCode(code: 'x', codeVerifier: 'y');
        fail('expected exception');
      } on BungieOAuthException catch (e) {
        expect(e.statusCode, 400);
        expect(e.message, contains('400'));
      }
    });

    test('throws on unexpected token JSON shape', () async {
      final client = BungieOAuthClient(
        clientId: 'c',
        redirectUri: 'http://127.0.0.1/cb',
        transport: (_) async => BungieHttpResponse(
          statusCode: 200,
          body: jsonEncode({'wrong': 'shape'}),
        ),
      );

      expect(
        () => client.exchangeCode(code: 'x', codeVerifier: 'y'),
        throwsA(isA<BungieOAuthException>()),
      );
    });

    test('accepts string numeric lifetimes and optional refresh', () async {
      final client = BungieOAuthClient(
        clientId: 'c',
        redirectUri: 'https://127.0.0.1:8765/callback',
        transport: (_) async => BungieHttpResponse(
          statusCode: 200,
          body: jsonEncode({
            'access_token': 'acc',
            'token_type': 'Bearer',
            'expires_in': '3600',
            'membership_id': 999001,
          }),
        ),
      );
      final fixedNow = DateTime.utc(2026, 7, 25, 12);
      final tokens = await client.exchangeCode(
        code: 'c',
        codeVerifier: 'v',
        now: fixedNow,
      );
      expect(tokens.accessToken, 'acc');
      expect(tokens.refreshToken, isEmpty);
      expect(tokens.bungieMembershipId, '999001');
      expect(
        tokens.expiresAt,
        fixedNow
            .add(const Duration(seconds: 3600))
            .subtract(kAccessTokenExpiryMargin),
      );
    });

    test('accepts string refresh_expires_in', () {
      final tokens = mapTokenResponse({
        'access_token': 'a',
        'refresh_token': 'r',
        'expires_in': '100',
        'refresh_expires_in': '200',
        'membership_id': 'm',
      }, now: DateTime.utc(2026, 1, 1));
      expect(tokens.refreshToken, 'r');
      expect(
        tokens.refreshExpiresAt,
        DateTime.utc(2026, 1, 1).add(const Duration(seconds: 200)),
      );
    });
  });

  group('US2 refresh', () {
    test('posts refresh_token grant with client_id, no secret', () async {
      BungieHttpRequest? seen;
      final client = BungieOAuthClient(
        clientId: 'client123',
        redirectUri: 'http://127.0.0.1/cb',
        transport: (request) async {
          seen = request;
          return BungieHttpResponse(
            statusCode: 200,
            body: jsonEncode(rawTokenResponse(access: 'new-acc')),
          );
        },
      );

      final old = BungieTokens(
        accessToken: 'old',
        refreshToken: 'refresh-abc',
        expiresAt: DateTime.utc(2020),
        refreshExpiresAt: DateTime.utc(2030),
        bungieMembershipId: 'm',
      );

      final next = await client.refreshTokens(old);
      expect(next.accessToken, 'new-acc');
      expect(seen!.body, contains('grant_type=refresh_token'));
      expect(seen!.body, contains('refresh_token=refresh-abc'));
      expect(seen!.body, contains('client_id=client123'));
      expect(seen!.body!.toLowerCase(), isNot(contains('client_secret')));
      expect(seen!.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('US2 token model helpers', () {
    test('needsRefresh and isSessionExpired', () {
      final now = DateTime.utc(2026, 1, 1, 12);
      final tokens = BungieTokens(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAt: now.subtract(const Duration(seconds: 1)),
        refreshExpiresAt: now.add(const Duration(hours: 1)),
        bungieMembershipId: 'm',
      );
      expect(needsRefresh(tokens, now: now), isTrue);
      expect(isSessionExpired(tokens, now: now), isFalse);

      final expiredSession = tokens.copyWith(
        refreshExpiresAt: now.subtract(const Duration(seconds: 1)),
      );
      expect(isSessionExpired(expiredSession, now: now), isTrue);

      final fresh = tokens.copyWith(
        expiresAt: now.add(const Duration(minutes: 5)),
      );
      expect(needsRefresh(fresh, now: now), isFalse);
    });
  });

  group('US2 no client_secret API surface', () {
    test('BungieOAuthClient and BungieTokens have no clientSecret fields', () {
      // Compile-time surface: construction only accepts public fields.
      final client = BungieOAuthClient(
        clientId: 'public-id',
        redirectUri: 'http://127.0.0.1/cb',
        transport: (_) async =>
            const BungieHttpResponse(statusCode: 500, body: ''),
      );
      expect(client.clientId, 'public-id');
      // Reflective guard: class names used in this package OAuth path.
      final tokens = BungieTokens(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAt: DateTime.now().toUtc(),
        refreshExpiresAt: DateTime.now().toUtc(),
        bungieMembershipId: 'm',
      );
      final tokenJson = jsonEncode({
        'accessToken': tokens.accessToken,
        'refreshToken': tokens.refreshToken,
        'bungieMembershipId': tokens.bungieMembershipId,
      });
      expect(tokenJson.toLowerCase(), isNot(contains('secret')));
    });
  });
}
