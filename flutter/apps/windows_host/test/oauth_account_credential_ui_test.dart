import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/client_credential_store.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/auth/windows_oauth_session.dart';
import 'package:destiny2_windows_host/settings/oauth_account_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_material_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('advanced section has credential field, save, and forget',
      (tester) async {
    final creds = MemoryClientCredentialStore();
    final session = WindowsOAuthSession(
      clientId: 'cid',
      redirectUri: 'https://127.0.0.1:8765/callback',
      tokenStore: MemoryTokenStore(),
      credentialStore: creds,
      oauthClient: BungieOAuthClient(
        clientId: 'cid',
        redirectUri: 'https://127.0.0.1:8765/callback',
        transport: (_) async => throw StateError('unused'),
      ),
      browserLauncher: FakeBrowserLauncher(),
    );
    await session.restore();

    await tester.pumpWidget(
      MaterialApp(
        theme: testMaterialTheme(),
        home: Scaffold(body: OAuthAccountCard(session: session)),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('oauth_advanced_toggle')));
    await tester.pump();

    expect(find.byKey(const Key('oauth_client_credential_field')), findsOneWidget);
    expect(find.byKey(const Key('oauth_save_client_credential')), findsOneWidget);
    expect(find.byKey(const Key('oauth_forget_client_credential')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('oauth_client_credential_field')),
      'FAKE-BUNGIE-APP-CREDENTIAL-ui-test',
    );
    await tester.tap(find.byKey(const Key('oauth_save_client_credential')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(await creds.hasCredential, isTrue);
    expect(session.isConfidentialMode, isTrue);
    expect(find.text('Confidential mode: on'), findsOneWidget);

    await tester.tap(find.byKey(const Key('oauth_forget_client_credential')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(await creds.hasCredential, isFalse);
    expect(session.isConfidentialMode, isFalse);
  });
}
