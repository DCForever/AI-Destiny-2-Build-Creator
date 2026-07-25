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

      final user = await getUserByMembership(
        db,
        bungieMembershipId: 'bungie-net-99',
      );
      expect(user, isNotNull);
      final items = await listInventoryItems(db, user!.id);
      expect(items, hasLength(2));
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
