import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_bungie/destiny2_bungie.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:destiny2_windows_host/auth/browser_launcher.dart';
import 'package:destiny2_windows_host/auth/token_store.dart';
import 'package:destiny2_windows_host/catalog/owned_catalog_bridge.dart';
import 'package:destiny2_windows_host/host_bootstrap.dart';
import 'package:destiny2_windows_host/sets/set_item_enrichment.dart';
import 'package:destiny2_windows_host/sets/sets_library_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:io';

import 'inventory_sync_test_fakes.dart';

class _FakeRefresh implements ManifestRefreshApi {
  @override
  Future<bool> isStale() async => false;

  @override
  Future<ManifestStatus> refresh({
    bool forceFullDownload = false,
    bool rebuildInIsolate = true,
  }) async =>
      const ManifestStatus(
        cachedVersion: null,
        remoteVersion: null,
        isStale: true,
        entityCache: null,
      );

  @override
  Future<ManifestStatus> status() async =>
      const ManifestStatus(
        cachedVersion: null,
        remoteVersion: null,
        isStale: true,
        entityCache: null,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppServices services;
  late AppDatabase db;
  late SetsLibraryController controller;
  late OwnedCatalogBridge bridge;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dart065_sets_');
    final root = StorageRoot(basePath: tempDir.path);
    await root.ensureLayout();
    db = AppDatabase.memory();
    services = await HostBootstrap.open(
      storageRoot: root,
      database: db,
      manifestRefresh: _FakeRefresh(),
      offlineCatalog: OfflineCatalog.preloaded(
        storageRoot: root,
        items: const [
          CatalogItem(
            hash: 2001,
            name: 'Solar HC',
            slot: 'Kinetic',
            element: 'Solar',
            ammo: 'Primary',
            itemTypeName: 'Hand Cannon',
            frame: 'Precision',
            isExotic: false,
          ),
          CatalogItem(
            hash: 3001,
            name: 'Helmet of Test',
            slot: 'Helmet',
            itemTypeName: 'Helmet',
            isExotic: false,
            sourceStore: 'legendary-armor',
          ),
        ],
        version: 'fixture-065',
      ),
      clientId: 'test-client',
      tokenStore: MemoryTokenStore(),
      browserLauncher: FakeBrowserLauncher(),
      profileClient: FakeProfileClient(),
      oauthClient: BungieOAuthClient(
        clientId: 'test-client',
        redirectUri: kDefaultWindowsRedirectUri,
        transport: (_) async => throw StateError('unused'),
      ),
    );
    controller = SetsLibraryController(
      db: db,
      session: services.oauthSession,
      inventorySync: services.inventorySync,
    );
    bridge = OwnedCatalogBridge(
      db: db,
      offlineCatalog: services.offlineCatalog,
      session: services.oauthSession,
      inventorySync: services.inventorySync,
      plugNameByHash: const {20: 'Kill Clip'},
    );
  });

  tearDown(() async {
    controller.dispose();
    await services.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('fillSlot persists selectedPerks (GAP-UI-SETS-10)', () async {
    await controller.refresh();
    final err = await controller.createSet(
      name: 'Weapons',
      type: SetType.weapon,
    );
    expect(err, isNull);

    final fill = await controller.fillSlot(
      'primary',
      const SetSlotPickResult(
        itemHash: 2001,
        itemName: 'Solar HC',
        instanceId: 'inst-1',
        selectedPerks: [20, 30],
      ),
    );
    expect(fill, isNull);
    final item = controller.selected!.activeItems.single;
    expect(item.selectedPerks, [20, 30]);
    expect(item.instanceId, 'inst-1');
  });

  test('needsReplaceConfirm when slot occupied (GAP-UI-SETS-07)', () async {
    await controller.refresh();
    await controller.createSet(name: 'W', type: SetType.weapon);
    expect(controller.needsReplaceConfirm('primary'), isFalse);
    await controller.fillSlot(
      'primary',
      const SetSlotPickResult(itemHash: 1, itemName: 'Old Gun'),
    );
    expect(controller.needsReplaceConfirm('primary'), isTrue);
    expect(controller.occupantForSlot('primary')?.itemName, 'Old Gun');
  });

  test('rejects second exotic weapon with plain-language reason (BR-SLOT-008)',
      () async {
    await controller.refresh();
    await controller.createSet(name: 'Weapons', type: SetType.weapon);
    final first = await controller.fillSlot(
      'primary',
      const SetSlotPickResult(
        itemHash: 1001,
        itemName: 'Witherhoard',
        isExotic: true,
        equipmentSlot: 'Kinetic',
        catalogKind: 'weapons',
      ),
    );
    expect(first, isNull);

    final known = {
      1001: setItemMetaFromCatalog(
        kind: 'weapons',
        slot: 'Kinetic',
        isExotic: true,
        name: 'Witherhoard',
      ),
    };
    final second = await controller.fillSlot(
      'heavy',
      const SetSlotPickResult(
        itemHash: 1002,
        itemName: 'Gjallarhorn',
        isExotic: true,
        equipmentSlot: 'Power',
        catalogKind: 'weapons',
      ),
      knownItemMeta: known,
    );
    expect(second, isNotNull);
    expect(second, matches(RegExp('exotic|Witherhoard', caseSensitive: false)));
    expect(controller.selected!.activeItems, hasLength(1));
  });

  test('enrich armor board totals from inventory (GAP-UI-SETS-01)', () async {
    await controller.refresh();
    final uid = controller.userId!;
    await replaceInventoryBatch(
      db,
      uid,
      now: '2026-07-25T00:00:00.000Z',
      items: const [
        InventoryItemRecord(
          instanceId: 'helm-1',
          itemHash: 3001,
          bucket: 'Helmet',
          location: 'vault',
          power: 1800,
          statValues: {
            'Health': 20,
            'Melee': 10,
            'Grenade': 10,
            'Super': 10,
            'Class': 10,
            'Weapons': 10,
          },
          syncedAt: '2026-07-25T00:00:00.000Z',
        ),
      ],
    );

    await controller.createSet(name: 'Armor', type: SetType.armor);
    await controller.fillSlot(
      'helmet',
      const SetSlotPickResult(
        itemHash: 3001,
        itemName: 'Helmet of Test',
        instanceId: 'helm-1',
      ),
    );

    final presentation = await enrichSetDetailPresentation(
      detail: controller.selected!,
      bridge: bridge,
      boardSlots: const ['helmet', 'arms', 'chest', 'legs', 'class_item'],
      userId: controller.userId,
    );
    expect(presentation.armorTotals, isNotNull);
    expect(presentation.armorTotals!.statValues['Health'], 20);
    expect(presentation.armorTotals!.grandTotal, 70);
    expect(presentation.rowsBySlot['helmet']?.metaChips, contains('Instance'));
  });

  test('wishlist armor marks stats unknown', () async {
    await controller.refresh();
    await controller.createSet(name: 'Armor2', type: SetType.armor);
    await controller.fillSlot(
      'helmet',
      const SetSlotPickResult(
        itemHash: 3001,
        itemName: 'Helmet of Test',
      ),
    );
    final presentation = await enrichSetDetailPresentation(
      detail: controller.selected!,
      bridge: bridge,
      boardSlots: const ['helmet'],
      userId: controller.userId,
    );
    expect(presentation.rowsBySlot['helmet']?.statsUnknown, isTrue);
  });

  test('prefers armor_stats plug base roll over live ItemStats (BR-SET-011)',
      () async {
    await controller.refresh();
    final uid = controller.userId!;
    await replaceInventoryBatch(
      db,
      uid,
      now: '2026-07-25T00:00:00.000Z',
      items: const [
        InventoryItemRecord(
          instanceId: 'helm-plug',
          itemHash: 3001,
          bucket: 'Helmet',
          location: 'vault',
          power: 1800,
          plugHashes: [11, 12, 99],
          // Live ItemStats include mod investments (should be ignored).
          statValues: {
            'Health': 99,
            'Melee': 99,
            'Grenade': 99,
            'Super': 99,
            'Class': 99,
            'Weapons': 99,
          },
          syncedAt: '2026-07-25T00:00:00.000Z',
        ),
      ],
    );

    await controller.createSet(name: 'Armor plug roll', type: SetType.armor);
    await controller.fillSlot(
      'helmet',
      const SetSlotPickResult(
        itemHash: 3001,
        itemName: 'Helmet of Test',
        instanceId: 'helm-plug',
      ),
    );

    final resolve = plugStatResolverFromMap({
      11: const PlugStatSource(
        plugCategoryIdentifier: 'armor_stats',
        investmentStats: [
          PlugInvestmentStat(statTypeHash: 392767087, value: 20), // Health
          PlugInvestmentStat(statTypeHash: 1735777505, value: 30), // Grenade
        ],
      ),
      12: const PlugStatSource(
        plugCategoryIdentifier: 'armor_stats',
        investmentStats: [
          PlugInvestmentStat(statTypeHash: 144602215, value: 25), // Super
        ],
      ),
      99: const PlugStatSource(
        plugCategoryIdentifier: 'enhancements.v2_general',
        investmentStats: [
          PlugInvestmentStat(statTypeHash: 1735777505, value: 10),
        ],
      ),
    });

    final presentation = await enrichSetDetailPresentation(
      detail: controller.selected!,
      bridge: bridge,
      boardSlots: const ['helmet', 'arms', 'chest', 'legs', 'class_item'],
      userId: controller.userId,
      resolvePlug: resolve,
    );
    final board = presentation.rowsBySlot['helmet']?.armorStats;
    expect(board, isNotNull);
    expect(board!.stats['Health'], 20);
    expect(board.stats['Grenade'], 30);
    expect(board.stats['Super'], 25);
    expect(board.stats['Melee'], 0);
    // Not the live 99s.
    expect(board.total, 75);
    expect(presentation.armorTotals?.statValues['Grenade'], 30);
  });
}
