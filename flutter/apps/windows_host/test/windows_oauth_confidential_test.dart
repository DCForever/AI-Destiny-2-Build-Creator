import 'dart:async';
import 'dart:convert';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_windows_host/auth/client_credential_store.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/auth/windows_oauth_session.dart';
import 'package:flutter_test/flutter_test.dart';

const _fakeCredential = 'FAKE-BUNGIE-APP-CREDENTIAL-not-real';
const _fakeAccess = 'FAKE-ACCESS-TOKEN-aabbcc';
const _fakeRefresh = 'FAKE-REFRESH-TOKEN-ddeeff';

BungieTokens _tokens({
  required DateTime now,
  String access = _fakeAccess,
  String refresh = _fakeRefresh,
  Duration accessTtl = const Duration(minutes: -1),
  Duration refreshTtl = const Duration(days: 30),
}) {
  return BungieTokens(
    accessToken: access,
    refreshToken: refresh,
    expiresAt: now.add(accessTtl),
    refreshExpiresAt: now.add(refreshTtl),
    bungieMembershipId: 'mem-c',
  );
}

String _tokenJson({
  String access = 'acc-new',
  String refresh = 'ref-rotated',
}) =>
    jsonEncode({
      'access_token': access,
      'token_type': 'Bearer',
      'expires_in': 3600,
      'refresh_token': refresh,
      'refresh_expires_in': 7776000,
      'membership_id': 'mem-c',
    });

void _assertNoSecrets(Iterable<String> haystacks) {
  for (final h in haystacks) {
    expect(h, isNot(contains(_fakeCredential)));
    expect(h, isNot(contains(_fakeAccess)));
    expect(h, isNot(contains(_fakeRefresh)));
  }
}

class _FailWriteStore implements TokenStore {
  _FailWriteStore(this.inner);
  final MemoryTokenStore inner;
  bool failNextWrite = false;

  @override
  Future<BungieTokens?> read() => inner.read();

  @override
  Future<BungieTokens?> readSecureOnly() => inner.readSecureOnly();

  @override
  Future<void> write(BungieTokens tokens) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('simulated credential manager write failure');
    }
    await inner.write(tokens);
  }

  @override
  Future<void> clear() => inner.clear();

  @override
  Future<void> clearSecureOnly() => inner.clearSecureOnly();

  @override
  Future<void> deleteLegacySidecarIfPresent() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('C3 secret never in logs/errors', () {
    test('refresh + failed exchange omit credential and tokens from logs',
        () async {
      final logs = <String>[];
      final errors = <Object>[];
      final creds = MemoryClientCredentialStore();
      await creds.write(_fakeCredential);
      final store = MemoryTokenStore();
      final now = DateTime.now().toUtc();
      await store.write(_tokens(now: now));

      var calls = 0;
      final session = WindowsOAuthSession(
        clientId: 'cid',
        redirectUri: 'https://127.0.0.1:8765/callback',
        tokenStore: store,
        credentialStore: creds,
        oauthClient: BungieOAuthClient(
          clientId: 'cid',
          redirectUri: 'https://127.0.0.1:8765/callback',
          transport: (_) async {
            calls++;
            if (calls == 1) {
              return BungieHttpResponse(
                statusCode: 200,
                body: _tokenJson(access: 'acc-ok', refresh: 'ref-ok'),
              );
            }
            return const BungieHttpResponse(
              statusCode: 400,
              body: '{"error":"invalid_grant","error_description":"bad"}',
            );
          },
        ),
        log: logs.add,
      );

      await session.restore();
      expect(session.isSignedIn, isTrue);
      expect(session.isConfidentialMode, isTrue);

      try {
        await session.runAuthorized((_) async {
          throw const BungieHttpException('unauthorized', statusCode: 401);
        });
      } catch (e) {
        errors.add(e);
      }

      _assertNoSecrets([...logs, ...errors.map((e) => e.toString())]);
      expect(
        logs.any((l) => l.contains('confidential=on')),
        isTrue,
      );
      expect(
        logs.any((l) => RegExp(r'credential.*len|secret.*len', caseSensitive: false)
            .hasMatch(l)),
        isFalse,
      );
    });
  });

  group('C4 atomic token pair persist', () {
    test('rotated refresh is written as one pair', () async {
      final store = MemoryTokenStore();
      final creds = MemoryClientCredentialStore();
      await creds.write(_fakeCredential);
      final now = DateTime.now().toUtc();
      await store.write(_tokens(now: now));

      final session = WindowsOAuthSession(
        clientId: 'cid',
        redirectUri: 'https://127.0.0.1:8765/callback',
        tokenStore: store,
        credentialStore: creds,
        oauthClient: BungieOAuthClient(
          clientId: 'cid',
          redirectUri: 'https://127.0.0.1:8765/callback',
          transport: (_) async => BungieHttpResponse(
            statusCode: 200,
            body: _tokenJson(access: 'acc-rot', refresh: 'ref-rot'),
          ),
        ),
      );

      await session.restore();
      final saved = await store.read();
      expect(saved!.accessToken, 'acc-rot');
      expect(saved.refreshToken, 'ref-rot');
    });

    test('persist failure signs out instead of using unsaved tokens', () async {
      final inner = MemoryTokenStore();
      final store = _FailWriteStore(inner);
      final creds = MemoryClientCredentialStore();
      await creds.write(_fakeCredential);
      final now = DateTime.now().toUtc();
      await inner.write(_tokens(now: now));
      store.failNextWrite = true;

      final session = WindowsOAuthSession(
        clientId: 'cid',
        redirectUri: 'https://127.0.0.1:8765/callback',
        tokenStore: store,
        credentialStore: creds,
        oauthClient: BungieOAuthClient(
          clientId: 'cid',
          redirectUri: 'https://127.0.0.1:8765/callback',
          transport: (_) async => BungieHttpResponse(
            statusCode: 200,
            body: _tokenJson(access: 'unsaved-acc', refresh: 'unsaved-ref'),
          ),
        ),
      );

      await session.restore();
      expect(session.isSignedIn, isFalse);
      expect(session.tokens, isNull);
      expect(await inner.read(), isNull);
      expect(session.isConfidentialMode, isTrue);
    });
  });

  group('C5 coalesced 401 refresh / no loop', () {
    test('concurrent callers share one in-flight refresh', () async {
      final store = MemoryTokenStore();
      final creds = MemoryClientCredentialStore();
      final now = DateTime.now().toUtc();
      await store.write(
        _tokens(now: now, accessTtl: const Duration(hours: 1)),
      );

      var refreshCalls = 0;
      final refreshGate = Completer<void>();
      final session = WindowsOAuthSession(
        clientId: 'cid',
        redirectUri: 'https://127.0.0.1:8765/callback',
        tokenStore: store,
        credentialStore: creds,
        oauthClient: BungieOAuthClient(
          clientId: 'cid',
          redirectUri: 'https://127.0.0.1:8765/callback',
          transport: (_) async {
            refreshCalls++;
            await refreshGate.future;
            return BungieHttpResponse(
              statusCode: 200,
              body: _tokenJson(access: 'acc-shared', refresh: 'ref-shared'),
            );
          },
        ),
      );
      await session.restore();

      Future<String> call() => session.runAuthorized((token) async {
            if (token != 'acc-shared') {
              throw const BungieHttpException('401', statusCode: 401);
            }
            return token;
          });

      final f1 = call();
      final f2 = call();
      await Future<void>.delayed(Duration.zero);
      expect(refreshCalls, 1);
      refreshGate.complete();
      final results = await Future.wait([f1, f2]);
      expect(results, ['acc-shared', 'acc-shared']);
      expect(refreshCalls, 1);
    });

    test('invalid_grant signs out without loop', () async {
      final store = MemoryTokenStore();
      final now = DateTime.now().toUtc();
      await store.write(
        _tokens(now: now, accessTtl: const Duration(hours: 1)),
      );
      final session = WindowsOAuthSession(
        clientId: 'cid',
        redirectUri: 'https://127.0.0.1:8765/callback',
        tokenStore: store,
        credentialStore: MemoryClientCredentialStore(),
        oauthClient: BungieOAuthClient(
          clientId: 'cid',
          redirectUri: 'https://127.0.0.1:8765/callback',
          transport: (_) async => const BungieHttpResponse(
            statusCode: 400,
            body: '{"error":"invalid_grant"}',
          ),
        ),
      );
      await session.restore();

      await expectLater(
        () => session.runAuthorized((_) async {
          throw const BungieHttpException('401', statusCode: 401);
        }),
        throwsA(isA<BungieOAuthException>()),
      );
      expect(session.isSignedIn, isFalse);
      expect(await store.read(), isNull);
      expect(session.promptForgetCredential, isFalse);
    });

    test('invalid_client signs out and prompts Forget client secret', () async {
      final store = MemoryTokenStore();
      final creds = MemoryClientCredentialStore();
      await creds.write(_fakeCredential);
      final now = DateTime.now().toUtc();
      await store.write(
        _tokens(now: now, accessTtl: const Duration(hours: 1)),
      );
      final session = WindowsOAuthSession(
        clientId: 'cid',
        redirectUri: 'https://127.0.0.1:8765/callback',
        tokenStore: store,
        credentialStore: creds,
        oauthClient: BungieOAuthClient(
          clientId: 'cid',
          redirectUri: 'https://127.0.0.1:8765/callback',
          transport: (_) async => const BungieHttpResponse(
            statusCode: 401,
            body: '{"error":"invalid_client"}',
          ),
        ),
      );
      await session.restore();

      await expectLater(
        () => session.runAuthorized((_) async {
          throw const BungieHttpException('401', statusCode: 401);
        }),
        throwsA(isA<BungieOAuthException>()),
      );
      expect(session.isSignedIn, isFalse);
      expect(session.promptForgetCredential, isTrue);
      expect(await creds.hasCredential, isTrue);
    });

    test('network refresh error keeps tokens', () async {
      final store = MemoryTokenStore();
      final now = DateTime.now().toUtc();
      await store.write(_tokens(now: now));
      final session = WindowsOAuthSession(
        clientId: 'cid',
        redirectUri: 'https://127.0.0.1:8765/callback',
        tokenStore: store,
        credentialStore: MemoryClientCredentialStore(),
        oauthClient: BungieOAuthClient(
          clientId: 'cid',
          redirectUri: 'https://127.0.0.1:8765/callback',
          transport: (_) async => const BungieHttpResponse(
            statusCode: 503,
            body: '{"error":"server_error"}',
          ),
        ),
      );
      await session.restore();
      expect(session.isSignedIn, isFalse);
      expect(session.status, OAuthSessionStatus.error);
      expect((await store.read())!.refreshToken, _fakeRefresh);
    });

    test('second 401 after refresh signs out', () async {
      final store = MemoryTokenStore();
      final now = DateTime.now().toUtc();
      await store.write(
        _tokens(now: now, accessTtl: const Duration(hours: 1)),
      );
      final session = WindowsOAuthSession(
        clientId: 'cid',
        redirectUri: 'https://127.0.0.1:8765/callback',
        tokenStore: store,
        credentialStore: MemoryClientCredentialStore(),
        oauthClient: BungieOAuthClient(
          clientId: 'cid',
          redirectUri: 'https://127.0.0.1:8765/callback',
          transport: (_) async => BungieHttpResponse(
            statusCode: 200,
            body: _tokenJson(access: 'acc-retry', refresh: 'ref-retry'),
          ),
        ),
      );
      await session.restore();

      await expectLater(
        () => session.runAuthorized((_) async {
          throw const BungieHttpException('401', statusCode: 401);
        }),
        throwsA(isA<BungieHttpException>()),
      );
      expect(session.isSignedIn, isFalse);
      expect(await store.read(), isNull);
    });
  });

  group('C6 public default + forget keeps tokens on sign-out', () {
    test('no stored credential stays Public (no Authorization header)',
        () async {
      BungieHttpRequest? seen;
      final store = MemoryTokenStore();
      final now = DateTime.now().toUtc();
      await store.write(_tokens(now: now));
      final session = WindowsOAuthSession(
        clientId: 'cid',
        redirectUri: 'https://127.0.0.1:8765/callback',
        tokenStore: store,
        credentialStore: MemoryClientCredentialStore(),
        oauthClient: BungieOAuthClient(
          clientId: 'cid',
          redirectUri: 'https://127.0.0.1:8765/callback',
          transport: (r) async {
            seen = r;
            return BungieHttpResponse(
              statusCode: 200,
              body: _tokenJson(),
            );
          },
        ),
      );
      await session.restore();
      expect(session.isConfidentialMode, isFalse);
      expect(seen!.headers.containsKey('Authorization'), isFalse);
    });

    test('signOut clears tokens but keeps credential', () async {
      final store = MemoryTokenStore();
      final creds = MemoryClientCredentialStore();
      await creds.write(_fakeCredential);
      final now = DateTime.now().toUtc();
      await store.write(
        _tokens(now: now, accessTtl: const Duration(hours: 1)),
      );
      final session = WindowsOAuthSession(
        clientId: 'cid',
        redirectUri: 'https://127.0.0.1:8765/callback',
        tokenStore: store,
        credentialStore: creds,
        oauthClient: BungieOAuthClient(
          clientId: 'cid',
          redirectUri: 'https://127.0.0.1:8765/callback',
          transport: (_) async => throw StateError('unused'),
        ),
      );
      await session.restore();
      await session.signOut();
      expect(await store.read(), isNull);
      expect(await creds.hasCredential, isTrue);
      expect(session.isConfidentialMode, isTrue);

      await session.forgetClientCredential();
      expect(await creds.hasCredential, isFalse);
      expect(session.isConfidentialMode, isFalse);
    });
  });
}
