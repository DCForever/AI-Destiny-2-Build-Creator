import 'dart:async';

import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/auth/windows_oauth_session.dart';
import 'package:destiny2_windows_host/settings/inventory_sync_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'inventory_sync_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late InventoryBusyLock lock;
  late MemoryTokenStore store;
  late WindowsOAuthSession session;
  late FakeProfileClient profile;
  late InventorySyncController controller;

  setUp(() async {
    db = AppDatabase.memory();
    lock = InventoryBusyLock();
    defaultInventoryBusyLock.clearForTests();
    store = MemoryTokenStore();
    await seedSignedIn(store);
    session = buildSignedInSession(store: store);
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
    controller.dispose();
    defaultInventoryBusyLock.clearForTests();
    await db.close();
  });

  group('syncNow', () {
    test('writes inventory and updates meta', () async {
      await controller.syncNow();

      expect(controller.phase, InventorySyncPhase.idle);
      expect(controller.errorMessage, isNull);
      expect(controller.itemCount, 2);
      expect(controller.syncVersion, 1);
      expect(controller.lastFullSyncAt, isNotNull);
      expect(profile.inventoryCalls, 1);
      // DART-053: full diagnostics retained after successful sync.
      expect(controller.lastDiagnostics, isNotNull);
      expect(controller.lastRawTotal, isNotNull);
      expect(controller.lastParsedTotal, isNotNull);
      expect(controller.lastDroppedTotal, isNotNull);
      expect(controller.lastStoredTotal, 2);
      expect(controller.lastDiagnosticsFormatted, contains('Bungie raw items'));
      expect(controller.lastDiagnosticsFormatted, contains('Stored after resolution'));

      final user = await getUserByMembership(
        db,
        bungieMembershipId: 'bungie-net-99',
      );
      expect(user, isNotNull);
      final items = await listInventoryItems(db, user!.id);
      expect(items, hasLength(2));
    });

    test('vault transfer fixtures require lookup (fail without)', () async {
      profile.items = [
        const RawInventoryItem(
          instanceId: 'vault-gun',
          itemHash: 555,
          bucketHash: 138197802, // vault general — needs lookup
          location: 'vault',
          power: 1800,
        ),
      ];
      // Controller without lookup builder — production wiring must not do this.
      await controller.syncNow();
      expect(controller.phase, InventorySyncPhase.idle);
      expect(controller.itemCount, 0);
      expect(controller.lastResolvedFromTransfer, 0);
      final empty = await listInventoryItems(db, controller.localUserId!);
      expect(empty, isEmpty);
    });

    test('vault fixtures store Kinetic when lookup wired', () async {
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
      controller.dispose();
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

    test('second sync replaces inventory and bumps version', () async {
      await controller.syncNow();
      profile.items = [
        const RawInventoryItem(
          instanceId: 'only-one',
          itemHash: 999,
          bucketHash: 1498876634,
          location: 'vault',
          power: 1,
        ),
      ];
      await controller.syncNow();

      expect(controller.itemCount, 1);
      expect(controller.syncVersion, 2);
      final items = await listInventoryItems(db, controller.localUserId!);
      expect(items.single.instanceId, 'only-one');
    });

    test('signed out sets error and does not call profile', () async {
      await session.signOut();
      await controller.syncNow();

      expect(controller.phase, InventorySyncPhase.error);
      expect(controller.errorMessage, contains('Sign in'));
      expect(profile.inventoryCalls, 0);
    });

    test('refreshStatus when signed out clears retained diagnostics', () async {
      await controller.syncNow();
      expect(controller.lastDiagnostics, isNotNull);
      await session.signOut();
      await controller.refreshStatus();
      expect(controller.lastDiagnostics, isNull);
      expect(controller.lastRawTotal, isNull);
      expect(controller.lastStoredTotal, isNull);
    });

    test('profile failure surfaces error', () async {
      profile = FakeProfileClient(throwOnInventory: true);
      controller.dispose();
      controller = InventorySyncController(
        db: db,
        session: session,
        profileClient: profile,
        lock: lock,
      );

      await controller.syncNow();

      expect(controller.phase, InventorySyncPhase.error);
      expect(controller.errorMessage, isNotNull);
      expect(controller.errorMessage, contains('memberships'));
    });

    test('in-flight second syncNow is ignored', () async {
      final slow = FakeProfileClient(
        inventoryDelay: const Duration(milliseconds: 80),
      );
      controller.dispose();
      controller = InventorySyncController(
        db: db,
        session: session,
        profileClient: slow,
        lock: lock,
      );

      final first = controller.syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.isSyncing, isTrue);
      await controller.syncNow(); // no-op while syncing
      await first;

      expect(slow.inventoryCalls, 1);
      expect(controller.itemCount, 2);
      expect(controller.phase, InventorySyncPhase.idle);
    });

    test('SyncInProgressError maps to busy message', () async {
      final user = await ensureUser(
        db,
        bungieMembershipId: 'bungie-net-99',
        membershipType: 0,
      );
      final held = Completer<void>();
      final release = Completer<void>();
      final holdFuture = lock.runExclusive(user.id, () async {
        held.complete();
        await release.future;
      });
      await held.future;

      await controller.syncNow();
      expect(controller.phase, InventorySyncPhase.error);
      expect(
        controller.errorMessage?.toLowerCase() ?? '',
        anyOf(contains('progress'), contains('busy')),
      );

      release.complete();
      await holdFuture;
    });
  });

  group('refreshStatus + freshness', () {
    test('refreshStatus loads meta without network inventory', () async {
      await controller.syncNow();
      final calls = profile.inventoryCalls;

      await controller.refreshStatus();
      expect(profile.inventoryCalls, calls);
      expect(controller.itemCount, 2);
      expect(controller.syncVersion, 1);
    });

    test('isFresh true within 60s window', () async {
      final now = DateTime.utc(2026, 7, 24, 12);
      controller.dispose();
      controller = InventorySyncController(
        db: db,
        session: session,
        profileClient: profile,
        lock: lock,
        clock: () => now,
      );
      final user = await ensureUser(
        db,
        bungieMembershipId: 'bungie-net-99',
        membershipType: 0,
      );
      await replaceInventoryBatch(
        db,
        user.id,
        items: const [],
        now: now.subtract(const Duration(seconds: 30)).toIso8601String(),
      );
      await controller.refreshStatus();
      expect(controller.isFresh, isTrue);
    });

    test('isFresh false when stale', () async {
      final now = DateTime.utc(2026, 7, 24, 12);
      controller.dispose();
      controller = InventorySyncController(
        db: db,
        session: session,
        profileClient: profile,
        lock: lock,
        clock: () => now,
      );
      final user = await ensureUser(
        db,
        bungieMembershipId: 'bungie-net-99',
        membershipType: 0,
      );
      await replaceInventoryBatch(
        db,
        user.id,
        items: const [],
        now: now.subtract(const Duration(seconds: 61)).toIso8601String(),
      );
      await controller.refreshStatus();
      expect(controller.isFresh, isFalse);
      expect(controller.lastFullSyncAt, isNotNull);
    });
  });
}
