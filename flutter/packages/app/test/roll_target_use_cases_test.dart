import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedUser() => insertUser(
        db,
        bungieMembershipId: 'm-app-roll',
        membershipType: 3,
      );

  test('create validates domain overlap then persists', () async {
    final userId = await seedUser();
    expect(
      () => createWeaponRollTarget(
        db,
        userId: userId,
        weaponKey: '99',
        name: 'Bad',
        columns: const [
          RollTargetColumn(
            columnKey: 't1',
            preferredPlugHashes: {1},
            avoidPlugHashes: {1},
          ),
        ],
        nowIso: '2026-08-07T00:00:00.000Z',
      ),
      throwsA(isA<RollTargetValidationException>()),
    );

    final t = await createWeaponRollTarget(
      db,
      userId: userId,
      weaponKey: '99',
      name: 'PvE',
      columns: const [
        RollTargetColumn(
          columnKey: 't1',
          preferredPlugHashes: {1, 2},
          avoidPlugHashes: {9},
        ),
      ],
      id: 'rt-app-1',
      nowIso: '2026-08-07T00:00:00.000Z',
    );
    expect(t.id, 'rt-app-1');
    expect(t.columns.single.preferredPlugHashes, {1, 2});

    await setActiveWeaponRollTarget(
      db,
      userId: userId,
      weaponKey: '99',
      targetId: t.id,
      nowIso: '2026-08-07T00:00:00.000Z',
    );
    final active = await getActiveWeaponRollTarget(
      db,
      userId: userId,
      weaponKey: '99',
    );
    expect(active!.name, 'PvE');

    final ranked = rankOwnedForRollTarget(
      t,
      const [
        RollTargetInstanceInput(
          instanceId: 'i1',
          plugsByColumn: {'t1': 1},
        ),
        RollTargetInstanceInput(
          instanceId: 'i2',
          plugsByColumn: {'t1': 9},
        ),
      ],
    );
    expect(ranked.first.instance.instanceId, 'i1');
    expect(ranked.last.match.avoidHits, 1);
  });

  test('create rejects exotic weapons (DBR-IDL-009)', () async {
    final userId = await seedUser();
    expect(
      () => createWeaponRollTarget(
        db,
        userId: userId,
        weaponKey: 'exotic-1',
        name: 'PvE',
        columns: const [
          RollTargetColumn(
            columnKey: 't1',
            preferredPlugHashes: {1},
          ),
        ],
        isExotic: true,
        nowIso: '2026-08-07T00:00:00.000Z',
      ),
      throwsA(
        isA<RollTargetValidationException>().having(
          (e) => e.code,
          'code',
          'ROLL_TARGET_EXOTIC_NOT_ALLOWED',
        ),
      ),
    );
  });
}
