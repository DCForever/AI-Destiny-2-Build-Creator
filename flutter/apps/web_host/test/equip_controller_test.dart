import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart'
    hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_web_host/auth/pending_auth_store.dart';
import 'package:destiny2_web_host/auth/token_store.dart';
import 'package:destiny2_web_host/auth/web_auth_navigator.dart';
import 'package:destiny2_web_host/auth/web_oauth_config.dart';
import 'package:destiny2_web_host/auth/web_oauth_session.dart';
import 'package:destiny2_web_host/builds/builds_controller.dart';
import 'package:destiny2_web_host/equip/equip_controller.dart';
import 'package:test/test.dart';

class FakeProfileClient implements BungieProfileClient {
  FakeProfileClient({
    List<DestinyMembership>? memberships,
    List<CharacterSummary>? characters,
  })  : memberships = memberships ??
            const [
              DestinyMembership(
                membershipType: 3,
                membershipId: 'destiny-1',
                displayName: 'Guardian',
              ),
            ],
        characters = characters ??
            const [
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

  List<DestinyMembership> memberships;
  List<CharacterSummary> characters;
  int characterCalls = 0;

  @override
  Future<List<DestinyMembership>> getMemberships(String accessToken) async {
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
    return const [];
  }

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

BungieTokens _tokens() {
  final now = DateTime.utc(2026, 7, 25, 12);
  return BungieTokens(
    accessToken: 'at-test',
    refreshToken: 'rt-test',
    expiresAt: now.add(const Duration(hours: 1)),
    refreshExpiresAt: now.add(const Duration(days: 30)),
    bungieMembershipId: 'M-test',
  );
}

Future<WebOAuthSession> signedInSession() async {
  const config = WebOAuthConfig(
    clientId: 'public-client',
    redirectUri: 'https://127.0.0.1:8080/auth/callback',
  );
  final store = MemoryTokenStore();
  await store.write(_tokens());
  final session = WebOAuthSession(
    config: config,
    tokenStore: store,
    oauthClient: BungieOAuthClient(
      clientId: config.clientId,
      redirectUri: config.redirectUri,
      transport: (_) async => throw StateError('unused'),
    ),
    navigator: MemoryWebAuthNavigator(origin: 'https://127.0.0.1:8080'),
    pendingAuthStore: MemoryPendingAuthStore(),
  );
  await session.restore();
  return session;
}

Future<WebOAuthSession> signedOutSession() async {
  const config = WebOAuthConfig(
    clientId: 'public-client',
    redirectUri: 'https://127.0.0.1:8080/auth/callback',
  );
  final session = WebOAuthSession(
    config: config,
    tokenStore: MemoryTokenStore(),
    oauthClient: BungieOAuthClient(
      clientId: config.clientId,
      redirectUri: config.redirectUri,
      transport: (_) async => throw StateError('unused'),
    ),
    navigator: MemoryWebAuthNavigator(origin: 'https://127.0.0.1:8080'),
    pendingAuthStore: MemoryPendingAuthStore(),
  );
  await session.restore();
  return session;
}

void main() {
  late AppDatabase db;
  late BuildsController builds;
  late List<String> writeLog;
  late FakeProfileClient profile;

  setUp(() async {
    db = AppDatabase.memory();
    builds = BuildsController(db: db);
    writeLog = <String>[];
    profile = FakeProfileClient();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedWeaponSet(
    int userId,
    String setId,
    String slot,
    int hash, {
    String? instanceId,
  }) async {
    await createUserSet(
      db,
      userId,
      CreateSetCommand(id: setId, name: 'Set $setId', type: SetType.weapon),
    );
    await upsertUserSetItem(
      db,
      userId,
      setId,
      UpsertSetItemCommand(
        id: '$setId-item',
        slot: slot,
        itemHash: hash,
        itemName: 'Item $hash',
        instanceId: instanceId,
      ),
    );
    // Second domain slot for package min; reuse pin mode of [instanceId].
    final second = slot == 'special' ? 'heavy' : 'special';
    final secondInstance =
        instanceId == null ? null : '$instanceId-2';
    await upsertUserSetItem(
      db,
      userId,
      setId,
      UpsertSetItemCommand(
        id: '$setId-item-2',
        slot: second,
        itemHash: hash + 1000,
        itemName: 'Item ${hash + 1000}',
        instanceId: secondInstance,
      ),
    );
  }

  Future<void> seedInventory(
    int userId, {
    required String instanceId,
    required int itemHash,
    String location = 'vault',
    String? characterId,
  }) async {
    await replaceInventoryBatch(
      db,
      userId,
      items: [
        InventoryItemRecord(
          instanceId: instanceId,
          itemHash: itemHash,
          bucket: 'Kinetic',
          location: location,
          characterId: characterId,
          syncedAt: '2026-07-25T12:00:00.000Z',
        ),
      ],
      now: '2026-07-25T12:00:00.000Z',
    );
  }

  Future<({int userId, String buildId, String variantId})> seedCompose({
    String? instanceId,
  }) async {
    final uid = await builds.resolveLibraryUserId();
    await seedWeaponSet(
      uid,
      'set-eq',
      'primary',
      100,
      instanceId: instanceId,
    );
    await builds.createBuild(
      name: 'Equip Build',
      className: GuardianClass.hunter,
      synergyTypes: const [DraftSynergyType(type: 'melee')],
    );
    expect(await builds.createVariant(name: 'Alt'), isNull);
    expect(await builds.attachSet('set-eq'), isNull);
    return (
      userId: uid,
      buildId: builds.selected!.build.id,
      variantId: builds.selectedVariant!.id,
    );
  }

  Future<EquipController> makeEquip({
    required WebOAuthSession session,
  }) async {
    return EquipController(
      db: db,
      session: session,
      profileClient: profile,
      writeClient: createMockWriteClient(
        transferItem: (ctx, args) async {
          writeLog.add('transfer:${args.instanceId}');
        },
        equipItem: (ctx, args) async {
          writeLog.add('equip:${args.instanceId}');
        },
      ),
      skipSyncIfStale: true,
    );
  }

  test('US1 wishlist not equip-ready; Apply blocked', () async {
    final session = await signedInSession();
    final equip = await makeEquip(session: session);
    final seed = await seedCompose();

    await equip.bind(
      userId: seed.userId,
      buildId: seed.buildId,
      variantId: seed.variantId,
      buildClass: 'Hunter',
    );

    expect(equip.equipReady, isFalse);
    expect(equip.canApply, isFalse);
    equip.selectCharacter('char-hunter');
    expect(equip.canApply, isFalse);

    final err = await equip.requestEquip();
    expect(err, isNotNull);
    expect(err!.toLowerCase(), contains('equip-ready'));
    expect(writeLog, isEmpty);
    expect(equip.writeCalls, 0);
  });

  test('US1 signed out blocks equip', () async {
    final session = await signedOutSession();
    final equip = await makeEquip(session: session);
    final seed = await seedCompose(instanceId: 'inst-1');
    await replaceInventoryBatch(
      db,
      seed.userId,
      items: [
        InventoryItemRecord(
          instanceId: 'inst-1',
          itemHash: 100,
          bucket: 'Kinetic',
          location: 'vault',
          syncedAt: '2026-07-25T12:00:00.000Z',
        ),
        InventoryItemRecord(
          instanceId: 'inst-1-2',
          itemHash: 1100,
          bucket: 'Energy',
          location: 'vault',
          syncedAt: '2026-07-25T12:00:00.000Z',
        ),
      ],
      now: '2026-07-25T12:00:00.000Z',
    );

    await equip.bind(
      userId: seed.userId,
      buildId: seed.buildId,
      variantId: seed.variantId,
      buildClass: 'Hunter',
    );

    expect(equip.equipReady, isTrue);
    expect(equip.isSignedIn, isFalse);
    expect(equip.canApply, isFalse);

    final err = await equip.requestEquip();
    expect(err, contains('Sign in'));
    expect(writeLog, isEmpty);
  });

  test('US3 equip-ready + character runs mock write + step report', () async {
    final session = await signedInSession();
    final equip = await makeEquip(session: session);
    final seed = await seedCompose(instanceId: 'inst-1');
    await replaceInventoryBatch(
      db,
      seed.userId,
      items: [
        InventoryItemRecord(
          instanceId: 'inst-1',
          itemHash: 100,
          bucket: 'Kinetic',
          location: 'vault',
          syncedAt: '2026-07-25T12:00:00.000Z',
        ),
        InventoryItemRecord(
          instanceId: 'inst-1-2',
          itemHash: 1100,
          bucket: 'Energy',
          location: 'vault',
          syncedAt: '2026-07-25T12:00:00.000Z',
        ),
      ],
      now: '2026-07-25T12:00:00.000Z',
    );

    await equip.bind(
      userId: seed.userId,
      buildId: seed.buildId,
      variantId: seed.variantId,
      buildClass: 'Hunter',
    );

    expect(equip.equipReady, isTrue, reason: equip.error);
    expect(equip.matchingCharacters.map((c) => c.characterId),
        contains('char-hunter'));
    equip.selectCharacter('char-hunter');
    expect(equip.canApply, isTrue);

    // Empty combat slots remain → gaps confirm first
    final pending = await equip.requestEquip();
    expect(pending, isNull);
    expect(equip.pendingGaps, isNotNull);
    expect(writeLog, isEmpty);

    equip.cancelGapsConfirm();
    expect(equip.pendingGaps, isNull);
    expect(writeLog, isEmpty);

    final withForce = await equip.requestEquip(forceGapsConfirm: true);
    expect(withForce, isNull, reason: equip.error);
    expect(equip.writeCalls, 1);
    expect(writeLog, isNotEmpty);
    expect(equip.lastStatus, isNotNull);
    expect(equip.statusMessage, contains('Completed'));
  });

  test('hard block when not equip-ready does not call write', () async {
    final session = await signedInSession();
    final equip = await makeEquip(session: session);
    final seed = await seedCompose(); // wishlist

    await equip.bind(
      userId: seed.userId,
      buildId: seed.buildId,
      variantId: seed.variantId,
      buildClass: 'Hunter',
    );
    equip.selectCharacter('char-hunter');

    final err = await equip.requestEquip(forceGapsConfirm: true);
    expect(err, isNotNull);
    expect(writeLog, isEmpty);
    expect(equip.writeCalls, 0);
  });
}
