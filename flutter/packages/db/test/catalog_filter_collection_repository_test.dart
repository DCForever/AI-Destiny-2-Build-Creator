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

  const now = '2026-08-08T12:00:00.000Z';
  const later = '2026-08-08T13:00:00.000Z';

  Future<int> seedUser() => insertUser(
        db,
        bungieMembershipId: 'm-filters-1',
        membershipType: 3,
        displayName: 'Filterer',
      );

  group('catalog_filter_collections CRUD', () {
    test('create → list → get → update → delete', () async {
      final userId = await seedUser();
      final created = await createCatalogFilterCollection(
        db,
        userId,
        id: 'fc1',
        browseMode: 'weapons',
        name: 'Solar HC',
        scope: 'owned',
        query: 'adept',
        exotic: false,
        elements: const CatalogFacetRecord(include: ['Solar']),
        archetypes: const CatalogFacetRecord(include: ['Hand Cannon']),
        sortKeys: const ['slot', 'name'],
        groupBy: const ['element'],
        now: now,
      );

      expect(created.id, 'fc1');
      expect(created.name, 'Solar HC');
      expect(created.scope, 'owned');
      expect(created.query, 'adept');
      expect(created.exotic, isFalse);
      expect(created.elements.include, ['Solar']);
      expect(created.sortKeys, ['slot', 'name']);
      expect(created.groupBy, ['element']);

      final listed =
          await listCatalogFilterCollections(db, userId, browseMode: 'weapons');
      expect(listed.map((r) => r.id), ['fc1']);

      final got = await getCatalogFilterCollection(db, userId, 'fc1');
      expect(got!.name, 'Solar HC');

      final updated = await updateCatalogFilterCollection(
        db,
        userId,
        'fc1',
        name: 'Solar HC v2',
        scope: 'all',
        elements: const CatalogFacetRecord(include: ['Solar', 'Arc']),
        now: later,
      );
      expect(updated!.name, 'Solar HC v2');
      expect(updated.scope, 'all');
      expect(updated.elements.include, ['Solar', 'Arc']);
      expect(updated.updatedAt, later);

      expect(await deleteCatalogFilterCollection(db, userId, 'fc1'), isTrue);
      expect(await getCatalogFilterCollection(db, userId, 'fc1'), isNull);
    });

    test('same name replaces filters and preserves id', () async {
      final userId = await seedUser();
      final first = await createCatalogFilterCollection(
        db,
        userId,
        id: 'a',
        browseMode: 'weapons',
        name: 'Raid',
        query: 'old',
        now: now,
      );
      final second = await createCatalogFilterCollection(
        db,
        userId,
        id: 'b',
        browseMode: 'weapons',
        name: 'Raid',
        query: 'new',
        elements: const CatalogFacetRecord(include: ['Void']),
        now: later,
      );
      expect(second.id, first.id);
      expect(second.query, 'new');
      expect(second.elements.include, ['Void']);
      final listed =
          await listCatalogFilterCollections(db, userId, browseMode: 'weapons');
      expect(listed, hasLength(1));
    });

    test('same name allowed across browse modes', () async {
      final userId = await seedUser();
      await createCatalogFilterCollection(
        db,
        userId,
        id: 'w',
        browseMode: 'weapons',
        name: 'Solar',
        now: now,
      );
      await createCatalogFilterCollection(
        db,
        userId,
        id: 'a',
        browseMode: 'armor',
        name: 'Solar',
        now: now,
      );
      final all = await listCatalogFilterCollections(db, userId);
      expect(all, hasLength(2));
    });

    test('rejects empty name', () async {
      final userId = await seedUser();
      expect(
        () => createCatalogFilterCollection(
          db,
          userId,
          id: 'x',
          browseMode: 'weapons',
          name: '  ',
          now: now,
        ),
        throwsA(
          isA<CatalogFilterCollectionPersistException>().having(
            (e) => e.code,
            'code',
            'FILTER_COLLECTION_NAME_REQUIRED',
          ),
        ),
      );
    });

    test('rejects invalid browse mode', () async {
      final userId = await seedUser();
      expect(
        () => createCatalogFilterCollection(
          db,
          userId,
          id: 'x',
          browseMode: 'pets',
          name: 'x',
          now: now,
        ),
        throwsA(
          isA<CatalogFilterCollectionPersistException>().having(
            (e) => e.code,
            'code',
            'FILTER_COLLECTION_BROWSE_MODE_INVALID',
          ),
        ),
      );
    });

    test('soft max per mode', () async {
      final userId = await seedUser();
      for (var i = 0; i < 3; i++) {
        await createCatalogFilterCollection(
          db,
          userId,
          id: 'c$i',
          browseMode: 'weapons',
          name: 'N$i',
          now: now,
          maxPerMode: 3,
        );
      }
      expect(
        () => createCatalogFilterCollection(
          db,
          userId,
          id: 'overflow',
          browseMode: 'weapons',
          name: 'overflow',
          now: now,
          maxPerMode: 3,
        ),
        throwsA(
          isA<CatalogFilterCollectionPersistException>().having(
            (e) => e.code,
            'code',
            'FILTER_COLLECTION_MAX_EXCEEDED',
          ),
        ),
      );
      // Replace-by-name still allowed at cap.
      final replaced = await createCatalogFilterCollection(
        db,
        userId,
        id: 'new-id',
        browseMode: 'weapons',
        name: 'N0',
        query: 'replaced',
        now: later,
        maxPerMode: 3,
      );
      expect(replaced.id, 'c0');
      expect(replaced.query, 'replaced');
    });

    test('user isolation', () async {
      final u1 = await seedUser();
      final u2 = await insertUser(
        db,
        bungieMembershipId: 'm-filters-2',
        membershipType: 3,
      );
      await createCatalogFilterCollection(
        db,
        u1,
        id: 'only-u1',
        browseMode: 'weapons',
        name: 'Mine',
        now: now,
      );
      expect(await getCatalogFilterCollection(db, u2, 'only-u1'), isNull);
      expect(await deleteCatalogFilterCollection(db, u2, 'only-u1'), isFalse);
    });

    test('core tables include catalog_filter_collections', () async {
      final tables = await db.listUserTableNames();
      expect(tables, contains('catalog_filter_collections'));
    });
  });
}
