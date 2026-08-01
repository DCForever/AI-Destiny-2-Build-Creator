import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_web_host/auth/token_store.dart';
import 'package:destiny2_web_host/auth/web_auth_navigator.dart';
import 'package:destiny2_web_host/auth/web_oauth_config.dart';
import 'package:destiny2_web_host/auth/web_oauth_session.dart';

/// Shared fakes for DART-056 inventory sync tests.
class FakeProfileClient implements BungieProfileClient {
  FakeProfileClient({
    List<DestinyMembership>? memberships,
    List<RawInventoryItem>? items,
    List<CharacterSummary>? characters,
    this.throwOnInventory = false,
  })  : memberships = memberships ??
            const [
              DestinyMembership(
                membershipType: 3,
                membershipId: 'destiny-1',
                displayName: 'Guardian',
              ),
            ],
        items = items ?? defaultItems,
        characters = characters ?? defaultCharacters;

  List<DestinyMembership> memberships;
  List<RawInventoryItem> items;
  List<CharacterSummary> characters;
  final bool throwOnInventory;
  int inventoryCalls = 0;
  int membershipCalls = 0;

  static final defaultItems = <RawInventoryItem>[
    const RawInventoryItem(
      instanceId: 'inst-a',
      itemHash: 100,
      bucketHash: 1498876634, // kinetic
      location: 'vault',
      power: 1800,
      plugHashes: [1],
    ),
    const RawInventoryItem(
      instanceId: 'inst-b',
      itemHash: 200,
      bucketHash: 2465295065, // energy
      location: 'character',
      characterId: 'char1',
      power: 1810,
    ),
  ];

  static const defaultCharacters = <CharacterSummary>[
    CharacterSummary(
      characterId: 'char-hunter',
      classType: 'Hunter',
      light: 1810,
      dateLastPlayed: '2026-07-24T12:00:00Z',
    ),
  ];

  @override
  Future<List<DestinyMembership>> getMemberships(String accessToken) async {
    membershipCalls += 1;
    return memberships;
  }

  @override
  Future<List<CharacterSummary>> getCharacters(
    String accessToken,
    DestinyMembership membership,
  ) async {
    return characters;
  }

  @override
  Future<Object?> getCharacterLoadoutsProfile(
    String accessToken,
    DestinyMembership membership,
  ) async {
    return {
      'characterLoadouts': {
        'data': {
          for (final c in characters)
            c.characterId: {'loadouts': <Object>[]},
        },
      },
    };
  }

  @override
  Future<List<RawInventoryItem>> getFullInventory(
    String accessToken,
    DestinyMembership membership,
  ) async {
    final r = await getFullInventoryWithDiagnostics(accessToken, membership);
    return r.items;
  }

  @override
  Future<FullInventoryParseResult> getFullInventoryWithDiagnostics(
    String accessToken,
    DestinyMembership membership,
  ) async {
    inventoryCalls += 1;
    if (throwOnInventory) {
      throw StateError('No Destiny memberships found');
    }
    final diagnostics = InventoryParseDiagnostics(
      membership: membership,
      raw: InventoryRawCounts(vault: items.length, total: items.length),
      parsed: InventoryParsedCounts(
        total: items.length,
        equipmentTotal: items.length,
      ),
      dropped: InventoryDroppedCounts(),
    );
    return FullInventoryParseResult(items: items, diagnostics: diagnostics);
  }
}

Future<void> seedSignedIn(
  TokenStore store, {
  String membershipId = 'bungie-net-99',
}) async {
  final now = DateTime.utc(2026, 7, 24, 12);
  await store.write(
    BungieTokens(
      accessToken: 'access-token-xyz',
      refreshToken: 'refresh-token-xyz',
      expiresAt: now.add(const Duration(hours: 1)),
      refreshExpiresAt: now.add(const Duration(days: 1)),
      bungieMembershipId: membershipId,
    ),
  );
}

WebOAuthSession buildSignedInSession({
  TokenStore? store,
}) {
  final tokenStore = store ?? MemoryTokenStore();
  return WebOAuthSession(
    config: const WebOAuthConfig(
      clientId: 'test-client',
      redirectUri: 'https://127.0.0.1:8080/auth/callback',
    ),
    tokenStore: tokenStore,
    oauthClient: BungieOAuthClient(
      clientId: 'test-client',
      redirectUri: 'https://127.0.0.1:8080/auth/callback',
      transport: (_) async => throw StateError('unused'),
    ),
    navigator: MemoryWebAuthNavigator(),
  );
}
