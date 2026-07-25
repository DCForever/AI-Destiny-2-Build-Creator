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
  });
}
