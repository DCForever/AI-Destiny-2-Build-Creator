import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_web_host/auth/token_store.dart';
import 'package:destiny2_web_host/auth/web_auth_navigator.dart';
import 'package:destiny2_web_host/auth/web_oauth_config.dart';
import 'package:destiny2_web_host/auth/web_oauth_session.dart';
import 'package:destiny2_web_host/components/oauth_account_card.dart';
import 'package:destiny2_web_host/pages/settings_page.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:test/test.dart';

WebOAuthSession _session({
  required String clientId,
  BungieTokens? tokens,
}) {
  final store = MemoryTokenStore();
  final session = WebOAuthSession(
    config: WebOAuthConfig(
      clientId: clientId,
      redirectUri: 'https://127.0.0.1:8080/auth/callback',
    ),
    tokenStore: store,
    oauthClient: BungieOAuthClient(
      clientId: clientId.isEmpty ? 'placeholder' : clientId,
      redirectUri: 'https://127.0.0.1:8080/auth/callback',
      transport: (_) async => const BungieHttpResponse(statusCode: 500, body: ''),
    ),
    navigator: MemoryWebAuthNavigator(),
  );
  return session;
}

void main() {
  group('OAuthAccountCard US3', () {
    testComponents('signed-out configured shows Sign in', (tester) async {
      final session = _session(clientId: 'cid');
      await session.restore();

      tester.pumpComponent(OAuthAccountCard(session: session));

      expect(find.text('Sign in'), findsOneComponent);
      expect(find.textContaining('Signed out'), findsOneComponent);
      // Tokens themselves must never render in UI.
      expect(find.textContaining('access_token'), findsNothing);
      expect(find.textContaining('refresh_token'), findsNothing);
    });

    testComponents('signed-in shows membership and Sign out', (tester) async {
      final store = MemoryTokenStore();
      final now = DateTime.utc(2026, 7, 25);
      await store.write(
        BungieTokens(
          accessToken: 'secret-access-should-not-render',
          refreshToken: 'secret-refresh-should-not-render',
          expiresAt: now.add(const Duration(hours: 1)),
          refreshExpiresAt: now.add(const Duration(days: 1)),
          bungieMembershipId: 'M123',
        ),
      );
      final session = WebOAuthSession(
        config: const WebOAuthConfig(
          clientId: 'cid',
          redirectUri: 'https://127.0.0.1:8080/auth/callback',
        ),
        tokenStore: store,
        oauthClient: BungieOAuthClient(
          clientId: 'cid',
          redirectUri: 'https://127.0.0.1:8080/auth/callback',
          transport: (_) async =>
              const BungieHttpResponse(statusCode: 500, body: ''),
        ),
        navigator: MemoryWebAuthNavigator(),
      );
      await session.restore();

      tester.pumpComponent(OAuthAccountCard(session: session));

      expect(find.text('Sign out'), findsOneComponent);
      expect(find.textContaining('M123'), findsOneComponent);
      expect(find.textContaining('secret-access'), findsNothing);
      expect(find.textContaining('secret-refresh'), findsNothing);
    });

    testComponents('missing client id shows config hint', (tester) async {
      final session = _session(clientId: '');
      await session.restore();
      tester.pumpComponent(OAuthAccountCard(session: session));

      expect(find.textContaining('Not configured'), findsOneComponent);
      expect(find.textContaining('BUNGIE_CLIENT_ID'), findsOneComponent);
    });
  });

  group('SettingsPage with OAuth', () {
    testComponents('renders account card when session provided', (tester) async {
      final session = _session(clientId: 'cid');
      await session.restore();
      tester.pumpComponent(
        SettingsPage(oauthSession: session),
      );

      expect(find.text(SettingsPage.titleText), findsOneComponent);
      expect(find.text('Sign in'), findsOneComponent);
      expect(find.textContaining('Public+PKCE'), findsComponents);
      expect(find.textContaining('No confidential client secret'), findsOneComponent);
    });
  });
}
