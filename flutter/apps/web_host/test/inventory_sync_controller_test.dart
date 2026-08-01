import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_web_host/auth/token_store.dart';
import 'package:destiny2_web_host/settings/inventory_sync_controller.dart';
import 'package:test/test.dart';

import 'inventory_sync_test_fakes.dart';

void main() {
  late AppDatabase db;
  late InventoryBusyLock lock;
  late MemoryTokenStore store;
  late FakeProfileClient profile;
  late InventorySyncController controller;

  setUp(() async {
    db = AppDatabase.memory();
    lock = InventoryBusyLock();
    defaultInventoryBusyLock.clearForTests();
    store = MemoryTokenStore();
    await seedSignedIn(store);
    final session = buildSignedInSession(store: store);
    await session.restore();
    profile = FakeProfileClient();
    controller = InventorySyncController(
      db: db,
      session: session,
      profileClient: profile,
      lock: lock,
      clock: () => DateTime.utc(2026, 7, 24, 12),
    );
  });

  tearDown(() async {
    defaultInventoryBusyLock.clearForTests();
    await db.close();
  });

  group('syncNow', () {
    test('writes inventory and updates meta + diagnostics', () async {
      await controller.syncNow();

      expect(controller.phase, InventorySyncPhase.idle);
      expect(controller.errorMessage, isNull);
      expect(controller.itemCount, 2);
      expect(controller.syncVersion, 1);
      expect(controller.lastFullSyncAt, isNotNull);
      expect(profile.inventoryCalls, 1);
      expect(controller.lastDiagnostics, isNotNull);
      expect(controller.lastRawTotal, isNotNull);
      expect(controller.lastStoredTotal, 2);
      expect(controller.lastDiagnosticsFormatted, contains('Bungie raw items'));

      final user = await getUserByMembership(
        db,
        bungieMembershipId: 'bungie-net-99',
      );
      expect(user, isNotNull);
      final items = await listInventoryItems(db, user!.id);
      expect(items, hasLength(2));
    });

    test('vault transfer fixtures drop without lookup', () async {
      profile.items = [
        const RawInventoryItem(
          instanceId: 'vault-gun',
          itemHash: 555,
          bucketHash: 138197802, // vault general
          location: 'vault',
          power: 1800,
        ),
      ];
      await controller.syncNow();
      expect(controller.phase, InventorySyncPhase.idle);
      expect(controller.itemCount, 0);
      expect(controller.lastResolvedFromTransfer, 0);
      final empty = await listInventoryItems(db, controller.localUserId!);
      expect(empty, isEmpty);
    });

    test('vault fixtures store Kinetic when lookup wired (DART-056)', () async {
      profile.items = [
        const RawInventoryItem(
          instanceId: 'vault-gun',
          itemHash: 555,
          bucketHash: 138197802,
          location: 'vault',
          power: 1800,
        ),
        const RawInventoryItem(
          instanceId: 'post-helm',
          itemHash: 666,
          bucketHash: 215593132, // postmaster
          location: 'character',
          characterId: 'c1',
          power: 1700,
        ),
      ];
      final session = buildSignedInSession(store: store);
      await session.restore();
      controller = InventorySyncController(
        db: db,
        session: session,
        profileClient: profile,
        lock: lock,
        equipmentBucketLookupBuilder: (hashes) async {
          expect(hashes, containsAll([555, 666]));
          return buildEquipmentBucketLookup(
            {
              '555': {
                'hash': 555,
                'inventory': {'bucketTypeHash': 1498876634},
              },
              '666': {
                'hash': 666,
                'inventory': {'bucketTypeHash': 3448274439},
              },
            },
            hashes,
          );
        },
      );

      await controller.syncNow();

      expect(controller.phase, InventorySyncPhase.idle);
      expect(controller.itemCount, 2);
      expect(controller.lastResolvedFromTransfer, greaterThan(0));
      expect(controller.lastResolvedFromTransfer, 2);
      final items = await listInventoryItems(db, controller.localUserId!);
      expect(items, hasLength(2));
      expect(
        items.where((e) => e.instanceId == 'vault-gun').single.bucket,
        'Kinetic',
      );
      expect(
        items.where((e) => e.instanceId == 'vault-gun').single.location,
        'vault',
      );
      expect(
        items.where((e) => e.instanceId == 'post-helm').single.bucket,
        'Helmet',
      );
    });

    test('signed out sets error and does not call profile', () async {
      final emptyStore = MemoryTokenStore();
      final session = buildSignedInSession(store: emptyStore);
      await session.restore();
      controller = InventorySyncController(
        db: db,
        session: session,
        profileClient: profile,
        lock: lock,
      );
      await controller.syncNow();
      expect(controller.phase, InventorySyncPhase.error);
      expect(controller.errorMessage, contains('Sign in'));
      expect(profile.inventoryCalls, 0);
    });
  });
}
