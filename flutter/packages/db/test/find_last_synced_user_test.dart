import 'package:destiny2_db/destiny2_db.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  test('findLastSyncedBungieUser prefers latest meta and skips local-library', () async {
    final localId = await insertUser(
      db,
      bungieMembershipId: kLocalLibraryMembershipId,
      membershipType: 0,
      displayName: 'Local library',
    );
    final oldId = await insertUser(
      db,
      bungieMembershipId: 'm-old',
      membershipType: 3,
    );
    final newId = await insertUser(
      db,
      bungieMembershipId: 'm-new',
      membershipType: 3,
    );

    await replaceInventoryBatch(
      db,
      localId,
      items: [
        InventoryItemRecord(
          instanceId: 'l1',
          itemHash: 1,
          bucket: 'kinetic',
          location: 'vault',
          power: 1,
          isMasterwork: false,
          isCrafted: false,
          plugHashes: const [],
          rollTags: const [],
          syncedAt: '2026-01-01T00:00:00.000Z',
        ),
      ],
      now: '2026-01-01T00:00:00.000Z',
    );
    await replaceInventoryBatch(
      db,
      oldId,
      items: [
        InventoryItemRecord(
          instanceId: 'o1',
          itemHash: 2,
          bucket: 'kinetic',
          location: 'vault',
          power: 1,
          isMasterwork: false,
          isCrafted: false,
          plugHashes: const [],
          rollTags: const [],
          syncedAt: '2026-01-02T00:00:00.000Z',
        ),
      ],
      now: '2026-01-02T00:00:00.000Z',
    );
    await replaceInventoryBatch(
      db,
      newId,
      items: [
        InventoryItemRecord(
          instanceId: 'n1',
          itemHash: 3,
          bucket: 'kinetic',
          location: 'vault',
          power: 1,
          isMasterwork: false,
          isCrafted: false,
          plugHashes: const [],
          rollTags: const [],
          syncedAt: '2026-01-03T00:00:00.000Z',
        ),
      ],
      now: '2026-01-03T00:00:00.000Z',
    );

    final found = await findLastSyncedBungieUser(db);
    expect(found, isNotNull);
    expect(found!.bungieMembershipId, 'm-new');
    expect(found.id, newId);
  });

  test('findLastSyncedBungieUser returns null when only local-library', () async {
    final localId = await insertUser(
      db,
      bungieMembershipId: kLocalLibraryMembershipId,
      membershipType: 0,
    );
    await replaceInventoryBatch(
      db,
      localId,
      items: [
        InventoryItemRecord(
          instanceId: 'l1',
          itemHash: 1,
          bucket: 'kinetic',
          location: 'vault',
          power: 1,
          isMasterwork: false,
          isCrafted: false,
          plugHashes: const [],
          rollTags: const [],
          syncedAt: '2026-01-01T00:00:00.000Z',
        ),
      ],
      now: '2026-01-01T00:00:00.000Z',
    );
    expect(await findLastSyncedBungieUser(db), isNull);
  });
}
