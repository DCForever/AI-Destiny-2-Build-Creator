import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_web_host/auth/pending_auth_store.dart';
import 'package:destiny2_web_host/auth/token_store.dart';
import 'package:destiny2_web_host/auth/web_auth_navigator.dart';
import 'package:destiny2_web_host/auth/web_oauth_config.dart';
import 'package:destiny2_web_host/auth/web_oauth_session.dart';
import 'package:destiny2_web_host/loadouts/loadouts_controller.dart';
import 'package:destiny2_web_host/loadouts/loadouts_page.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:test/test.dart';

class _FakeProfile implements BungieProfileClient {
  _FakeProfile({this.profile});

  Object? profile;

  @override
  Future<List<DestinyMembership>> getMemberships(String accessToken) async {
    return const [
      DestinyMembership(
        membershipType: 3,
        membershipId: 'destiny-1',
        displayName: 'Guardian',
      ),
    ];
  }

  @override
  Future<List<CharacterSummary>> getCharacters(
    String accessToken,
    DestinyMembership membership,
  ) async {
    return const [
      CharacterSummary(
        characterId: 'char-titan',
        classType: 'Titan',
        light: 1820,
      ),
    ];
  }

  @override
  Future<Object?> getCharacterLoadoutsProfile(
    String accessToken,
    DestinyMembership membership,
  ) async {
    return profile ??
        {
          'characters': {
            'data': {
              'char-titan': {
                'characterId': 'char-titan',
                'classType': 0,
                'light': 1820,
                'dateLastPlayed': '2026-07-23T12:00:00Z',
              },
            },
          },
          'characterLoadouts': {
            'data': {
              'char-titan': {
                'loadouts': [
                  {
                    'iconHash': 0,
                    'colorHash': 0,
                    'nameHash': 0,
                    'items': [
                      {'itemInstanceId': '999'},
                    ],
                  },
                  {
                    'iconHash': 0,
                    'colorHash': 0,
                    'nameHash': 0,
                    'items': <Object>[],
                  },
                ],
              },
            },
          },
        };
  }

  @override
  Future<List<RawInventoryItem>> getFullInventory(
    String accessToken,
    DestinyMembership membership,
  ) async =>
      const [];

  @override
  Future<FullInventoryParseResult> getFullInventoryWithDiagnostics(
    String accessToken,
    DestinyMembership membership,
  ) async {
    return FullInventoryParseResult(
      items: const [],
      diagnostics: InventoryParseDiagnostics(
        membership: membership,
        raw: InventoryRawCounts(),
        parsed: InventoryParsedCounts(),
        dropped: InventoryDroppedCounts(),
      ),
    );
  }
}

Future<WebOAuthSession> _session({required bool signedIn}) async {
  final store = MemoryTokenStore();
  if (signedIn) {
    final now = DateTime.utc(2026, 7, 25, 12);
    await store.write(
      BungieTokens(
        accessToken: 'at-test',
        refreshToken: 'rt-test',
        expiresAt: now.add(const Duration(hours: 1)),
        refreshExpiresAt: now.add(const Duration(days: 1)),
        bungieMembershipId: 'bungie-1',
      ),
    );
  }
  final session = WebOAuthSession(
    config: const WebOAuthConfig(
      clientId: 'test-client',
      redirectUri: 'https://127.0.0.1:8080/auth/callback',
    ),
    tokenStore: store,
    oauthClient: BungieOAuthClient(
      clientId: 'test-client',
      redirectUri: 'https://127.0.0.1:8080/auth/callback',
      transport: (_) async => throw StateError('unused'),
    ),
    navigator: MemoryWebAuthNavigator(
      currentUri: Uri.parse('https://127.0.0.1:8080/loadouts'),
    ),
    pendingAuthStore: MemoryPendingAuthStore(),
  );
  await session.restore();
  return session;
}

void main() {
  group('LoadoutsPage', () {
    testComponents('blocked state without controller', (tester) async {
      tester.pumpComponent(const LoadoutsPage());
      expect(find.text(LoadoutsPage.titleText), findsOneComponent);
    });

    testComponents('signed-out gate', (tester) async {
      final session = await _session(signedIn: false);
      final controller = LoadoutsController(
        session: session,
        profileClient: _FakeProfile(),
      );
      tester.pumpComponent(LoadoutsPage(controller: controller));
      await pumpEventQueue();
      expect(find.text(LoadoutsPage.signedOutText), findsOneComponent);
    });

    testComponents('lists non-empty loadouts', (tester) async {
      final session = await _session(signedIn: true);
      final controller = LoadoutsController(
        session: session,
        profileClient: _FakeProfile(),
      );
      tester.pumpComponent(LoadoutsPage(controller: controller));
      await pumpEventQueue();
      await pumpEventQueue();
      expect(find.text('Loadout 1'), findsOneComponent);
      // empty hidden by default
      expect(find.text('Loadout 2'), findsNothing);
    });
  });
}
