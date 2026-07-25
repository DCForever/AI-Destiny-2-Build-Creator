import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/auth/windows_oauth_session.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';

/// Shared fakes for DART-025 inventory sync tests (no `main`).
class FakeProfileClient implements BungieProfileClient {
  FakeProfileClient({
    List<DestinyMembership>? memberships,
    List<RawInventoryItem>? items,
    List<CharacterSummary>? characters,
    this.throwOnInventory = false,
    this.inventoryDelay,
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
  final Duration? inventoryDelay;
  int inventoryCalls = 0;
  int membershipCalls = 0;
  int characterCalls = 0;

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
    CharacterSummary(
      characterId: 'char-titan',
      classType: 'Titan',
      light: 1820,
      dateLastPlayed: '2026-07-23T12:00:00Z',
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
    characterCalls += 1;
    return characters;
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
    if (inventoryDelay != null) {
      await Future<void>.delayed(inventoryDelay!);
    }
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

WindowsOAuthSession buildSignedInSession({
  String membershipId = 'bungie-net-99',
  TokenStore? store,
}) {
  final tokenStore = store ?? MemoryTokenStore();
  return WindowsOAuthSession(
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
