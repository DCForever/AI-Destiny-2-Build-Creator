import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_web_host/auth/token_store.dart';
import 'package:destiny2_web_host/catalog/owned_catalog_bridge.dart';
import 'package:destiny2_web_host/pages/catalog_page.dart';
import 'package:destiny2_web_host/settings/inventory_sync_controller.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:test/test.dart';

import 'inventory_sync_test_fakes.dart';

void main() {
  late AppDatabase db;

  final fixtures = [
    const CatalogItem(
      hash: 100,
      name: 'Owned Kinetic',
      slot: 'Kinetic',
      element: 'Kinetic',
      ammo: 'Primary',
      isExotic: false,
    ),
    const CatalogItem(
      hash: 300,
      name: 'Unowned Exotic',
      slot: 'Energy',
      element: 'Solar',
      ammo: 'Special',
      isExotic: true,
    ),
  ];

  setUp(() async {
    db = AppDatabase.memory();
    defaultInventoryBusyLock.clearForTests();
  });

  tearDown(() async {
    defaultInventoryBusyLock.clearForTests();
    await db.close();
  });

  Future<OwnedCatalogBridge> seededBridge() async {
    final store = MemoryTokenStore();
    await seedSignedIn(store);
    final session = buildSignedInSession(store: store);
    await session.restore();
    final controller = InventorySyncController(
      db: db,
      session: session,
      profileClient: FakeProfileClient(),
    );
    await controller.refreshStatus();
    final userId = controller.localUserId!;
    await replaceInventoryBatch(
      db,
      userId,
      now: '2026-07-24T12:00:00.000Z',
      items: const [
        InventoryItemRecord(
          instanceId: 'inst-high',
          itemHash: 100,
          bucket: 'Kinetic',
          location: 'vault',
          power: 1810,
          isMasterwork: false,
          isCrafted: false,
          plugHashes: [],
          rollTags: [],
          syncedAt: '2026-07-24T12:00:00.000Z',
        ),
        InventoryItemRecord(
          instanceId: 'inst-low',
          itemHash: 100,
          bucket: 'Kinetic',
          location: 'character',
          characterId: 'c1',
          power: 1800,
          isMasterwork: true,
          isCrafted: false,
          plugHashes: [],
          rollTags: ['Crafted'],
          syncedAt: '2026-07-24T12:00:00.000Z',
        ),
      ],
    );
    return OwnedCatalogBridge(
      db: db,
      session: session,
      inventorySync: controller,
      baseItems: fixtures,
    );
  }

  group('OwnedCatalogBridge (DART-056)', () {
    test('annotates owned counts and projects instances power-desc', () async {
      final bridge = await seededBridge();
      await bridge.refresh(reloadEntities: false);

      expect(bridge.ownedCounts[100], 2);
      expect(bridge.ownedCounts.containsKey(300), isFalse);

      final all = bridge.browse(const CatalogClientFilters());
      expect(all.map((e) => e.hash), containsAll([100, 300]));
      expect(all.where((e) => e.hash == 100).single.ownedCount, 2);

      final owned = bridge.browse(
        const CatalogClientFilters(scope: CatalogScope.owned),
      );
      expect(owned.map((e) => e.hash).toList(), [100]);

      final instances = bridge.instancesFor(100);
      expect(instances, hasLength(2));
      expect(instances.first.instanceId, 'inst-high');
      expect(instances.first.power, 1810);
      expect(instances.last.instanceId, 'inst-low');
    });
  });

  group('CatalogPage Owned (DART-056)', () {
    testComponents('All scope shows owned and unowned; owned badge',
        (tester) async {
      final bridge = await seededBridge();
      await bridge.refresh(reloadEntities: false);

      tester.pumpComponent(
        CatalogPage(
          initialItems: fixtures,
          initialVersion: 'fixture-owned-1',
          bridge: bridge,
        ),
      );
      await tester.pump();

      expect(find.text('Owned Kinetic'), findsOneComponent);
      expect(find.text('Unowned Exotic'), findsOneComponent);
      expect(find.textContaining('×2'), findsComponents);
      expect(find.textContaining('scope=all'), findsOneComponent);
    });

    testComponents('Owned scope filters to owned only', (tester) async {
      final bridge = await seededBridge();
      await bridge.refresh(reloadEntities: false);

      tester.pumpComponent(
        CatalogPage(
          initialItems: fixtures,
          initialVersion: 'fixture-owned-1',
          bridge: bridge,
        ),
      );
      await tester.pump();

      await tester.click(find.byKey(const ValueKey('scope-chip-owned')));
      await tester.pump();

      expect(find.text('Owned Kinetic'), findsOneComponent);
      expect(find.text('Unowned Exotic'), findsNothing);
      expect(find.textContaining('scope=owned'), findsOneComponent);
    });

    testComponents('select owned row shows instance ids power-desc',
        (tester) async {
      final bridge = await seededBridge();
      await bridge.refresh(reloadEntities: false);

      tester.pumpComponent(
        CatalogPage(
          initialItems: fixtures,
          initialVersion: 'fixture-owned-1',
          bridge: bridge,
        ),
      );
      await tester.pump();

      await tester.click(find.byKey(const ValueKey('catalog-row-100')));
      await tester.pump();

      expect(find.textContaining('Owned instances'), findsOneComponent);
      expect(find.text('inst-high'), findsOneComponent);
      expect(find.text('inst-low'), findsOneComponent);
      expect(find.textContaining('power 1810'), findsOneComponent);
      expect(find.textContaining('equip/DIM'), findsComponents);
    });
  });
}
