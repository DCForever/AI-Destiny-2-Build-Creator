import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
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
        bungieMembershipId: 'm-app-filters',
        membershipType: 3,
      );

  test('create validates then persists; apply returns filters soft-only',
      () async {
    final userId = await seedUser();

    expect(
      () => createCatalogFilterCollectionUseCase(
        db,
        userId: userId,
        name: '',
        browseMode: kCatalogBrowseModeWeapons,
        nowIso: '2026-08-08T00:00:00.000Z',
      ),
      throwsA(isA<CatalogFilterCollectionValidationException>()),
    );

    final created = await createCatalogFilterCollectionUseCase(
      db,
      userId: userId,
      name: 'Void specials',
      browseMode: kCatalogBrowseModeWeapons,
      scope: kCatalogScopeOwned,
      query: 'adept',
      exotic: false,
      elements: const CatalogFacetSelection(include: ['Void']),
      ammos: const CatalogFacetSelection(include: ['Special']),
      sortKeys: const ['slot', 'ammo', 'name'],
      groupBy: const ['element'],
      id: 'fc-app-1',
      nowIso: '2026-08-08T00:00:00.000Z',
    );
    expect(created.id, 'fc-app-1');
    expect(created.elements.include, ['Void']);

    final applied = await applyCatalogFilterCollection(
      db,
      userId: userId,
      id: 'fc-app-1',
    );
    expect(applied!.name, 'Void specials');

    final client = await applyCatalogFilterCollectionAsClientFilters(
      db,
      userId: userId,
      id: 'fc-app-1',
    );
    expect(client, isNotNull);
    expect(client!.scope, CatalogScope.owned);
    expect(client.query, 'adept');
    expect(client.exotic, isFalse);
    final elements = normalizeFacet(client.elements);
    expect(elements.include, ['Void']);
    final ammos = normalizeFacet(client.ammos);
    expect(ammos.include, ['Special']);

    expect(
      catalogSortKeysFromCollection(applied),
      [CatalogSortKey.slot, CatalogSortKey.ammo, CatalogSortKey.name],
    );
    expect(
      catalogGroupByFromCollection(applied),
      [CatalogGroupDimension.element],
    );
  });

  test('rename and delete', () async {
    final userId = await seedUser();
    await createCatalogFilterCollectionUseCase(
      db,
      userId: userId,
      name: 'Old',
      browseMode: kCatalogBrowseModeArmor,
      id: 'r1',
      nowIso: '2026-08-08T00:00:00.000Z',
    );
    final renamed = await renameCatalogFilterCollection(
      db,
      userId: userId,
      id: 'r1',
      name: 'New',
      nowIso: '2026-08-08T01:00:00.000Z',
    );
    expect(renamed!.name, 'New');

    final listed = await listCatalogFilterCollectionsUseCase(
      db,
      userId: userId,
      browseMode: kCatalogBrowseModeArmor,
    );
    expect(listed.single.name, 'New');

    expect(
      await deleteCatalogFilterCollectionUseCase(
        db,
        userId: userId,
        id: 'r1',
      ),
      isTrue,
    );
    expect(
      await getCatalogFilterCollectionUseCase(
        db,
        userId: userId,
        id: 'r1',
      ),
      isNull,
    );
  });

  test('saveCatalogFilterCollection replace-by-name', () async {
    final userId = await seedUser();
    final first = await saveCatalogFilterCollection(
      db,
      CatalogFilterCollection(
        id: 's1',
        userId: '$userId',
        name: 'Preset',
        browseMode: kCatalogBrowseModeUniversal,
        query: 'one',
      ),
      nowIso: '2026-08-08T00:00:00.000Z',
    );
    final second = await saveCatalogFilterCollection(
      db,
      CatalogFilterCollection(
        id: 's2',
        userId: '$userId',
        name: 'Preset',
        browseMode: kCatalogBrowseModeUniversal,
        query: 'two',
        elements: const CatalogFacetSelection(include: ['Arc']),
      ),
      nowIso: '2026-08-08T01:00:00.000Z',
    );
    expect(second.id, first.id);
    expect(second.query, 'two');
    expect(second.elements.include, ['Arc']);
  });
}
