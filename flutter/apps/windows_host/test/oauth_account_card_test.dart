import 'dart:convert';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/loopback_callback_server.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/auth/windows_oauth_session.dart';
import 'package:destiny2_windows_host/settings/oauth_account_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_material_theme.dart';

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

WindowsOAuthSession buildSession({
  String clientId = 'cid',
  TokenStore? store,
  Future<LoopbackCallbackResult> Function()? wait,
}) {
  return WindowsOAuthSession(
    clientId: clientId,
    redirectUri: 'http://127.0.0.1:8765/callback',
    tokenStore: store ?? MemoryTokenStore(),
    oauthClient: BungieOAuthClient(
      clientId: clientId.isEmpty ? 'placeholder' : clientId,
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
    browserLauncher: FakeBrowserLauncher(),
    waitForCallbackOverride: wait,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signed-out shows Sign in', (tester) async {
    final session = buildSession();
    await session.restore();

    await tester.pumpWidget(
      MaterialApp(theme: testMaterialTheme(), home: Scaffold(body: OAuthAccountCard(session: session))),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('oauth_account_card')), findsOneWidget);
    expect(find.byKey(const Key('oauth_sign_in')), findsOneWidget);
    expect(find.byKey(const Key('oauth_sign_out')), findsNothing);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('signed-in shows membership and Sign out', (tester) async {
    final store = MemoryTokenStore();
    // Relative to wall clock: restore() uses DateTime.now for expiry checks.
    final now = DateTime.now().toUtc();
    await store.write(
      BungieTokens(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAt: now.add(const Duration(hours: 1)),
        refreshExpiresAt: now.add(const Duration(days: 1)),
        bungieMembershipId: 'M123',
      ),
    );
    final session = buildSession(store: store);
    await session.restore();

    await tester.pumpWidget(
      MaterialApp(theme: testMaterialTheme(), home: Scaffold(body: OAuthAccountCard(session: session))),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('oauth_membership_id')), findsOneWidget);
    expect(find.textContaining('M123'), findsOneWidget);
    expect(find.byKey(const Key('oauth_sign_out')), findsOneWidget);

    await tester.tap(find.byKey(const Key('oauth_sign_out')));
    await _pumpFrames(tester);

    expect(session.isSignedIn, isFalse);
    expect(find.byKey(const Key('oauth_sign_in')), findsOneWidget);
    expect(await store.read(), isNull);
  });

  testWidgets('missing client id disables Sign in and shows hint',
      (tester) async {
    final session = buildSession(clientId: '');
    await session.restore();

    await tester.pumpWidget(
      MaterialApp(theme: testMaterialTheme(), home: Scaffold(body: OAuthAccountCard(session: session))),
    );
    await _pumpFrames(tester);

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('oauth_sign_in')),
    );
    expect(button.onPressed, isNull);
    expect(find.byKey(const Key('oauth_config_hint')), findsOneWidget);
  });

  testWidgets('sign-in success updates card', (tester) async {
    String? state;
    final browser = FakeBrowserLauncher();
    final store = MemoryTokenStore();
    final session = WindowsOAuthSession(
      clientId: 'cid',
      redirectUri: 'http://127.0.0.1:8765/callback',
      tokenStore: store,
      oauthClient: BungieOAuthClient(
        clientId: 'cid',
        redirectUri: 'http://127.0.0.1:8765/callback',
        transport: (_) async => BungieHttpResponse(
          statusCode: 200,
          body: jsonEncode({
            'access_token': 'acc',
            'token_type': 'Bearer',
            'expires_in': 3600,
            'refresh_token': 'ref',
            'refresh_expires_in': 7776000,
            'membership_id': 'M999',
          }),
        ),
      ),
      browserLauncher: browser,
      waitForCallbackOverride: () async {
        final uri = Uri.parse(browser.opened.single);
        state = uri.queryParameters['state'];
        return LoopbackCallbackResult(code: 'c', state: state);
      },
    );
    await session.restore();

    await tester.pumpWidget(
      MaterialApp(theme: testMaterialTheme(), home: Scaffold(body: OAuthAccountCard(session: session))),
    );
    await _pumpFrames(tester);

    await tester.tap(find.byKey(const Key('oauth_sign_in')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await _pumpFrames(tester);

    expect(session.isSignedIn, isTrue);
    expect(find.textContaining('M999'), findsOneWidget);
    expect(find.byKey(const Key('oauth_sign_out')), findsOneWidget);
  });
}
