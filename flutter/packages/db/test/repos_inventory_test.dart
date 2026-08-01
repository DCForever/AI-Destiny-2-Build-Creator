import 'dart:async';

import 'package:destiny2_db/destiny2_db.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
    defaultInventoryBusyLock.clearForTests();
  });

  tearDown(() async {
    defaultInventoryBusyLock.clearForTests();
    await db.close();
  });

  const now = '2026-07-24T12:00:00.000Z';
  const later = '2026-07-24T13:00:00.000Z';

  Future<int> seedUser({String membershipId = 'm-inv-1'}) {
    return insertUser(
      db,
      bungieMembershipId: membershipId,
      membershipType: 3,
      displayName: 'InvTester',
    );
  }

  InventoryItemRecord item({
    required String instanceId,
    int itemHash = 100,
    String bucket = 'kinetic',
    String location = 'vault',
    int power = 1800,
    List<int> plugHashes = const [],
    List<String> rollTags = const [],
    Map<String, Object?>? statValues,
    int? gearTier,
    List<Map<String, Object?>>? socketPlugs,
    String syncedAt = now,
    bool isMasterwork = false,
    bool isCrafted = false,
    String? characterId,
  }) {
    return InventoryItemRecord(
      instanceId: instanceId,
      itemHash: itemHash,
      bucket: bucket,
      location: location,
      characterId: characterId,
      power: power,
      isMasterwork: isMasterwork,
      isCrafted: isCrafted,
      plugHashes: plugHashes,
      rollTags: rollTags,
      statValues: statValues,
      gearTier: gearTier,
      socketPlugs: socketPlugs,
      syncedAt: syncedAt,
    );
  }

  group('US1 full-replace transaction', () {
    test('first replace inserts items and sync meta', () async {
      final userId = await seedUser();
      final status = await replaceInventoryBatch(
        db,
        userId,
        items: [
          item(
            instanceId: 'a',
            itemHash: 1,
            plugHashes: [10, 11],
            rollTags: ['Crafted'],
            statValues: {'mobility': 20},
            gearTier: 3,
            socketPlugs: [
              {
                'socketIndex': 0,
                'equippedPlugHash': 99,
                'reusablePlugHashes': [99, 98],
                'columnKind': 'barrel',
                'columnLabel': 'Barrel',
              },
            ],
            isCrafted: true,
          ),
          item(instanceId: 'b', itemHash: 2, bucket: 'energy', power: 1810),
        ],
        now: now,
      );

      expect(status.itemCount, 2);
      expect(status.syncVersion, 1);
      expect(status.lastFullSyncAt, now);

      final listed = await listInventoryItems(db, userId);
      expect(listed, hasLength(2));
      final a = listed.firstWhere((i) => i.instanceId == 'a');
      expect(a.itemHash, 1);
      expect(a.plugHashes, [10, 11]);
      expect(a.rollTags, ['Crafted']);
      expect(a.statValues!['mobility'], 20);
      expect(a.gearTier, 3);
      expect(a.isCrafted, isTrue);
      expect(a.socketPlugs, isNotNull);
      expect(a.socketPlugs!.single['equippedPlugHash'], 99);

      final gotStatus = await getInventoryStatus(db, userId);
      expect(gotStatus, status);

      final user = await getUser(db, userId);
      expect(user!.lastSyncAt, now);
    });

    test('replace prunes orphans and updates fields; bumps syncVersion', () async {
      final userId = await seedUser();
      await replaceInventoryBatch(
        db,
        userId,
        items: [
          item(instanceId: 'a', power: 10),
          item(instanceId: 'b', power: 20),
        ],
        now: now,
      );

      final status2 = await replaceInventoryBatch(
        db,
        userId,
        items: [
          item(instanceId: 'b', power: 25, bucket: 'energy'),
          item(instanceId: 'c', power: 30),
        ],
        now: later,
      );

      expect(status2.syncVersion, 2);
      expect(status2.itemCount, 2);
      expect(status2.lastFullSyncAt, later);

      final listed = await listInventoryItems(db, userId);
      expect(listed.map((i) => i.instanceId).toSet(), {'b', 'c'});
      final b = listed.firstWhere((i) => i.instanceId == 'b');
      expect(b.power, 25);
      expect(b.bucket, 'energy');
      expect(listed.any((i) => i.instanceId == 'a'), isFalse);
    });

    test('empty replace clears items and still bumps version', () async {
      final userId = await seedUser();
      await replaceInventoryBatch(
        db,
        userId,
        items: [item(instanceId: 'a')],
        now: now,
      );

      final status = await replaceInventoryBatch(
        db,
        userId,
        items: const [],
        now: later,
      );
      expect(status.itemCount, 0);
      expect(status.syncVersion, 2);
      expect(await listInventoryItems(db, userId), isEmpty);
    });

    test('failed transaction leaves prior inventory unchanged', () async {
      final userId = await seedUser();
      await replaceInventoryBatch(
        db,
        userId,
        items: [item(instanceId: 'keep', power: 1)],
        now: now,
      );

      // Force failure inside a transaction after a delete would have run if
      // replaceInventoryBatch were open-coded — use a manual txn that aborts.
      await expectLater(
        db.transaction(() async {
          await (db.delete(db.inventoryItems)
                ..where((t) => t.userId.equals(userId)))
              .go();
          // Invalid FK: user that does not exist.
          await db.into(db.inventoryItems).insert(
                InventoryItemsCompanion.insert(
                  userId: 999999,
                  instanceId: 'x',
                  itemHash: 1,
                  bucket: 'kinetic',
                  location: 'vault',
                  syncedAt: later,
                ),
              );
        }),
        throwsA(isA<Exception>()),
      );

      final listed = await listInventoryItems(db, userId);
      expect(listed, hasLength(1));
      expect(listed.single.instanceId, 'keep');
      expect(listed.single.power, 1);
      final status = await getInventoryStatus(db, userId);
      expect(status!.syncVersion, 1);
    });
  });

  group('US2 composite unique (user_id, instance_id)', () {
    test('raw duplicate insert fails', () async {
      final userId = await seedUser();
      await db.into(db.inventoryItems).insert(
            InventoryItemsCompanion.insert(
              userId: userId,
              instanceId: 'inst-1',
              itemHash: 100,
              bucket: 'kinetic',
              location: 'vault',
              syncedAt: now,
            ),
          );
      await expectLater(
        db.into(db.inventoryItems).insert(
              InventoryItemsCompanion.insert(
                userId: userId,
                instanceId: 'inst-1',
                itemHash: 200,
                bucket: 'energy',
                location: 'vault',
                syncedAt: now,
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });

    test('replace leaves single row with updated power for same instance', () async {
      final userId = await seedUser();
      await replaceInventoryBatch(
        db,
        userId,
        items: [item(instanceId: 'inst-1', power: 10)],
        now: now,
      );
      await replaceInventoryBatch(
        db,
        userId,
        items: [item(instanceId: 'inst-1', power: 20)],
        now: later,
      );

      final listed = await listInventoryItems(db, userId);
      expect(listed, hasLength(1));
      expect(listed.single.power, 20);
      expect(listed.single.instanceId, 'inst-1');
    });
  });

  group('US3 busy lock hook', () {
    test('concurrent exclusive replace for same user throws busy', () async {
      final userId = await seedUser();
      final lock = InventoryBusyLock();
      final started = Completer<void>();
      final release = Completer<void>();

      final first = lock.runExclusive(userId, () async {
        started.complete();
        await release.future;
        return replaceInventoryBatch(
          db,
          userId,
          items: [item(instanceId: 'a')],
          now: now,
        );
      });

      await started.future;
      expect(lock.isBusy(userId), isTrue);
      expect(isInventoryReplaceBusy(userId, lock: lock), isTrue);

      await expectLater(
        lock.runExclusive(userId, () async {
          return replaceInventoryBatch(
            db,
            userId,
            items: [item(instanceId: 'b')],
            now: later,
          );
        }),
        throwsA(isA<InventoryReplaceBusyException>()),
      );

      release.complete();
      final status = await first;
      expect(status.itemCount, 1);
      expect(lock.isBusy(userId), isFalse);

      // After release, exclusive replace succeeds again.
      final status2 = await replaceInventoryBatchExclusive(
        db,
        userId,
        items: [item(instanceId: 'c')],
        now: later,
        lock: lock,
      );
      expect(status2.itemCount, 1);
      final listed = await listInventoryItems(db, userId);
      expect(listed.single.instanceId, 'c');
    });

    test('exclusive replace for different user allowed while A busy', () async {
      final userA = await seedUser(membershipId: 'm-a');
      final userB = await seedUser(membershipId: 'm-b');
      final lock = InventoryBusyLock();
      final started = Completer<void>();
      final release = Completer<void>();

      final first = lock.runExclusive(userA, () async {
        started.complete();
        await release.future;
        return 'held';
      });

      await started.future;

      final bStatus = await replaceInventoryBatchExclusive(
        db,
        userB,
        items: [item(instanceId: 'b1')],
        now: now,
        lock: lock,
      );
      expect(bStatus.itemCount, 1);

      release.complete();
      await first;
    });

    test('replaceInventoryBatchExclusive uses default lock', () async {
      final userId = await seedUser();
      final started = Completer<void>();
      final release = Completer<void>();

      final first = defaultInventoryBusyLock.runExclusive(userId, () async {
        started.complete();
        await release.future;
      });
      await started.future;

      await expectLater(
        replaceInventoryBatchExclusive(
          db,
          userId,
          items: [item(instanceId: 'x')],
          now: now,
        ),
        throwsA(isA<InventoryReplaceBusyException>()),
      );

      release.complete();
      await first;
    });
  });

  group('US4 query helpers', () {
    test('filters by bucket, hashes, instance ids; user scoped', () async {
      final userA = await seedUser(membershipId: 'qa');
      final userB = await seedUser(membershipId: 'qb');

      await replaceInventoryBatch(
        db,
        userA,
        items: [
          item(instanceId: 'a1', itemHash: 1, bucket: 'kinetic'),
          item(instanceId: 'a2', itemHash: 2, bucket: 'energy'),
          item(
            instanceId: 'a3',
            itemHash: 3,
            bucket: 'helmet',
            rollTags: ['MeleeBuildCandidate'],
          ),
        ],
        now: now,
      );
      await replaceInventoryBatch(
        db,
        userB,
        items: [item(instanceId: 'b1', itemHash: 1, bucket: 'kinetic')],
        now: now,
      );

      final kinetic = await queryInventoryByBucket(db, userA, 'kinetic');
      expect(kinetic.map((i) => i.instanceId), ['a1']);

      final byHash = await queryInventoryByHashes(db, userA, [2, 3]);
      expect(byHash.map((i) => i.instanceId).toSet(), {'a2', 'a3'});
      expect(await queryInventoryByHashes(db, userA, const []), isEmpty);

      final byInst =
          await queryInventoryByInstanceIds(db, userA, ['a1', 'missing']);
      expect(byInst.map((i) => i.instanceId), ['a1']);
      expect(await queryInventoryByInstanceIds(db, userA, const []), isEmpty);

      final tagged =
          await queryInventoryByTags(db, userA, 'MeleeBuildCandidate');
      expect(tagged.map((i) => i.instanceId), ['a3']);

      final listA = await listInventoryItems(db, userA);
      expect(listA, hasLength(3));
      expect(listA.every((i) => i.instanceId.startsWith('a')), isTrue);
      expect(await getInventoryStatus(db, userA), isNotNull);
      expect(await getInventoryStatus(db, 99999), isNull);
    });
  });
}
