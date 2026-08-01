import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:test/test.dart';

void main() {
  group('US1 PKCE pair', () {
    test('generatePkcePair produces S256 challenge matching verifier', () {
      final pair = generatePkcePair(random: Random(42));
      expect(pair.method, kPkceMethodS256);
      expect(pair.codeVerifier.length, 64);
      expect(RegExp(r'^[A-Za-z0-9\-._~]+$').hasMatch(pair.codeVerifier), isTrue);

      final digest = sha256.convert(utf8.encode(pair.codeVerifier));
      final expected =
          base64Url.encode(Uint8List.fromList(digest.bytes)).replaceAll('=', '');
      expect(pair.codeChallenge, expected);
      expect(pair.codeChallenge.contains('='), isFalse);
      expect(s256CodeChallenge(pair.codeVerifier), pair.codeChallenge);
    });

    test('rejects verifier length outside 43–128', () {
      expect(
        () => generatePkcePair(random: Random(1), verifierLength: 10),
        throwsArgumentError,
      );
    });
  });

  group('US1 OAuth state CSRF', () {
    test('validateOAuthState accepts equal state', () {
      expect(
        validateOAuthState(expected: 'abc-def_12', actual: 'abc-def_12'),
        isTrue,
      );
    });

    test('validateOAuthState rejects mismatch and empty', () {
      expect(
        validateOAuthState(expected: 'abc', actual: 'xyz'),
        isFalse,
      );
      expect(
        validateOAuthState(expected: 'abc', actual: 'ab'),
        isFalse,
      );
      expect(
        validateOAuthState(expected: '', actual: ''),
        isFalse,
      );
      expect(
        validateOAuthState(expected: 'a', actual: ''),
        isFalse,
      );
    });

    test('generateOAuthState is non-empty URL-safe', () {
      final state = generateOAuthState(random: Random(7));
      expect(state.length, 32);
      expect(RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(state), isTrue);
    });
  });

  group('US1 authorize URL', () {
    test('includes PKCE S256 params, state, client_id, redirect_uri', () {
      final client = BungieOAuthClient(
        clientId: 'cid-public',
        redirectUri: 'http://127.0.0.1:8765/callback',
        transport: (_) async =>
            const BungieHttpResponse(statusCode: 500, body: ''),
      );
      final pair = generatePkcePair(random: Random(3));
      const state = 'state-csrf-value';
      final url = client.buildAuthorizeUrl(
        state: state,
        codeChallenge: pair.codeChallenge,
      );

      final uri = Uri.parse(url);
      expect(uri.scheme, 'https');
      expect(uri.host, 'www.bungie.net');
      expect(uri.path, '/en/oauth/authorize');
      expect(uri.queryParameters['client_id'], 'cid-public');
      expect(uri.queryParameters['response_type'], 'code');
      expect(uri.queryParameters['state'], state);
      expect(
        uri.queryParameters['redirect_uri'],
        'http://127.0.0.1:8765/callback',
      );
      expect(uri.queryParameters['code_challenge'], pair.codeChallenge);
      expect(uri.queryParameters['code_challenge_method'], 'S256');
    });

    test('URL-encodes special characters in state', () {
      final client = BungieOAuthClient(
        clientId: 'c',
        redirectUri: 'http://127.0.0.1/cb',
        transport: (_) async =>
            const BungieHttpResponse(statusCode: 500, body: ''),
      );
      final url = client.buildAuthorizeUrl(
        state: 'a b+c',
        codeChallenge: 'challenge',
      );
      expect(url, isNot(contains('a b+c')));
      expect(Uri.parse(url).queryParameters['state'], 'a b+c');
    });

    test('rejects empty client id / redirect at construction', () {
      expect(
        () => BungieOAuthClient(
          clientId: '',
          redirectUri: 'http://x',
          transport: (_) async =>
              const BungieHttpResponse(statusCode: 500, body: ''),
        ),
        throwsA(isA<BungieConfigException>()),
      );
      expect(
        () => BungieOAuthClient(
          clientId: 'c',
          redirectUri: '  ',
          transport: (_) async =>
              const BungieHttpResponse(statusCode: 500, body: ''),
        ),
        throwsA(isA<BungieConfigException>()),
      );
    });
  });
}
