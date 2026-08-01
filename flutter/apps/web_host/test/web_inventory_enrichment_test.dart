import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_web_host/auth/token_store.dart';
import 'package:destiny2_web_host/catalog/owned_catalog_bridge.dart';
import 'package:destiny2_web_host/equip/roll_tag_lookup_provider.dart';
import 'package:destiny2_web_host/equip/weapon_socket_context_provider.dart';
import 'package:destiny2_web_host/settings/inventory_sync_controller.dart';
import 'package:test/test.dart';

import 'inventory_sync_test_fakes.dart';

void main() {
  late AppDatabase db;
  late InventoryBusyLock lock;
  late MemoryTokenStore store;

  setUp(() async {
    db = AppDatabase.memory();
    lock = InventoryBusyLock();
    defaultInventoryBusyLock.clearForTests();
    store = MemoryTokenStore();
    await seedSignedIn(store);
  });

  tearDown(() async {
    defaultInventoryBusyLock.clearForTests();
    await db.close();
  });

  group('GAP-INV-02 web roll tags', () {
    test('catalog-seeded perk names produce OrbitBuild tags', () async {
      final catalog = OfflineCatalog.preloaded(
        items: [
          const CatalogItem(
            hash: 3,
            name: 'Demolitionist',
            isExotic: false,
            sourceStore: 'mods',
          ),
          const CatalogItem(
            hash: 4,
            name: 'Adrenaline Junkie',
            isExotic: false,
            sourceStore: 'mods',
          ),
          const CatalogItem(
            hash: 300,
            name: 'Test Hand Cannon',
            isExotic: false,
            frame: 'Adaptive Frame',
            itemTypeName: 'Hand Cannon',
            sourceStore: 'weapons',
          ),
        ],
        version: 'test',
      );
      final tags = createWebRollTagEnrichment(offlineCatalog: catalog);
      final session = buildSignedInSession(store: store);
      await session.restore();
      final profile = FakeProfileClient(
        items: const [
          RawInventoryItem(
            instanceId: 'orbit-gun',
            itemHash: 300,
            bucketHash: 2465295065,
            location: 'vault',
            power: 1800,
            plugHashes: [3, 4],
          ),
        ],
      );

      final controller = InventorySyncController(
        db: db,
        session: session,
        profileClient: profile,
        lock: lock,
        clock: () => DateTime.utc(2026, 7, 24, 12),
        perkNameMapBuilder: tags.perkNameMapBuilder,
        weaponRollMetaLookupBuilder: tags.weaponRollMetaLookupBuilder,
      );

      await controller.syncNow();
      expect(controller.phase, InventorySyncPhase.idle);
      final items = await listInventoryItems(db, controller.localUserId!);
      expect(items, hasLength(1));
      expect(items.single.rollTags, contains(RollTags.orbitBuild));
    });

    test('extraPerkNames injects residual champion perk names', () async {
      final catalog = OfflineCatalog.preloaded(
        items: const [
          CatalogItem(
            hash: 400,
            name: 'Scout',
            isExotic: false,
            frame: 'Lightweight Frame',
            itemTypeName: 'Scout Rifle',
          ),
        ],
        version: 'test',
      );
      final tags = createWebRollTagEnrichment(
        offlineCatalog: catalog,
        extraPerkNames: const {5: 'Anti-Barrier Rounds'},
      );
      final session = buildSignedInSession(store: store);
      await session.restore();
      final profile = FakeProfileClient(
        items: const [
          RawInventoryItem(
            instanceId: 'champ-gun',
            itemHash: 400,
            bucketHash: 1498876634,
            location: 'vault',
            power: 1800,
            plugHashes: [5],
          ),
        ],
      );

      final controller = InventorySyncController(
        db: db,
        session: session,
        profileClient: profile,
        lock: lock,
        clock: () => DateTime.utc(2026, 7, 24, 12),
        perkNameMapBuilder: tags.perkNameMapBuilder,
        weaponRollMetaLookupBuilder: tags.weaponRollMetaLookupBuilder,
      );

      await controller.syncNow();
      final items = await listInventoryItems(db, controller.localUserId!);
      expect(items.single.rollTags, contains(RollTags.championBarrier));
    });
  });

  group('GAP-INV-03 web socket enrichment', () {
    test('stores columnKind/columnLabel when context maps supplied', () async {
      final socket = createWebWeaponSocketEnrichment(
        plugCategoryByHash: const {
          101: 'barrels.2',
          201: 'magazines.2',
          301: 'traits.2',
        },
        weaponPerkIndexesByItem: const {
          500: [0, 1, 2],
        },
      );
      final session = buildSignedInSession(store: store);
      await session.restore();
      final profile = FakeProfileClient(
        items: const [
          RawInventoryItem(
            instanceId: 'perk-gun',
            itemHash: 500,
            bucketHash: 1498876634,
            location: 'character',
            characterId: 'c1',
            power: 1810,
            plugHashes: [101, 201, 301],
            socketCapture: [
              RawSocketCapture(
                socketIndex: 0,
                equippedPlugHash: 101,
                reusablePlugHashes: [101, 102],
              ),
              RawSocketCapture(
                socketIndex: 1,
                equippedPlugHash: 201,
                reusablePlugHashes: [201],
              ),
              RawSocketCapture(
                socketIndex: 2,
                equippedPlugHash: 301,
                reusablePlugHashes: [301],
              ),
            ],
          ),
        ],
      );

      final controller = InventorySyncController(
        db: db,
        session: session,
        profileClient: profile,
        lock: lock,
        clock: () => DateTime.utc(2026, 7, 24, 12),
        weaponSocketContextBuilder: socket.weaponSocketContextBuilder,
      );

      await controller.syncNow();
      final items = await listInventoryItems(db, controller.localUserId!);
      final plugs = items.single.socketPlugs;
      expect(plugs, isNotNull);
      expect(plugs!.length, greaterThanOrEqualTo(3));
      expect(plugs[0]['columnKind'], 'barrel');
      expect(plugs[0]['columnLabel'], 'Barrel');
      expect(plugs[1]['columnKind'], 'magazine');
      expect(plugs[2]['columnKind'], 'trait');
    });
  });

  group('GAP-UI-CATALOG-08 owned detail names', () {
    test('instancesForResolved shows names not raw #hash when plugs known',
        () async {
      final session = buildSignedInSession(store: store);
      await session.restore();
      final user = await ensureUser(
        db,
        bungieMembershipId: 'bungie-net-99',
        membershipType: 0,
        displayName: '',
      );
      await replaceInventoryBatch(
        db,
        user.id,
        now: '2026-07-24T12:00:00.000Z',
        items: const [
          InventoryItemRecord(
            instanceId: 'i1',
            itemHash: 100,
            bucket: 'Kinetic',
            location: 'vault',
            power: 1800,
            plugHashes: [20],
            socketPlugs: [
              {
                'socketIndex': 0,
                'equippedPlugHash': 20,
                'reusablePlugHashes': [20],
                'columnKind': 'trait',
                'columnLabel': 'Trait 1',
              },
            ],
            syncedAt: '2026-07-24T12:00:00.000Z',
          ),
        ],
      );

      final bridge = OwnedCatalogBridge(
        db: db,
        session: session,
        baseItems: const [
          CatalogItem(hash: 100, name: 'Gun', isExotic: false),
          CatalogItem(hash: 20, name: 'Kill Clip', isExotic: false),
        ],
        plugNameByHash: const {20: 'Kill Clip'},
      );
      await bridge.refresh(reloadEntities: false);
      final instances = await bridge.instancesForResolved(100);
      expect(instances, hasLength(1));
      final cards = instances.single.plugCards;
      expect(cards, isNotEmpty);
      expect(cards.single.displayName, 'Kill Clip');
      expect(cards.single.resolved, isTrue);
    });
  });
}
