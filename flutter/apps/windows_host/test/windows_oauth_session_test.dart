import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/loopback_callback_server.dart';
import 'package:destiny2_windows_host/auth/token_codec.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/auth/windows_oauth_session.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

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

class _CorruptThrowingStore implements TokenStore {
  bool cleared = false;
  bool clearedSecureOnly = false;

  @override
  Future<BungieTokens?> read() async {
    throw const TokenStoreCorruptException();
  }

  @override
  Future<BungieTokens?> readSecureOnly() async {
    throw const TokenStoreCorruptException();
  }

  @override
  Future<void> write(BungieTokens tokens) async {}

  @override
  Future<void> clear() async {
    cleared = true;
  }

  @override
  Future<void> clearSecureOnly() async {
    clearedSecureOnly = true;
  }

  @override
  Future<void> deleteLegacySidecarIfPresent() async {}
}

/// Corrupt Locker payload without using FlutterSecureStorage.
class _CorruptRawPrimary implements TokenStore {
  _CorruptRawPrimary(this.raw);

  String? raw;
  int clearSecureOnlyCalls = 0;
  int clearCalls = 0;

  @override
  Future<BungieTokens?> read() async {
    if (raw == null || raw!.trim().isEmpty) return null;
    final decoded = decodeBungieTokens(raw);
    if (decoded == null) throw const TokenStoreCorruptException();
    return decoded;
  }

  @override
  Future<BungieTokens?> readSecureOnly() async => read();

  @override
  Future<void> write(BungieTokens tokens) async {
    raw = encodeBungieTokens(tokens);
  }

  @override
  Future<void> clear() async {
    clearCalls += 1;
    raw = null;
  }

  @override
  Future<void> clearSecureOnly() async {
    clearSecureOnlyCalls += 1;
    raw = null;
  }

  @override
  Future<void> deleteLegacySidecarIfPresent() async {}
}

/// In-memory primary for DualTokenStore session tests.
class _MemoryPrimary implements TokenStore {
  String? raw;
  int readSecureOnlyCalls = 0;
  int readCalls = 0;

  @override
  Future<BungieTokens?> read() async {
    readCalls += 1;
    if (raw == null || raw!.trim().isEmpty) return null;
    return decodeBungieTokens(raw);
  }

  @override
  Future<BungieTokens?> readSecureOnly() async {
    readSecureOnlyCalls += 1;
    return read();
  }

  @override
  Future<void> write(BungieTokens tokens) async {
    raw = encodeBungieTokens(tokens);
  }

  @override
  Future<void> clear() async {
    raw = null;
  }

  @override
  Future<void> clearSecureOnly() async {
    raw = null;
  }

  @override
  Future<void> deleteLegacySidecarIfPresent() async {}
}

/// First migration write leaves Locker empty (null read-back); later writes stick.
class _FailOnceThenOkPrimary implements TokenStore {
  int writeCount = 0;
  BungieTokens? _tokens;

  @override
  Future<BungieTokens?> read() async => _tokens;

  @override
  Future<BungieTokens?> readSecureOnly() async => _tokens;

  @override
  Future<void> write(BungieTokens tokens) async {
    writeCount += 1;
    if (writeCount == 1) {
      _tokens = null; // force null read-back → rollback
      return;
    }
    _tokens = tokens;
  }

  @override
  Future<void> clear() async {
    _tokens = null;
  }

  @override
  Future<void> clearSecureOnly() async {
    _tokens = null;
  }

  @override
  Future<void> deleteLegacySidecarIfPresent() async {}
}

/// Write appears to succeed but secure read-back is always null (failed persist).
class _WriteOkNullReadPrimary implements TokenStore {
  int clearSecureOnlyCalls = 0;
  int deleteSidecarCalls = 0;
  int readSecureOnlyCalls = 0;
  int readCalls = 0;

  @override
  Future<BungieTokens?> read() async {
    readCalls += 1;
    return null;
  }

  @override
  Future<BungieTokens?> readSecureOnly() async {
    readSecureOnlyCalls += 1;
    return null;
  }

  @override
  Future<void> write(BungieTokens tokens) async {}

  @override
  Future<void> clear() async {}

  @override
  Future<void> clearSecureOnly() async {
    clearSecureOnlyCalls += 1;
  }

  @override
  Future<void> deleteLegacySidecarIfPresent() async {
    deleteSidecarCalls += 1;
  }
}

/// Tracks clearSecureOnly while holding an existing good session.
class _CountingMemoryStore implements TokenStore {
  BungieTokens? _tokens;
  int clearSecureOnlyCalls = 0;

  @override
  Future<BungieTokens?> read() async => _tokens;

  @override
  Future<BungieTokens?> readSecureOnly() async => _tokens;

  @override
  Future<void> write(BungieTokens tokens) async {
    _tokens = tokens;
  }

  @override
  Future<void> clear() async {
    _tokens = null;
  }

  @override
  Future<void> clearSecureOnly() async {
    clearSecureOnlyCalls += 1;
    _tokens = null;
  }

  @override
  Future<void> deleteLegacySidecarIfPresent() async {}
}

/// First write sticks; later writes appear to succeed but secure read is null.
class _VerifyFailAfterWriteStore implements TokenStore {
  BungieTokens? _tokens;
  int writeCount = 0;

  @override
  Future<BungieTokens?> read() async => _tokens;

  @override
  Future<BungieTokens?> readSecureOnly() async {
    // After the re-sign-in write (writeCount >= 2), pretend verify failed
    // until rollback rewrites the prior session (writeCount keeps climbing).
    if (writeCount == 2) return null;
    return _tokens;
  }

  @override
  Future<void> write(BungieTokens tokens) async {
    writeCount += 1;
    _tokens = tokens;
  }

  @override
  Future<void> clear() async {
    _tokens = null;
  }

  @override
  Future<void> clearSecureOnly() async {
    _tokens = null;
  }

  @override
  Future<void> deleteLegacySidecarIfPresent() async {}
}

/// Fake loopback for stop()-isolation tests (no real HTTP bind).
class FakeLoopbackCallbackServer extends LoopbackCallbackServer {
  FakeLoopbackCallbackServer({
    required this.onWait,
    this.stopThrows = false,
  });

  final Future<LoopbackCallbackResult> Function() onWait;
  final bool stopThrows;
  bool started = false;
  bool stopCalled = false;

  @override
  Future<void> start({
    String host = '127.0.0.1',
    required int port,
    String callbackPath = '/callback',
    bool useTls = false,
  }) async {
    started = true;
  }

  @override
  bool get isRunning => started;

  @override
  Future<LoopbackCallbackResult> waitForCallback({
    Duration timeout = const Duration(minutes: 5),
  }) =>
      onWait();

  @override
  Future<void> stop() async {
    stopCalled = true;
    started = false;
    if (stopThrows) {
      throw StateError('loopback stop failed');
    }
  }
}

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
      expect(
        session.errorMessage,
        'Sign-in could not be verified. Please try again.',
      );
      expect(session.errorMessage, isNot(contains('CSRF')));
      expect(await store.read(), isNull);
    });

    test('Bungie error query leaves signed-out', () async {
      final store = MemoryTokenStore();
      final browser = FakeBrowserLauncher();
      final logs = <String>[];
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
        log: logs.add,
        waitForCallbackOverride: () async => const LoopbackCallbackResult(
          error: 'access_denied',
          errorDescription: 'User denied SECRET-should-not-leak',
          state: 'ignored',
        ),
      );

      await session.signIn();
      expect(session.isSignedIn, isFalse);
      expect(session.status, OAuthSessionStatus.error);
      expect(
        session.errorMessage,
        'Sign-in was cancelled. Try again when ready.',
      );
      expect(session.errorMessage, isNot(contains('User denied')));
      expect(session.errorMessage, isNot(contains('SECRET')));
      expect(await store.read(), isNull);
      // (d) callback log has flags only — no raw error value.
      final callbackLogs =
          logs.where((l) => l.contains('callback received')).toList();
      expect(callbackLogs, isNotEmpty);
      for (final line in callbackLogs) {
        expect(line, contains('hasError=true'));
        expect(line, isNot(contains('access_denied')));
        expect(line, isNot(contains('User denied')));
        expect(line, isNot(contains('SECRET')));
      }
    });

    test('(a) access_denied maps to friendly cancelled text', () async {
      final session = WindowsOAuthSession(
        clientId: clientId,
        redirectUri: redirectUri,
        tokenStore: MemoryTokenStore(),
        oauthClient: BungieOAuthClient(
          clientId: clientId,
          redirectUri: redirectUri,
          transport: (_) async => throw StateError('unused'),
        ),
        browserLauncher: FakeBrowserLauncher(),
        waitForCallbackOverride: () async => const LoopbackCallbackResult(
          error: 'access_denied',
          errorDescription: 'raw provider text must not appear',
        ),
      );
      await session.signIn();
      expect(
        session.errorMessage,
        'Sign-in was cancelled. Try again when ready.',
      );
      expect(session.errorMessage, isNot(contains('raw provider')));
    });

    test('(a) state mismatch maps to friendly verified text', () async {
      final session = WindowsOAuthSession(
        clientId: clientId,
        redirectUri: redirectUri,
        tokenStore: MemoryTokenStore(),
        oauthClient: BungieOAuthClient(
          clientId: clientId,
          redirectUri: redirectUri,
          transport: (_) async => throw StateError('unused'),
        ),
        browserLauncher: FakeBrowserLauncher(),
        waitForCallbackOverride: () async => const LoopbackCallbackResult(
          code: 'code',
          state: 'wrong-state',
        ),
      );
      await session.signIn();
      expect(
        session.errorMessage,
        'Sign-in could not be verified. Please try again.',
      );
    });

    test('(a) callback timeout maps to friendly timeout text', () async {
      final session = WindowsOAuthSession(
        clientId: clientId,
        redirectUri: redirectUri,
        tokenStore: MemoryTokenStore(),
        oauthClient: BungieOAuthClient(
          clientId: clientId,
          redirectUri: redirectUri,
          transport: (_) async => throw StateError('unused'),
        ),
        browserLauncher: FakeBrowserLauncher(),
        waitForCallbackOverride: () async {
          throw TimeoutException('OAuth loopback callback timed out');
        },
      );
      await session.signIn();
      expect(
        session.errorMessage,
        'Sign-in timed out waiting for Bungie. Please try again.',
      );
      expect(session.errorMessage, isNot(contains('timed out after')));
    });

    test('(a) token exchange HTTP failure maps to friendly exchange text',
        () async {
      String? capturedState;
      final browser = FakeBrowserLauncher();
      final session = WindowsOAuthSession(
        clientId: clientId,
        redirectUri: redirectUri,
        tokenStore: MemoryTokenStore(),
        oauthClient: BungieOAuthClient(
          clientId: clientId,
          redirectUri: redirectUri,
          transport: (_) async => const BungieHttpResponse(
            statusCode: 500,
            body: '{"error":"server_error","error_description":"SECRET-body"}',
          ),
        ),
        browserLauncher: browser,
        waitForCallbackOverride: () async {
          capturedState =
              Uri.parse(browser.opened.single).queryParameters['state'];
          return LoopbackCallbackResult(
            code: 'auth-code',
            state: capturedState,
          );
        },
      );
      await session.signIn();
      expect(
        session.errorMessage,
        'Could not complete sign-in with Bungie. Please try again.',
      );
      expect(session.errorMessage, isNot(contains('SECRET')));
      expect(session.errorMessage, isNot(contains('server_error')));
    });

    test('(a) network unreachable maps to friendly network text', () async {
      final session = WindowsOAuthSession(
        clientId: clientId,
        redirectUri: redirectUri,
        tokenStore: MemoryTokenStore(),
        oauthClient: BungieOAuthClient(
          clientId: clientId,
          redirectUri: redirectUri,
          transport: (_) async => throw StateError('unused'),
        ),
        browserLauncher: FakeBrowserLauncher(),
        waitForCallbackOverride: () async {
          throw const SocketException('Network is unreachable');
        },
      );
      await session.signIn();
      expect(
        session.errorMessage,
        'Network unavailable. Check your connection and try again.',
      );
      expect(session.errorMessage, isNot(contains('unreachable')));
    });

    test('(a) unknown failure uses fixed text (no type/raw leak)', () async {
      // CHANGED: previously included (${e.runtimeType}); now fixed copy only.
      const leaked = 'access-token-SECRET-ui-leak-xyz';
      final session = WindowsOAuthSession(
        clientId: clientId,
        redirectUri: redirectUri,
        tokenStore: MemoryTokenStore(),
        oauthClient: BungieOAuthClient(
          clientId: clientId,
          redirectUri: redirectUri,
          transport: (_) async => throw StateError('unused'),
        ),
        browserLauncher: FakeBrowserLauncher(),
        waitForCallbackOverride: () async {
          throw Exception(leaked);
        },
      );
      await session.signIn();
      expect(session.errorMessage, isNot(contains('SECRET')));
      expect(session.errorMessage, isNot(contains(leaked)));
      expect(session.errorMessage, isNot(contains('Exception')));
      expect(session.errorMessage, 'Sign-in failed - please try again.');
    });

    test(
      '(b) verified sign-in deletes leftover plaintext sidecar',
      () async {
        final dir = await Directory.systemTemp.createTemp('oauth_signin_side_');
        addTearDown(() async {
          if (await dir.exists()) await dir.delete(recursive: true);
        });
        final primary = _MemoryPrimary();
        final secondary = FileTokenStore(baseDir: dir.path);
        final now = DateTime.now().toUtc();
        await secondary.write(
          BungieTokens(
            accessToken: 'old-sidecar-SECRET',
            refreshToken: 'old-sidecar-ref-SECRET',
            expiresAt: now.add(const Duration(hours: 1)),
            refreshExpiresAt: now.add(const Duration(days: 1)),
            bungieMembershipId: 'old-memb',
          ),
        );
        final sidecar = File(p.join(dir.path, kBungieTokenFileName));
        expect(await sidecar.exists(), isTrue);

        final dual = DualTokenStore(primary: primary, secondary: secondary);
        final browser = FakeBrowserLauncher();
        String? capturedState;
        final session = WindowsOAuthSession(
          clientId: clientId,
          redirectUri: redirectUri,
          tokenStore: dual,
          oauthClient: BungieOAuthClient(
            clientId: clientId,
            redirectUri: redirectUri,
            transport: (_) async => BungieHttpResponse(
              statusCode: 200,
              body: jsonEncode(rawTokenResponse()),
            ),
          ),
          browserLauncher: browser,
          waitForCallbackOverride: () async {
            capturedState =
                Uri.parse(browser.opened.single).queryParameters['state'];
            return LoopbackCallbackResult(
              code: 'auth-code-xyz',
              state: capturedState,
            );
          },
        );

        await session.signIn();
        expect(session.isSignedIn, isTrue);
        expect((await primary.read())?.accessToken, 'acc-secret-111');
        expect(await sidecar.exists(), isFalse);
      },
    );

    test(
      '(1) failed Locker read-back during sign-in keeps plaintext sidecar',
      () async {
        final dir = await Directory.systemTemp.createTemp('oauth_rb_fail_');
        addTearDown(() async {
          if (await dir.exists()) await dir.delete(recursive: true);
        });
        final primary = _WriteOkNullReadPrimary();
        final secondary = FileTokenStore(baseDir: dir.path);
        final now = DateTime.now().toUtc();
        await secondary.write(
          BungieTokens(
            accessToken: 'sidecar-keep-SECRET',
            refreshToken: 'sidecar-keep-ref-SECRET',
            expiresAt: now.add(const Duration(hours: 1)),
            refreshExpiresAt: now.add(const Duration(days: 1)),
            bungieMembershipId: 'sidecar-memb',
          ),
        );
        final sidecar = File(p.join(dir.path, kBungieTokenFileName));
        expect(await sidecar.exists(), isTrue);

        final dual = DualTokenStore(primary: primary, secondary: secondary);
        final browser = FakeBrowserLauncher();
        String? capturedState;
        final session = WindowsOAuthSession(
          clientId: clientId,
          redirectUri: redirectUri,
          tokenStore: dual,
          oauthClient: BungieOAuthClient(
            clientId: clientId,
            redirectUri: redirectUri,
            transport: (_) async => BungieHttpResponse(
              statusCode: 200,
              body: jsonEncode(rawTokenResponse()),
            ),
          ),
          browserLauncher: browser,
          waitForCallbackOverride: () async {
            capturedState =
                Uri.parse(browser.opened.single).queryParameters['state'];
            return LoopbackCallbackResult(
              code: 'auth-code-xyz',
              state: capturedState,
            );
          },
        );

        await session.signIn();
        expect(session.isSignedIn, isFalse);
        expect(primary.deleteSidecarCalls, 0);
        expect(await sidecar.exists(), isTrue);
        expect(
          (await secondary.read())?.accessToken,
          'sidecar-keep-SECRET',
        );
        // Verify used secure-only read (not DualTokenStore.read migration).
        expect(primary.readSecureOnlyCalls, greaterThanOrEqualTo(1));
      },
    );

    test(
      '(2) failed re-sign-in does not clearSecureOnly a good Locker session',
      () async {
        final store = _CountingMemoryStore();
        final now = DateTime.now().toUtc();
        final good = BungieTokens(
          accessToken: 'good-access-SECRET',
          refreshToken: 'good-refresh-SECRET',
          expiresAt: now.add(const Duration(hours: 1)),
          refreshExpiresAt: now.add(const Duration(days: 1)),
          bungieMembershipId: 'good-memb',
        );
        await store.write(good);

        final session = WindowsOAuthSession(
          clientId: clientId,
          redirectUri: redirectUri,
          tokenStore: store,
          oauthClient: BungieOAuthClient(
            clientId: clientId,
            redirectUri: redirectUri,
            transport: (_) async => throw StateError('unused'),
          ),
          browserLauncher: FakeBrowserLauncher(),
          waitForCallbackOverride: () async =>
              const LoopbackCallbackResult(error: 'access_denied'),
        );
        await session.restore();
        expect(session.isSignedIn, isTrue);
        expect(store.clearSecureOnlyCalls, 0);

        await session.signIn();
        expect(store.clearSecureOnlyCalls, 0);
        expect((await store.read())?.accessToken, 'good-access-SECRET');
        expect(session.isSignedIn, isTrue);
        expect(session.tokens?.accessToken, 'good-access-SECRET');
      },
    );

    test(
      '(5) re-sign-in verify fail rolls Locker back to prior good session',
      () async {
        final store = _VerifyFailAfterWriteStore();
        final now = DateTime.now().toUtc();
        final good = BungieTokens(
          accessToken: 'prior-good-access-SECRET',
          refreshToken: 'prior-good-refresh-SECRET',
          expiresAt: now.add(const Duration(hours: 1)),
          refreshExpiresAt: now.add(const Duration(days: 1)),
          bungieMembershipId: 'prior-memb',
        );
        await store.write(good);

        final browser = FakeBrowserLauncher();
        String? capturedState;
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
                access: 'new-bad-access-SECRET',
                refresh: 'new-bad-refresh-SECRET',
                membershipId: 'new-memb',
              )),
            ),
          ),
          browserLauncher: browser,
          waitForCallbackOverride: () async {
            capturedState =
                Uri.parse(browser.opened.single).queryParameters['state'];
            return LoopbackCallbackResult(
              code: 'auth-code-xyz',
              state: capturedState,
            );
          },
        );
        await session.restore();
        expect(session.isSignedIn, isTrue);

        await session.signIn();
        expect(session.isSignedIn, isTrue);
        expect(session.tokens?.accessToken, 'prior-good-access-SECRET');
        expect(
          (await store.read())?.accessToken,
          'prior-good-access-SECRET',
        );
        expect(
          (await store.readSecureOnly())?.accessToken,
          'prior-good-access-SECRET',
        );
        expect(session.tokens?.accessToken, isNot(contains('new-bad')));
      },
    );

    test(
      '(2) cancel after callback aborts exchange/write',
      () async {
        final store = MemoryTokenStore();
        final browser = FakeBrowserLauncher();
        final exchangeStarted = Completer<void>();
        final exchangeRelease = Completer<BungieHttpResponse>();
        String? capturedState;

        final session = WindowsOAuthSession(
          clientId: clientId,
          redirectUri: redirectUri,
          tokenStore: store,
          oauthClient: BungieOAuthClient(
            clientId: clientId,
            redirectUri: redirectUri,
            transport: (_) async {
              if (!exchangeStarted.isCompleted) {
                exchangeStarted.complete();
              }
              return exchangeRelease.future;
            },
          ),
          browserLauncher: browser,
          waitForCallbackOverride: () async {
            capturedState =
                Uri.parse(browser.opened.single).queryParameters['state'];
            return LoopbackCallbackResult(
              code: 'auth-code-late',
              state: capturedState,
            );
          },
        );

        final signInFuture = session.signIn();
        await exchangeStarted.future;
        expect(session.status, OAuthSessionStatus.signingIn);

        await session.cancelSignIn();
        exchangeRelease.complete(
          BungieHttpResponse(
            statusCode: 200,
            body: jsonEncode(rawTokenResponse(
              access: 'should-not-store-SECRET',
              refresh: 'should-not-store-ref-SECRET',
            )),
          ),
        );
        await signInFuture;

        expect(session.isSignedIn, isFalse);
        expect(await store.read(), isNull);
        expect(session.lastSignInFailureKind, OAuthSignInFailureKind.cancelled);
      },
    );

    test(
      '(3) second signIn is blocked until first finally runs',
      () async {
        final waits = <Completer<LoopbackCallbackResult>>[];
        Completer<LoopbackCallbackResult> nextWait() {
          final c = Completer<LoopbackCallbackResult>();
          waits.add(c);
          return c;
        }

        final browser = FakeBrowserLauncher();
        final session = WindowsOAuthSession(
          clientId: clientId,
          redirectUri: redirectUri,
          tokenStore: MemoryTokenStore(),
          oauthClient: BungieOAuthClient(
            clientId: clientId,
            redirectUri: redirectUri,
            transport: (_) async => BungieHttpResponse(
              statusCode: 200,
              body: jsonEncode(rawTokenResponse()),
            ),
          ),
          browserLauncher: browser,
          waitForCallbackOverride: () => nextWait().future,
        );

        final first = session.signIn();
        await Future<void>.delayed(Duration.zero);
        expect(session.status, OAuthSessionStatus.signingIn);

        // Overlapping call must no-op while first is busy.
        await session.signIn();
        expect(browser.opened, hasLength(1));
        expect(waits, hasLength(1));

        await session.cancelSignIn();
        await first;
        expect(session.status, OAuthSessionStatus.signedOut);

        // After finally, a new sign-in may start.
        final second = session.signIn();
        await Future<void>.delayed(Duration.zero);
        expect(session.status, OAuthSessionStatus.signingIn);
        expect(browser.opened, hasLength(2));
        expect(waits, hasLength(2));
        await session.cancelSignIn();
        await second;
      },
    );

    test(
      '(4) non-bungie authorize URL is refused before browser open',
      () async {
        final browser = FakeBrowserLauncher();
        final session = WindowsOAuthSession(
          clientId: clientId,
          redirectUri: redirectUri,
          tokenStore: MemoryTokenStore(),
          oauthClient: BungieOAuthClient(
            clientId: clientId,
            redirectUri: redirectUri,
            authorizeBaseUrl: Uri.parse('https://evil.example/oauth'),
            transport: (_) async => throw StateError('unused'),
          ),
          browserLauncher: browser,
          waitForCallbackOverride: () async =>
              const LoopbackCallbackResult(code: 'x', state: 'y'),
        );

        await session.signIn();
        expect(browser.opened, isEmpty);
        expect(
          session.lastSignInFailureKind,
          OAuthSignInFailureKind.unsafeAuthorizeUrl,
        );
        expect(session.errorMessage, kUnsafeAuthorizeUrlMessage);
        expect(session.errorMessage, isNot(contains('evil')));
      },
    );

    test('(4) isAllowedBungieAuthorizeUrl allowlist', () {
      expect(
        isAllowedBungieAuthorizeUrl(
          'https://www.bungie.net/en/oauth/authorize?client_id=1',
        ),
        isTrue,
      );
      expect(
        isAllowedBungieAuthorizeUrl('http://www.bungie.net/en/oauth/authorize'),
        isFalse,
      );
      expect(
        isAllowedBungieAuthorizeUrl(
          'https://evil.example/en/oauth/authorize',
        ),
        isFalse,
      );
      expect(
        isAllowedBungieAuthorizeUrl(
          'https://www.bungie.net.evil.example/x',
        ),
        isFalse,
      );
      expect(
        isAllowedBungieAuthorizeUrl(
          'https://user@www.bungie.net/en/oauth/authorize',
        ),
        isFalse,
      );
    });

    test(
      '(3) sign-in verify uses readSecureOnly (no DualTokenStore migration)',
      () async {
        final dir = await Directory.systemTemp.createTemp('oauth_sec_only_');
        addTearDown(() async {
          if (await dir.exists()) await dir.delete(recursive: true);
        });
        // Primary write is a no-op; DualTokenStore.read() would migrate sidecar.
        final primary = _WriteOkNullReadPrimary();
        final secondary = FileTokenStore(baseDir: dir.path);
        final now = DateTime.now().toUtc();
        await secondary.write(
          BungieTokens(
            accessToken: 'migrate-bait-SECRET',
            refreshToken: 'migrate-bait-ref-SECRET',
            expiresAt: now.add(const Duration(hours: 1)),
            refreshExpiresAt: now.add(const Duration(days: 1)),
            bungieMembershipId: 'migrate-bait',
          ),
        );
        final sidecar = File(p.join(dir.path, kBungieTokenFileName));
        final dual = DualTokenStore(primary: primary, secondary: secondary);
        final browser = FakeBrowserLauncher();
        String? capturedState;
        final session = WindowsOAuthSession(
          clientId: clientId,
          redirectUri: redirectUri,
          tokenStore: dual,
          oauthClient: BungieOAuthClient(
            clientId: clientId,
            redirectUri: redirectUri,
            transport: (_) async => BungieHttpResponse(
              statusCode: 200,
              body: jsonEncode(rawTokenResponse()),
            ),
          ),
          browserLauncher: browser,
          waitForCallbackOverride: () async {
            capturedState =
                Uri.parse(browser.opened.single).queryParameters['state'];
            return LoopbackCallbackResult(
              code: 'auth-code-xyz',
              state: capturedState,
            );
          },
        );

        await session.signIn();
        expect(session.isSignedIn, isFalse);
        expect(primary.readSecureOnlyCalls, greaterThanOrEqualTo(1));
        // Migration via DualTokenStore.read() would have deleted the sidecar.
        expect(await sidecar.exists(), isTrue);
        expect(
          (await secondary.read())?.accessToken,
          'migrate-bait-SECRET',
        );
      },
    );

    test(
      '(4) missing authorization code maps to fixed missing-code wording',
      () async {
        final session = WindowsOAuthSession(
          clientId: clientId,
          redirectUri: redirectUri,
          tokenStore: MemoryTokenStore(),
          oauthClient: BungieOAuthClient(
            clientId: clientId,
            redirectUri: redirectUri,
            transport: (_) async => throw StateError('unused'),
          ),
          browserLauncher: FakeBrowserLauncher(),
          waitForCallbackOverride: () async =>
              const LoopbackCallbackResult(state: 'some-state'),
        );
        await session.signIn();
        expect(session.isSignedIn, isFalse);
        expect(
          session.lastSignInFailureKind,
          OAuthSignInFailureKind.missingAuthorizationCode,
        );
        expect(
          session.errorMessage,
          "Bungie didn't send a sign-in code - try again.",
        );
        expect(session.errorMessage, isNot(contains('Exception')));
      },
    );

    test(
      '(c) loopback.stop() throw after verified write does not clear Locker',
      () async {
        final store = MemoryTokenStore();
        final browser = FakeBrowserLauncher();
        String? capturedState;
        final loopback = FakeLoopbackCallbackServer(
          stopThrows: true,
          onWait: () async {
            capturedState =
                Uri.parse(browser.opened.single).queryParameters['state'];
            return LoopbackCallbackResult(
              code: 'auth-code-xyz',
              state: capturedState,
            );
          },
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
              body: jsonEncode(rawTokenResponse()),
            ),
          ),
          browserLauncher: browser,
          loopbackServer: loopback,
        );

        await session.signIn();
        expect(loopback.stopCalled, isTrue);
        expect(session.isSignedIn, isTrue);
        expect(session.status, OAuthSessionStatus.signedIn);
        expect((await store.read())?.accessToken, 'acc-secret-111');
      },
    );

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

    test('corrupt secure store restores as signed out with safe message',
        () async {
      final store = _CorruptThrowingStore();
      final session = WindowsOAuthSession(
        clientId: clientId,
        redirectUri: redirectUri,
        tokenStore: store,
        oauthClient: BungieOAuthClient(
          clientId: clientId,
          redirectUri: redirectUri,
          transport: (_) async => throw StateError('unused'),
        ),
        browserLauncher: FakeBrowserLauncher(),
      );

      await session.restore();
      expect(session.isSignedIn, isFalse);
      expect(session.status, OAuthSessionStatus.signedOut);
      expect(
        session.errorMessage,
        'Sign-in data could not be read - please sign in again',
      );
      expect(session.errorMessage, isNot(contains('SECRET')));
      // Skeptic fix 2: corrupt path clears Locker only.
      expect(store.clearedSecureOnly, isTrue);
      expect(store.cleared, isFalse);
    });

    test(
      '(2) corrupt Locker on restore leaves the sidecar file in place',
      () async {
        final dir = await Directory.systemTemp.createTemp('oauth_corrupt_side_');
        addTearDown(() async {
          if (await dir.exists()) await dir.delete(recursive: true);
        });

        final primary = _CorruptRawPrimary('{not-valid-json}');
        final secondary = FileTokenStore(baseDir: dir.path);
        final now = DateTime.now().toUtc();
        await secondary.write(
          BungieTokens(
            accessToken: 'sidecar-acc-SECRET',
            refreshToken: 'sidecar-ref-SECRET',
            expiresAt: now.add(const Duration(hours: 1)),
            refreshExpiresAt: now.add(const Duration(days: 1)),
            bungieMembershipId: 'mem-sidecar',
          ),
        );
        final sidecar = File(p.join(dir.path, kBungieTokenFileName));
        expect(await sidecar.exists(), isTrue);

        final dual = DualTokenStore(primary: primary, secondary: secondary);
        final session = WindowsOAuthSession(
          clientId: clientId,
          redirectUri: redirectUri,
          tokenStore: dual,
          oauthClient: BungieOAuthClient(
            clientId: clientId,
            redirectUri: redirectUri,
            transport: (_) async => throw StateError('unused'),
          ),
          browserLauncher: FakeBrowserLauncher(),
        );

        await session.restore();
        expect(session.isSignedIn, isFalse);
        expect(session.status, OAuthSessionStatus.signedOut);
        expect(
          session.errorMessage,
          'Sign-in data could not be read - please sign in again',
        );
        expect(primary.clearSecureOnlyCalls, 1);
        expect(primary.clearCalls, 0);
        expect(primary.raw, isNull);
        expect(await sidecar.exists(), isTrue);
        expect((await secondary.read())?.accessToken, 'sidecar-acc-SECRET');
      },
    );

    test(
      'explicit signOut deletes DualTokenStore sidecar file',
      () async {
        final dir = await Directory.systemTemp.createTemp('oauth_signout_side_');
        addTearDown(() async {
          if (await dir.exists()) await dir.delete(recursive: true);
        });

        final primary = _MemoryPrimary();
        final secondary = FileTokenStore(baseDir: dir.path);
        final now = DateTime.now().toUtc();
        final tokens = BungieTokens(
          accessToken: 'signout-acc-SECRET',
          refreshToken: 'signout-ref-SECRET',
          expiresAt: now.add(const Duration(hours: 1)),
          refreshExpiresAt: now.add(const Duration(days: 1)),
          bungieMembershipId: 'mem-signout',
        );
        await primary.write(tokens);
        await secondary.write(tokens);
        final sidecar = File(p.join(dir.path, kBungieTokenFileName));
        expect(await sidecar.exists(), isTrue);

        final dual = DualTokenStore(primary: primary, secondary: secondary);
        final session = WindowsOAuthSession(
          clientId: clientId,
          redirectUri: redirectUri,
          tokenStore: dual,
          oauthClient: BungieOAuthClient(
            clientId: clientId,
            redirectUri: redirectUri,
            transport: (_) async => throw StateError('unused'),
          ),
          browserLauncher: FakeBrowserLauncher(),
        );
        await session.restore();
        expect(session.isSignedIn, isTrue);

        await session.signOut();
        expect(session.isSignedIn, isFalse);
        expect(await primary.read(), isNull);
        expect(await sidecar.exists(), isFalse);
      },
    );

    test(
      'failed migration then second restore migrates cleanly',
      () async {
        final dir = await Directory.systemTemp.createTemp('oauth_mig_chain_');
        addTearDown(() async {
          if (await dir.exists()) await dir.delete(recursive: true);
        });

        final primary = _FailOnceThenOkPrimary();
        final secondary = FileTokenStore(baseDir: dir.path);
        final now = DateTime.now().toUtc();
        final tokens = BungieTokens(
          accessToken: 'chain-acc-SECRET',
          refreshToken: 'chain-ref-SECRET',
          expiresAt: now.add(const Duration(hours: 1)),
          refreshExpiresAt: now.add(const Duration(days: 1)),
          bungieMembershipId: 'mem-chain',
        );
        await secondary.write(tokens);
        final sidecar = File(p.join(dir.path, kBungieTokenFileName));
        expect(await sidecar.exists(), isTrue);

        final dual = DualTokenStore(primary: primary, secondary: secondary);
        final session = WindowsOAuthSession(
          clientId: clientId,
          redirectUri: redirectUri,
          tokenStore: dual,
          oauthClient: BungieOAuthClient(
            clientId: clientId,
            redirectUri: redirectUri,
            transport: (_) async => throw StateError('unused'),
          ),
          browserLauncher: FakeBrowserLauncher(),
        );

        await session.restore();
        expect(session.isSignedIn, isFalse);
        expect(await sidecar.exists(), isTrue);
        expect(primary.writeCount, 1);
        expect(await primary.read(), isNull);

        await session.restore();
        expect(session.isSignedIn, isTrue);
        expect(session.membershipId, 'mem-chain');
        expect((await primary.read())?.accessToken, 'chain-acc-SECRET');
        expect(await sidecar.exists(), isFalse);
      },
    );

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

  group('LoopbackCallbackServer peer filter (5)', () {
    test('isIpv4LoopbackPeer accepts only 127.0.0.1', () {
      expect(isIpv4LoopbackPeer(InternetAddress('127.0.0.1')), isTrue);
      expect(isIpv4LoopbackPeer(InternetAddress.loopbackIPv4), isTrue);
      // localhost can resolve to IPv6 — reject ::1.
      expect(isIpv4LoopbackPeer(InternetAddress.loopbackIPv6), isFalse);
      expect(isIpv4LoopbackPeer(InternetAddress('::1')), isFalse);
      expect(isIpv4LoopbackPeer(InternetAddress('8.8.8.8')), isFalse);
      expect(isIpv4LoopbackPeer(null), isFalse);
    });

    test('registered Windows redirect URI uses 127.0.0.1 not localhost', () {
      // Prod matrix must stay on 127.0.0.1 — do not widen to localhost.
      final p = parseLoopbackRedirectUri(kDefaultWindowsRedirectUri);
      expect(p.host, '127.0.0.1');
      expect(kDefaultWindowsRedirectUri, isNot(contains('localhost')));
    });
  });
}
