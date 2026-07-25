import 'dart:async';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:test/test.dart';

class _FakeProfileClient implements BungieProfileClient {
  _FakeProfileClient({
    this.memberships = const [
      DestinyMembership(
        membershipType: 3,
        membershipId: 'destiny-mem-111',
        displayName: 'Guardian',
      ),
    ],
    List<RawInventoryItem>? items,
    this.onInventory,
  }) : items = items ?? _defaultItems;

  List<DestinyMembership> memberships;
  List<RawInventoryItem> items;
  void Function()? onInventory;
  int inventoryCalls = 0;
  int membershipCalls = 0;

  static final _defaultItems = <RawInventoryItem>[
    const RawInventoryItem(
      instanceId: 'inst1',
      itemHash: 123,
      bucketHash: 1498876634,
      location: 'vault',
      power: 1800,
      plugHashes: [9],
      isMasterwork: false,
      isCrafted: false,
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
    return const [];
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
    onInventory?.call();
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

void main() {
  late AppDatabase db;
  late InventoryBusyLock lock;

  setUp(() {
    db = AppDatabase.memory();
    lock = InventoryBusyLock();
    defaultInventoryBusyLock.clearForTests();
  });

  tearDown(() async {
    defaultInventoryBusyLock.clearForTests();
    await db.close();
  });

  const now = '2026-07-24T12:00:00.000Z';

  Future<int> seedUser({
    String membershipId = 'bungie-net-id',
    int membershipType = 0,
    String displayName = '',
  }) {
    return insertUser(
      db,
      bungieMembershipId: membershipId,
      membershipType: membershipType,
      displayName: displayName,
    );
  }

  group('syncUserInventory', () {
    test('full-replace writes items and bumps syncVersion', () async {
      final userId = await seedUser();
      final client = _FakeProfileClient();

      final result = await syncUserInventory(
        db: db,
        userId: userId,
        accessToken: 'token',
        profileClient: client,
        now: now,
        lock: lock,
      );

      expect(client.membershipCalls, 1);
      expect(client.inventoryCalls, 1);
      expect(result.itemCount, 1);
      expect(result.syncVersion, 1);
      expect(result.lastFullSyncAt, now);

      final listed = await listInventoryItems(db, userId);
      expect(listed, hasLength(1));
      expect(listed.single.instanceId, 'inst1');
      expect(listed.single.bucket, 'Kinetic');
      expect(listed.single.power, 1800);

      final status = await getInventoryStatus(db, userId);
      expect(status?.syncVersion, 1);
      expect(status?.itemCount, 1);

      final user = await getUser(db, userId);
      expect(user?.membershipType, 3);
      expect(user?.displayName, 'Guardian');
    });

    test('second sync replaces orphans and increments version', () async {
      final userId = await seedUser();
      final client = _FakeProfileClient();

      await syncUserInventory(
        db: db,
        userId: userId,
        accessToken: 't',
        profileClient: client,
        now: now,
        lock: lock,
      );

      client.items = [
        const RawInventoryItem(
          instanceId: 'inst2',
          itemHash: 999,
          bucketHash: 2465295065,
          location: 'character',
          characterId: 'c1',
          power: 1810,
          isCrafted: true,
        ),
      ];

      final result = await syncUserInventory(
        db: db,
        userId: userId,
        accessToken: 't',
        profileClient: client,
        now: '2026-07-24T13:00:00.000Z',
        lock: lock,
      );

      expect(result.syncVersion, 2);
      expect(result.itemCount, 1);
      final listed = await listInventoryItems(db, userId);
      expect(listed.single.instanceId, 'inst2');
      expect(listed.single.bucket, 'Energy');
      expect(listed.single.rollTags, ['Crafted']);
    });

    test('throws when no Destiny memberships', () async {
      final userId = await seedUser();
      final client = _FakeProfileClient(memberships: const []);

      await expectLater(
        syncUserInventory(
          db: db,
          userId: userId,
          accessToken: 't',
          profileClient: client,
          now: now,
          lock: lock,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('No Destiny memberships'),
          ),
        ),
      );
      expect(client.inventoryCalls, 0);
      expect(await listInventoryItems(db, userId), isEmpty);
    });

    test('concurrent sync throws SyncInProgressError', () async {
      final userId = await seedUser();
      final started = Completer<void>();
      final release = Completer<void>();
      final client = _FakeProfileClient(
        onInventory: () {
          if (!started.isCompleted) started.complete();
        },
      );

      // Hold lock manually to simulate in-flight exclusive sync.
      final first = lock.runExclusive(userId, () async {
        await release.future;
        return 'held';
      });

      await expectLater(
        syncUserInventory(
          db: db,
          userId: userId,
          accessToken: 't',
          profileClient: client,
          now: now,
          lock: lock,
        ),
        throwsA(isA<SyncInProgressError>()),
      );

      release.complete();
      await first;
      expect(client.inventoryCalls, 0);
    });

    test('empty inventory still bumps version', () async {
      final userId = await seedUser();
      final client = _FakeProfileClient(items: const []);

      final result = await syncUserInventory(
        db: db,
        userId: userId,
        accessToken: 't',
        profileClient: client,
        now: now,
        lock: lock,
      );

      expect(result.itemCount, 0);
      expect(result.syncVersion, 1);
      expect(await listInventoryItems(db, userId), isEmpty);
    });

    test('resolves transfer containers with lookup', () async {
      final userId = await seedUser();
      final client = _FakeProfileClient(
        items: const [
          RawInventoryItem(
            instanceId: 'vault-gun',
            itemHash: 555,
            bucketHash: 138197802,
            location: 'vault',
            power: 1800,
          ),
        ],
      );

      final without = await syncUserInventory(
        db: db,
        userId: userId,
        accessToken: 't',
        profileClient: client,
        now: now,
        lock: lock,
      );
      expect(without.itemCount, 0);
      expect(without.diagnostics.resolution?.resolvedFromTransfer, 0);
      expect(without.diagnostics.resolution?.droppedNonEquipment, 1);

      final withLookup = await syncUserInventory(
        db: db,
        userId: userId,
        accessToken: 't',
        profileClient: client,
        equipmentBucketLookup: {555: 1498876634},
        now: '2026-07-24T14:00:00.000Z',
        lock: lock,
      );
      expect(withLookup.itemCount, 1);
      expect(withLookup.diagnostics.resolution?.resolvedFromTransfer, greaterThan(0));
      expect(withLookup.diagnostics.resolution?.resolvedFromTransfer, 1);
      final listed = await listInventoryItems(db, userId);
      expect(listed.single.bucket, 'Kinetic');
      expect(listed.single.location, 'vault');
    });

    test('lookup builder resolves vault using DestinyInventoryItemDefinition',
        () async {
      final userId = await seedUser();
      final client = _FakeProfileClient(
        items: const [
          RawInventoryItem(
            instanceId: 'vault-gun',
            itemHash: 777,
            bucketHash: 138197802,
            location: 'vault',
            power: 1800,
          ),
          RawInventoryItem(
            instanceId: 'post-helm',
            itemHash: 888,
            bucketHash: 215593132,
            location: 'character',
            characterId: 'c1',
            power: 1700,
          ),
        ],
      );

      final table = <String, dynamic>{
        '777': {
          'hash': 777,
          'inventory': {'bucketTypeHash': 1498876634},
        },
        '888': {
          'hash': 888,
          'inventory': {'bucketTypeHash': 3448274439},
        },
      };

      final result = await syncUserInventory(
        db: db,
        userId: userId,
        accessToken: 't',
        profileClient: client,
        equipmentBucketLookupBuilder: (hashes) async {
          expect(hashes, containsAll([777, 888]));
          return buildEquipmentBucketLookup(table, hashes);
        },
        now: now,
        lock: lock,
      );

      expect(result.itemCount, 2);
      expect(result.diagnostics.resolution?.resolvedFromTransfer, 2);
      final listed = await listInventoryItems(db, userId);
      expect(
        listed.map((e) => e.bucket).toSet(),
        {'Kinetic', 'Helmet'},
      );
      expect(
        listed.where((e) => e.location == 'vault').single.bucket,
        'Kinetic',
      );
    });

    test('DART-051: stores MeleeBuildCandidate when perk map + weapon meta provided',
        () async {
      final userId = await seedUser();
      final client = _FakeProfileClient(
        items: const [
          RawInventoryItem(
            instanceId: 'hc-melee',
            itemHash: 100,
            bucketHash: 1498876634,
            location: 'vault',
            power: 1800,
            plugHashes: [1, 2],
          ),
        ],
      );

      await syncUserInventory(
        db: db,
        userId: userId,
        accessToken: 't',
        profileClient: client,
        perkNameMap: const {
          1: 'Pugilist',
          2: 'Swashbuckler',
        },
        weaponRollMetaLookup: const {
          100: RollTagWeaponMeta(
            frame: 'Adaptive Frame',
            itemTypeName: 'Hand Cannon',
          ),
        },
        now: now,
        lock: lock,
      );

      final listed = await listInventoryItems(db, userId);
      expect(listed.single.rollTags, contains(RollTags.meleeBuildCandidate));
      expect(listed.single.rollTags, contains(RollTags.championBarrier));
    });

    test('DART-051: stores ChampionBarrier from weapon frame meta', () async {
      final userId = await seedUser();
      final client = _FakeProfileClient(
        items: const [
          RawInventoryItem(
            instanceId: 'scout',
            itemHash: 200,
            bucketHash: 1498876634,
            location: 'character',
            characterId: 'c1',
            power: 1810,
          ),
        ],
      );

      await syncUserInventory(
        db: db,
        userId: userId,
        accessToken: 't',
        profileClient: client,
        weaponRollMetaLookup: const {
          200: RollTagWeaponMeta(
            frame: 'Adaptive Frame',
            itemTypeName: 'Scout Rifle',
          ),
        },
        now: now,
        lock: lock,
      );

      final listed = await listInventoryItems(db, userId);
      expect(listed.single.rollTags, contains(RollTags.championBarrier));
    });

    test('DART-051: perk name builder enriches OrbitBuild', () async {
      final userId = await seedUser();
      final client = _FakeProfileClient(
        items: const [
          RawInventoryItem(
            instanceId: 'orbit-gun',
            itemHash: 300,
            bucketHash: 2465295065,
            location: 'vault',
            power: 1800,
            plugHashes: [3, 4],
          ),
        ],
      );

      await syncUserInventory(
        db: db,
        userId: userId,
        accessToken: 't',
        profileClient: client,
        perkNameMapBuilder: (plugs) async {
          expect(plugs, containsAll([3, 4]));
          return {3: 'Demolitionist', 4: 'Adrenaline Junkie'};
        },
        now: now,
        lock: lock,
      );

      final listed = await listInventoryItems(db, userId);
      expect(listed.single.rollTags, contains(RollTags.orbitBuild));
    });

    test('DART-051: empty enrichment maps yield no invented tags', () async {
      final userId = await seedUser();
      final client = _FakeProfileClient(
        items: const [
          RawInventoryItem(
            instanceId: 'plain',
            itemHash: 400,
            bucketHash: 1498876634,
            location: 'vault',
            power: 1800,
            plugHashes: [1, 2],
          ),
        ],
      );

      await syncUserInventory(
        db: db,
        userId: userId,
        accessToken: 't',
        profileClient: client,
        now: now,
        lock: lock,
      );

      final listed = await listInventoryItems(db, userId);
      expect(listed.single.rollTags, isEmpty);
    });

    test(
        'DART-052: stores socket plugs with columnKind/columnLabel when context provided',
        () async {
      final userId = await seedUser();
      final client = _FakeProfileClient(
        items: const [
          RawInventoryItem(
            instanceId: 'perk-gun',
            itemHash: 500,
            bucketHash: 1498876634,
            location: 'character',
            characterId: 'c1',
            power: 1810,
            plugHashes: [101, 201, 301],
            socketCapture: [
              RawSocketCapture(
                socketIndex: 0,
                equippedPlugHash: 101,
                reusablePlugHashes: [101, 102],
              ),
              RawSocketCapture(
                socketIndex: 1,
                equippedPlugHash: 201,
                reusablePlugHashes: [201],
              ),
              RawSocketCapture(
                socketIndex: 2,
                equippedPlugHash: 301,
                reusablePlugHashes: [301],
              ),
              RawSocketCapture(
                socketIndex: 9,
                equippedPlugHash: 901,
                reusablePlugHashes: [],
              ),
            ],
          ),
        ],
      );

      await syncUserInventory(
        db: db,
        userId: userId,
        accessToken: 't',
        profileClient: client,
        weaponSocketContextBuilder: (itemHash, plugHashes) async {
          expect(itemHash, 500);
          expect(plugHashes, containsAll([101, 201, 301, 901]));
          return const WeaponSocketContext(
            plugCategoryByHash: {
              101: 'barrels.rifle',
              201: 'magazines.ar',
              301: 'traits.weapon',
              901: 'shader',
            },
            weaponPerkSocketIndexes: [0, 1, 2, 3],
          );
        },
        now: now,
        lock: lock,
      );

      final listed = await listInventoryItems(db, userId);
      final plugs = listed.single.socketPlugs;
      expect(plugs, isNotNull);
      expect(plugs, hasLength(3));
      expect(plugs![0]['columnKind'], 'barrel');
      expect(plugs[0]['columnLabel'], 'Barrel');
      expect(plugs[1]['columnKind'], 'magazine');
      expect(plugs[2]['columnKind'], 'trait');
      expect(plugs[2]['columnLabel'], 'Trait 1');
      expect(plugs.any((p) => p['equippedPlugHash'] == 901), isFalse);
    });

    test('DART-052: without context falls back to raw capture maps', () async {
      final userId = await seedUser();
      final client = _FakeProfileClient(
        items: const [
          RawInventoryItem(
            instanceId: 'raw-gun',
            itemHash: 600,
            bucketHash: 1498876634,
            location: 'vault',
            power: 1800,
            socketCapture: [
              RawSocketCapture(
                socketIndex: 0,
                equippedPlugHash: 101,
                reusablePlugHashes: [102],
              ),
            ],
          ),
        ],
      );

      await syncUserInventory(
        db: db,
        userId: userId,
        accessToken: 't',
        profileClient: client,
        now: now,
        lock: lock,
      );

      final listed = await listInventoryItems(db, userId);
      final plugs = listed.single.socketPlugs;
      expect(plugs, isNotNull);
      expect(plugs!.single['socketIndex'], 0);
      expect(plugs.single['equippedPlugHash'], 101);
      expect(plugs.single.containsKey('columnKind'), isFalse);
    });

    test('DART-052: non-weapon stores null socketPlugs', () async {
      final userId = await seedUser();
      final client = _FakeProfileClient(
        items: const [
          RawInventoryItem(
            instanceId: 'helm',
            itemHash: 700,
            bucketHash: 3448274439,
            location: 'character',
            characterId: 'c1',
            power: 1800,
          ),
        ],
      );

      await syncUserInventory(
        db: db,
        userId: userId,
        accessToken: 't',
        profileClient: client,
        now: now,
        lock: lock,
      );

      final listed = await listInventoryItems(db, userId);
      expect(listed.single.bucket, 'Helmet');
      expect(listed.single.socketPlugs, isNull);
    });

    test('DART-052: context builder from item defs enriches vault weapon',
        () async {
      final userId = await seedUser();
      final client = _FakeProfileClient(
        items: const [
          RawInventoryItem(
            instanceId: 'vault-perk',
            itemHash: 800,
            bucketHash: 138197802,
            location: 'vault',
            power: 1800,
            socketCapture: [
              RawSocketCapture(
                socketIndex: 0,
                equippedPlugHash: 101,
                reusablePlugHashes: [101],
              ),
            ],
          ),
        ],
      );

      final table = <String, dynamic>{
        '800': {
          'hash': 800,
          'inventory': {'bucketTypeHash': 1498876634},
          'sockets': {
            'socketCategories': [
              {
                'socketCategoryHash': kWeaponPerksCategoryHash,
                'socketIndexes': [0, 1, 2],
              },
            ],
          },
        },
        '101': {
          'hash': 101,
          'plug': {'plugCategoryIdentifier': 'barrels.rifle'},
        },
      };

      await syncUserInventory(
        db: db,
        userId: userId,
        accessToken: 't',
        profileClient: client,
        equipmentBucketLookup: const {800: 1498876634},
        weaponSocketContextBuilder: (itemHash, plugHashes) async {
          return buildWeaponSocketContextFromItemDefs(
            table,
            itemHash,
            plugHashes,
          );
        },
        now: now,
        lock: lock,
      );

      final listed = await listInventoryItems(db, userId);
      expect(listed.single.bucket, 'Kinetic');
      expect(listed.single.socketPlugs, isNotNull);
      expect(listed.single.socketPlugs!.single['columnKind'], 'barrel');
      expect(listed.single.socketPlugs!.single['columnLabel'], 'Barrel');
    });
  });
}
