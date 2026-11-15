import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/loopback_callback_server.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/auth/windows_oauth_session.dart';
import 'package:destiny2_windows_host/builds_mock/apply_sign_in_dialog.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_apply.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_controller.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_page.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
import 'package:destiny2_windows_host/theme/flap_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'inventory_sync_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApplySignInDialog states', () {
    testWidgets('signed-out prompt renders exact mockup copy', (tester) async {
      final session = _buildSession();
      await session.restore();

      await _openDialog(tester, session: session);
      expect(find.byKey(const Key('apply_sign_in_dialog')), findsOneWidget);
      expect(find.byKey(const Key('apply_sign_in_prompt')), findsOneWidget);
      expect(find.text(kApplySignInTitle), findsOneWidget);
      expect(find.text(kApplySignInBody), findsOneWidget);
      expect(find.text(kApplySignInOpenButton), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text(kApplySignInPermissionsHeading), findsOneWidget);
      expect(find.text('· Read profile'), findsOneWidget);
      expect(find.text('· Read inventory and vault'), findsOneWidget);
      expect(find.text('· Move and equip items'), findsOneWidget);

      await tester.tap(find.byKey(const Key('apply_sign_in_cancel')));
      await tester.pumpAndSettle();
    });

    testWidgets('waiting renders spinner copy and copy-link', (tester) async {
      final wait = Completer<LoopbackCallbackResult>();
      final browser = FakeBrowserLauncher();
      final session = _buildSession(
        browser: browser,
        wait: () => wait.future,
      );
      await session.restore();

      await _openDialog(tester, session: session);

      await tester.tap(find.byKey(const Key('apply_sign_in_open')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.byKey(const Key('apply_sign_in_waiting')), findsOneWidget);
      expect(find.text(kApplySignInWaitingBody), findsOneWidget);
      expect(find.text(kApplySignInCopyLink), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(browser.opened, isNotEmpty);

      await tester.tap(find.byKey(const Key('apply_sign_in_cancel')));
      await tester.pumpAndSettle();
    });

    testWidgets('Cancel during waiting stops flow and closes listener',
        (tester) async {
      final wait = Completer<LoopbackCallbackResult>();
      var loopbackStopped = false;
      final loopback = _RecordingLoopback(
        onStop: () => loopbackStopped = true,
      );
      final session = _buildSession(
        wait: () => wait.future,
        loopback: loopback,
      );
      await session.restore();

      await _openDialog(tester, session: session);

      await tester.tap(find.byKey(const Key('apply_sign_in_open')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byKey(const Key('apply_sign_in_waiting')), findsOneWidget);

      await tester.tap(find.byKey(const Key('apply_sign_in_cancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('apply_sign_in_dialog')), findsNothing);
      expect(session.status, OAuthSessionStatus.signedOut);
      expect(session.isSignedIn, isFalse);
      expect(loopbackStopped, isTrue);
    });

    testWidgets('Copy link copies authorize URL without token/secret material',
        (tester) async {
      final wait = Completer<LoopbackCallbackResult>();
      final browser = FakeBrowserLauncher();
      final copied = <String>[];
      final session = _buildSession(
        browser: browser,
        wait: () => wait.future,
      );
      await session.restore();

      await _openDialog(
        tester,
        session: session,
        clipboardWriter: (text) async => copied.add(text),
      );

      await tester.tap(find.byKey(const Key('apply_sign_in_open')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(session.pendingAuthorizeUrl, isNotNull);
      await tester.tap(find.byKey(const Key('apply_sign_in_copy_link')));
      await tester.pump();

      expect(copied, hasLength(1));
      final url = copied.single.toLowerCase();
      expect(url, contains('client_id'));
      expect(url, contains('state'));
      expect(url, contains('code_challenge'));
      expect(url, contains('redirect'));
      expect(url, isNot(contains('access_token')));
      expect(url, isNot(contains('refresh_token')));
      expect(url, isNot(contains('secret')));
      expect(url, equals(browser.opened.single.toLowerCase()));

      await tester.tap(find.byKey(const Key('apply_sign_in_cancel')));
      await tester.pumpAndSettle();
    });

    testWidgets('success shows name and auto-continues after 1s (fake async)',
        (tester) async {
      final browser = FakeBrowserLauncher();
      late String capturedState;
      final session = WindowsOAuthSession(
        clientId: 'test-client',
        redirectUri: 'http://127.0.0.1:8765/callback',
        tokenStore: MemoryTokenStore(),
        oauthClient: BungieOAuthClient(
          clientId: 'test-client',
          redirectUri: 'http://127.0.0.1:8765/callback',
          transport: (request) async {
            return BungieHttpResponse(
              statusCode: 200,
              body: jsonEncode({
                'access_token': 'acc',
                'token_type': 'Bearer',
                'expires_in': 3600,
                'refresh_token': 'ref',
                'refresh_expires_in': 7776000,
                'membership_id': 'M42',
              }),
            );
          },
        ),
        browserLauncher: browser,
        waitForCallbackOverride: () async {
          capturedState =
              Uri.parse(browser.opened.single).queryParameters['state']!;
          return LoopbackCallbackResult(
            code: 'auth-code',
            state: capturedState,
          );
        },
      );
      await session.restore();

      ApplySignInDialogResult? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: _theme(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  key: const Key('open_dialog'),
                  onPressed: () async {
                    result = await showApplySignInDialog(
                      context: context,
                      session: session,
                      bungieDisplayName: 'GuardianOne',
                      successContinueDelay: const Duration(seconds: 1),
                    );
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('open_dialog')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('apply_sign_in_open')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('apply_sign_in_success')), findsOneWidget);
      expect(find.text('Signed in as GuardianOne'), findsOneWidget);
      expect(result, isNull);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('apply_sign_in_dialog')), findsNothing);
      expect(result, ApplySignInDialogResult.signedIn);
      expect(session.isSignedIn, isTrue);
    });

    testWidgets('each error maps to fixed message; raw text never appears',
        (tester) async {
      // CHANGED: tokenExchangeFailed no longer shares the network message;
      // null/unknown uses its own fixed text (not the network copy).
      final cases = <OAuthSignInFailureKind, String>{
        OAuthSignInFailureKind.cancelled: kApplySignInCancelledMessage,
        OAuthSignInFailureKind.callbackTimeout: kApplySignInTimeoutMessage,
        OAuthSignInFailureKind.stateMismatch: kApplySignInStateMismatchMessage,
        OAuthSignInFailureKind.networkUnreachable: kApplySignInNetworkMessage,
        OAuthSignInFailureKind.tokenExchangeFailed: kApplySignInExchangeMessage,
        OAuthSignInFailureKind.missingAuthorizationCode:
            kApplySignInMissingCodeMessage,
        OAuthSignInFailureKind.unsafeAuthorizeUrl: kApplySignInUnsafeUrlMessage,
      };

      for (final entry in cases.entries) {
        final kind = entry.key;
        final expected = entry.value;
        final rawLeak = 'RAW_EXCEPTION_SHOULD_NEVER_SHOW_${kind.name}';

        final session = _sessionThatFails(kind, rawLeak: rawLeak);
        await session.restore();

        await _openDialog(tester, session: session);

        await tester.tap(find.byKey(const Key('apply_sign_in_open')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byKey(const Key('apply_sign_in_error')), findsOneWidget);
        expect(find.text(kApplySignInTitle), findsOneWidget);
        expect(find.text(expected), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        expect(find.textContaining(rawLeak), findsNothing);
        expect(find.textContaining('Exception'), findsNothing);
        expect(find.textContaining('access_token'), findsNothing);
        if (kind != OAuthSignInFailureKind.networkUnreachable) {
          expect(find.text(kApplySignInNetworkMessage), findsNothing);
        }

        await tester.tap(find.byKey(const Key('apply_sign_in_try_again')));
        await tester.pump();
        expect(find.byKey(const Key('apply_sign_in_prompt')), findsOneWidget);
        await tester.tap(find.byKey(const Key('apply_sign_in_cancel')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('apply_sign_in_dialog')), findsNothing);
      }
    });

    test('applySignInDialogErrorMessage null uses unknown fixed text', () {
      expect(
        applySignInDialogErrorMessage(null),
        kApplySignInUnknownMessage,
      );
      expect(
        applySignInDialogErrorMessage(null),
        isNot(kApplySignInNetworkMessage),
      );
    });

    testWidgets(
        '(1) Escape/barrier dismiss while waiting calls cancelSignIn',
        (tester) async {
      final wait = Completer<LoopbackCallbackResult>();
      var loopbackStopped = false;
      final loopback = _RecordingLoopback(
        onStop: () => loopbackStopped = true,
      );
      final session = _buildSession(
        wait: () => wait.future,
        loopback: loopback,
      );
      await session.restore();

      ApplySignInDialogResult? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: _theme(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  key: const Key('open_dialog'),
                  onPressed: () async {
                    result = await showApplySignInDialog(
                      context: context,
                      session: session,
                    );
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('open_dialog')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('apply_sign_in_open')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byKey(const Key('apply_sign_in_waiting')), findsOneWidget);
      expect(session.status, OAuthSessionStatus.signingIn);

      // Barrier tap (outside dialog) dismisses and must cancel sign-in.
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('apply_sign_in_dialog')), findsNothing);
      expect(result, ApplySignInDialogResult.cancelled);
      expect(session.status, OAuthSessionStatus.signedOut);
      expect(loopbackStopped, isTrue);
    });

    testWidgets(
        '(7) body says equip only; permissions still list move and equip',
        (tester) async {
      final session = _buildSession();
      await session.restore();
      await _openDialog(tester, session: session);

      expect(
        find.text(
          'Apply needs your permission to equip items. '
          "Bungie's sign-in opens in your browser.",
        ),
        findsOneWidget,
      );
      expect(find.textContaining('move and equip items'), findsNothing);
      expect(find.text('· Move and equip items'), findsOneWidget);

      await tester.tap(find.byKey(const Key('apply_sign_in_cancel')));
      await tester.pumpAndSettle();
    });
  });

  group('Apply button gate', () {
    testWidgets('already signed-in skips the dialog and keeps Apply enabled',
        (tester) async {
      final tokenStore = MemoryTokenStore();
      await seedSignedIn(tokenStore);
      final session = WindowsOAuthSession(
        clientId: 'test-client',
        redirectUri: kDefaultWindowsRedirectUri,
        tokenStore: tokenStore,
        oauthClient: BungieOAuthClient(
          clientId: 'test-client',
          redirectUri: kDefaultWindowsRedirectUri,
          transport: (_) async => throw StateError('unused'),
        ),
        browserLauncher: FakeBrowserLauncher(),
      );
      await session.restore();
      expect(session.isSignedIn, isTrue);

      final profile = FakeProfileClient(
        characters: const [
          CharacterSummary(
            characterId: 'char-warlock-4821',
            classType: 'Warlock',
            light: 2010,
          ),
        ],
      );

      await tester.binding.setSurfaceSize(const Size(1440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: _theme(),
          home: Scaffold(
            body: BuildsMockPage(
              controller: BuildsMockController(),
              applyPorts: BuildsMockApplyPorts(
                oauthSession: session,
                profileClient: profile,
                writeClient: createMockWriteClient(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byKey(const Key('builds_mock_card_b01')).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final apply = tester.widget<FilledButton>(
        find.byKey(const Key('builds_mock_apply_character_b01')),
      );
      expect(apply.onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('builds_mock_apply_character_b01')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('apply_sign_in_dialog')), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('signed-out Apply opens sign-in dialog', (tester) async {
      final session = WindowsOAuthSession(
        clientId: 'test-client',
        redirectUri: kDefaultWindowsRedirectUri,
        tokenStore: MemoryTokenStore(),
        oauthClient: BungieOAuthClient(
          clientId: 'test-client',
          redirectUri: kDefaultWindowsRedirectUri,
          transport: (_) async => throw StateError('unused'),
        ),
        browserLauncher: FakeBrowserLauncher(),
        waitForCallbackOverride: () =>
            Completer<LoopbackCallbackResult>().future,
      );
      await session.restore();

      await tester.binding.setSurfaceSize(const Size(1440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: _theme(),
          home: Scaffold(
            body: BuildsMockPage(
              controller: BuildsMockController(),
              applyPorts: BuildsMockApplyPorts(
                oauthSession: session,
                profileClient: FakeProfileClient(),
                writeClient: createMockWriteClient(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byKey(const Key('builds_mock_card_b01')).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final apply = tester.widget<FilledButton>(
        find.byKey(const Key('builds_mock_apply_character_b01')),
      );
      expect(apply.onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('builds_mock_apply_character_b01')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('apply_sign_in_dialog')), findsOneWidget);
      expect(find.text(kApplySignInTitle), findsOneWidget);
      expect(find.text(kApplySignInOpenButton), findsOneWidget);

      await tester.tap(find.byKey(const Key('apply_sign_in_cancel')));
      await tester.pumpAndSettle();
    });
  });
}

ThemeData _theme() => buildFlapTheme(brightness: Brightness.light).copyWith(
      splashFactory: NoSplash.splashFactory,
    );

Future<void> _openDialog(
  WidgetTester tester, {
  required WindowsOAuthSession session,
  ApplySignInClipboardWriter? clipboardWriter,
  String? bungieDisplayName,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: _theme(),
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: TextButton(
              key: const Key('open_dialog'),
              onPressed: () {
                showApplySignInDialog(
                  context: context,
                  session: session,
                  clipboardWriter: clipboardWriter,
                  bungieDisplayName: bungieDisplayName,
                );
              },
              child: const Text('Open'),
            ),
          );
        },
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.byKey(const Key('open_dialog')));
  await tester.pumpAndSettle();
}

WindowsOAuthSession _buildSession({
  FakeBrowserLauncher? browser,
  Future<LoopbackCallbackResult> Function()? wait,
  LoopbackCallbackServer? loopback,
}) {
  return WindowsOAuthSession(
    clientId: 'test-client',
    redirectUri: 'http://127.0.0.1:8765/callback',
    tokenStore: MemoryTokenStore(),
    oauthClient: BungieOAuthClient(
      clientId: 'test-client',
      redirectUri: 'http://127.0.0.1:8765/callback',
      transport: (request) async {
        return BungieHttpResponse(
          statusCode: 200,
          body: jsonEncode({
            'access_token': 'acc',
            'token_type': 'Bearer',
            'expires_in': 3600,
            'refresh_token': 'ref',
            'refresh_expires_in': 7776000,
            'membership_id': 'M123',
          }),
        );
      },
    ),
    browserLauncher: browser ?? FakeBrowserLauncher(),
    loopbackServer: loopback,
    waitForCallbackOverride: wait,
  );
}

WindowsOAuthSession _sessionThatFails(
  OAuthSignInFailureKind kind, {
  required String rawLeak,
}) {
  if (kind == OAuthSignInFailureKind.unsafeAuthorizeUrl) {
    return WindowsOAuthSession(
      clientId: 'test-client',
      redirectUri: 'http://127.0.0.1:8765/callback',
      tokenStore: MemoryTokenStore(),
      oauthClient: BungieOAuthClient(
        clientId: 'test-client',
        redirectUri: 'http://127.0.0.1:8765/callback',
        authorizeBaseUrl: Uri.parse('https://evil.example/oauth'),
        transport: (_) async => throw StateError(rawLeak),
      ),
      browserLauncher: FakeBrowserLauncher(),
      waitForCallbackOverride: () async =>
          const LoopbackCallbackResult(code: 'x', state: 'y'),
    );
  }
  return WindowsOAuthSession(
    clientId: 'test-client',
    redirectUri: 'http://127.0.0.1:8765/callback',
    tokenStore: MemoryTokenStore(),
    oauthClient: BungieOAuthClient(
      clientId: 'test-client',
      redirectUri: 'http://127.0.0.1:8765/callback',
      transport: (_) async => throw StateError(rawLeak),
    ),
    browserLauncher: FakeBrowserLauncher(),
    waitForCallbackOverride: () async {
      switch (kind) {
        case OAuthSignInFailureKind.cancelled:
          return const LoopbackCallbackResult(error: 'access_denied');
        case OAuthSignInFailureKind.callbackTimeout:
          throw TimeoutException(rawLeak);
        case OAuthSignInFailureKind.stateMismatch:
          return const LoopbackCallbackResult(
            code: 'code',
            state: 'wrong-state',
          );
        case OAuthSignInFailureKind.networkUnreachable:
          throw SocketException(rawLeak);
        case OAuthSignInFailureKind.tokenExchangeFailed:
          return const LoopbackCallbackResult(error: 'server_error');
        case OAuthSignInFailureKind.missingAuthorizationCode:
          return const LoopbackCallbackResult(state: 'state-only');
        case OAuthSignInFailureKind.unsafeAuthorizeUrl:
          throw StateError(rawLeak);
      }
    },
  );
}

class _RecordingLoopback extends LoopbackCallbackServer {
  _RecordingLoopback({required this.onStop});

  final void Function() onStop;

  @override
  Future<void> stop() async {
    onStop();
    await super.stop();
  }
}
