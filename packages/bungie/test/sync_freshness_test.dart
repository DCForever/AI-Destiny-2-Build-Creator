import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:test/test.dart';

class _CountingProfileClient implements BungieProfileClient {
  int inventoryCalls = 0;

  @override
  Future<List<DestinyMembership>> getMemberships(String accessToken) async {
    return const [
      DestinyMembership(
        membershipType: 3,
        membershipId: 'm1',
        displayName: 'G',
      ),
    ];
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
    return FullInventoryParseResult(
      items: const [
        RawInventoryItem(
          instanceId: 'i1',
          itemHash: 1,
          bucketHash: 1498876634,
          location: 'vault',
        ),
      ],
      diagnostics: InventoryParseDiagnostics(
        membership: membership,
        raw: InventoryRawCounts(total: 1, vault: 1),
        parsed: InventoryParsedCounts(total: 1, equipmentTotal: 1),
        dropped: InventoryDroppedCounts(),
      ),
    );
  }
}

void main() {
  group('isInventoryFresh', () {
    final now = DateTime.parse('2026-07-10T12:00:30.000Z').millisecondsSinceEpoch;

    test('true within 60s', () {
      expect(
        isInventoryFresh(
          '2026-07-10T12:00:00.000Z',
          nowMs: now,
        ),
        isTrue,
      );
    });

    test('false after 60s', () {
      final later =
          DateTime.parse('2026-07-10T12:01:01.000Z').millisecondsSinceEpoch;
      expect(
        isInventoryFresh(
          '2026-07-10T12:00:00.000Z',
          nowMs: later,
        ),
        isFalse,
      );
    });

    test('false for null or invalid', () {
      expect(isInventoryFresh(null, nowMs: now), isFalse);
      expect(isInventoryFresh('not-a-date', nowMs: now), isFalse);
    });

    test('default window is 60000 ms', () {
      expect(kEquipSyncFreshMs, 60000);
    });
  });

  group('syncIfStale', () {
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

    test('skips sync when lastFullSyncAt is fresh', () async {
      final userId = await insertUser(
        db,
        bungieMembershipId: 'bm1',
        membershipType: 3,
        displayName: 'G',
      );
      await replaceInventoryBatch(
        db,
        userId,
        items: const [
          InventoryItemRecord(
            instanceId: 'x',
            itemHash: 1,
            bucket: 'Kinetic',
            location: 'vault',
            syncedAt: '2026-07-10T12:00:00.000Z',
          ),
        ],
        now: '2026-07-10T12:00:00.000Z',
      );

      final client = _CountingProfileClient();
      final nowMs =
          DateTime.parse('2026-07-10T12:00:30.000Z').millisecondsSinceEpoch;

      final result = await syncIfStale(
        db: db,
        userId: userId,
        accessToken: 'tok',
        profileClient: client,
        nowMs: nowMs,
        lock: lock,
      );

      expect(result.synced, isFalse);
      expect(result.lastFullSyncAt, '2026-07-10T12:00:00.000Z');
      expect(client.inventoryCalls, 0);
    });

    test('runs sync when stale', () async {
      final userId = await insertUser(
        db,
        bungieMembershipId: 'bm2',
        membershipType: 3,
        displayName: 'G',
      );
      final client = _CountingProfileClient();
      const now = '2026-07-10T12:05:00.000Z';
      final nowMs = DateTime.parse(now).millisecondsSinceEpoch;

      final result = await syncIfStale(
        db: db,
        userId: userId,
        accessToken: 'tok',
        profileClient: client,
        now: now,
        nowMs: nowMs,
        lock: lock,
      );

      expect(result.synced, isTrue);
      expect(result.result?.itemCount, 1);
      expect(result.result?.syncVersion, 1);
      expect(client.inventoryCalls, 1);
      final listed = await listInventoryItems(db, userId);
      expect(listed, hasLength(1));
    });
  });
}
