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

  const now = '2026-08-07T12:00:00.000Z';
  const later = '2026-08-07T13:00:00.000Z';

  Future<int> seedUser() => insertUser(
        db,
        bungieMembershipId: 'm-roll-1',
        membershipType: 3,
        displayName: 'Roller',
      );

  group('weapon_roll_targets CRUD', () {
    test('create → list → get → update → delete', () async {
      final userId = await seedUser();
      final created = await createRollTarget(
        db,
        userId,
        id: 'rt1',
        weaponKey: '12345',
        name: 'PvE',
        columns: const [
          RollTargetColumnRecord(
            columnKey: 'trait1',
            preferredPlugHashes: [1, 2],
            avoidPlugHashes: [9],
          ),
        ],
        now: now,
      );

      expect(created.id, 'rt1');
      expect(created.name, 'PvE');
      expect(created.columns.single.preferredPlugHashes, [1, 2]);
      expect(created.columns.single.avoidPlugHashes, [9]);

      final listed = await listRollTargets(db, userId, weaponKey: '12345');
      expect(listed.map((r) => r.id), ['rt1']);

      final got = await getRollTarget(db, userId, 'rt1');
      expect(got!.name, 'PvE');

      final updated = await updateRollTarget(
        db,
        userId,
        'rt1',
        name: 'Raid',
        columns: const [
          RollTargetColumnRecord(
            columnKey: 'trait1',
            preferredPlugHashes: [1],
            avoidPlugHashes: [8, 9],
          ),
        ],
        now: later,
      );
      expect(updated!.name, 'Raid');
      expect(updated.columns.single.preferredPlugHashes, [1]);
      expect(updated.updatedAt, later);

      expect(await deleteRollTarget(db, userId, 'rt1'), isTrue);
      expect(await getRollTarget(db, userId, 'rt1'), isNull);
    });

    test('rejects preferred ∩ avoid on create', () async {
      final userId = await seedUser();
      expect(
        () => createRollTarget(
          db,
          userId,
          id: 'bad',
          weaponKey: '1',
          name: 'Bad',
          columns: const [
            RollTargetColumnRecord(
              columnKey: 't1',
              preferredPlugHashes: [1, 2],
              avoidPlugHashes: [2],
            ),
          ],
          now: now,
        ),
        throwsA(
          isA<RollTargetPersistException>().having(
            (e) => e.code,
            'code',
            'ROLL_TARGET_PREFERRED_AVOID_OVERLAP',
          ),
        ),
      );
    });

    test('duplicate name same weapon fails', () async {
      final userId = await seedUser();
      await createRollTarget(
        db,
        userId,
        id: 'a',
        weaponKey: 'w1',
        name: 'PvE',
        now: now,
      );
      expect(
        () => createRollTarget(
          db,
          userId,
          id: 'b',
          weaponKey: 'w1',
          name: 'PvE',
          now: now,
        ),
        throwsA(isA<RollTargetPersistException>()),
      );
      // Same name different weapon OK
      final other = await createRollTarget(
        db,
        userId,
        id: 'c',
        weaponKey: 'w2',
        name: 'PvE',
        now: now,
      );
      expect(other.weaponKey, 'w2');
    });

    test('active target set / get / clear; delete clears active', () async {
      final userId = await seedUser();
      await createRollTarget(
        db,
        userId,
        id: 'rt-a',
        weaponKey: 'w1',
        name: 'PvE',
        now: now,
      );
      await createRollTarget(
        db,
        userId,
        id: 'rt-b',
        weaponKey: 'w1',
        name: 'PvP',
        now: now,
      );

      await setActiveRollTarget(
        db,
        userId,
        'w1',
        targetId: 'rt-b',
        now: now,
      );
      expect(await getActiveRollTargetId(db, userId, 'w1'), 'rt-b');
      final active = await getActiveRollTarget(db, userId, 'w1');
      expect(active!.name, 'PvP');

      await setActiveRollTarget(
        db,
        userId,
        'w1',
        targetId: null,
        now: later,
      );
      expect(await getActiveRollTargetId(db, userId, 'w1'), isNull);

      await setActiveRollTarget(
        db,
        userId,
        'w1',
        targetId: 'rt-a',
        now: later,
      );
      expect(await deleteRollTarget(db, userId, 'rt-a'), isTrue);
      expect(await getActiveRollTargetId(db, userId, 'w1'), isNull);
    });

    test('active target wrong weapon rejected', () async {
      final userId = await seedUser();
      await createRollTarget(
        db,
        userId,
        id: 'rt1',
        weaponKey: 'w1',
        name: 'PvE',
        now: now,
      );
      expect(
        () => setActiveRollTarget(
          db,
          userId,
          'w2',
          targetId: 'rt1',
          now: now,
        ),
        throwsA(
          isA<RollTargetPersistException>().having(
            (e) => e.code,
            'code',
            'ROLL_TARGET_ACTIVE_INVALID',
          ),
        ),
      );
    });
  });

  group('ensure creates tables', () {
    test('core tables include weapon_roll_targets', () async {
      final tables = await db.listUserTableNames();
      expect(tables, contains('weapon_roll_targets'));
      expect(tables, contains('weapon_roll_target_active'));
    });
  });
}
