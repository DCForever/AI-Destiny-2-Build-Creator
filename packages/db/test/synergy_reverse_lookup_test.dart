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

  Future<int> seedUser() {
    return insertUser(
      db,
      bungieMembershipId: 'm-syn-rev',
      membershipType: 3,
      displayName: 'Rev',
    );
  }

  test('findSynergiesByTarget returns linked synergies by itemHash', () async {
    final userId = await seedUser();
    const now = '2026-07-25T00:00:00.000Z';
    await createSynergyRecord(
      db,
      userId,
      id: 'syn-a',
      name: 'A',
      type: 'dps',
      links: const [
        SynergyLinkInput(
          kind: 'weapon',
          displayName: 'Fatebringer',
          itemHash: 111,
        ),
      ],
      now: now,
    );
    await createSynergyRecord(
      db,
      userId,
      id: 'syn-b',
      name: 'B',
      type: 'melee',
      links: const [
        SynergyLinkInput(
          kind: 'weapon',
          displayName: 'Fatebringer',
          itemHash: 111,
        ),
      ],
      now: now,
    );
    await createSynergyRecord(
      db,
      userId,
      id: 'syn-c',
      name: 'C',
      type: 'solo',
      links: const [
        SynergyLinkInput(
          kind: 'weapon',
          displayName: 'Other',
          itemHash: 222,
        ),
      ],
      now: now,
    );

    final found = await findSynergiesByTarget(
      db,
      userId,
      const SynergyTargetQuery(kind: 'weapon', itemHash: 111),
    );
    expect(found.map((s) => s.id).toSet(), {'syn-a', 'syn-b'});

    final batch = await findSynergiesByItemHashes(
      db,
      userId,
      'weapon',
      [111, 222, 999],
    );
    expect(batch[111]!.map((s) => s.id).toSet(), {'syn-a', 'syn-b'});
    expect(batch[222]!.map((s) => s.id).toList(), ['syn-c']);
    expect(batch[999], isEmpty);
  });
}
