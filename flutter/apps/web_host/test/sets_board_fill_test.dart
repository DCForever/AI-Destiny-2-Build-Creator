import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_web_host/auth/token_store.dart';
import 'package:destiny2_web_host/catalog/owned_catalog_bridge.dart';
import 'package:destiny2_web_host/sets/sets_controller.dart';
import 'package:test/test.dart';

import 'inventory_sync_test_fakes.dart';

void main() {
  late AppDatabase db;
  late SetsController controller;

  setUp(() {
    db = AppDatabase.memory();
    controller = SetsController(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('fillSlot persists selectedPerks (GAP-UI-SETS-10)', () async {
    await controller.createSet(
      name: 'Kinetic Core',
      type: SetType.weapon,
      id: 'set-w',
    );
    final err = await controller.fillSlot(
      'primary',
      const SetSlotPickResult(
        itemHash: 42,
        itemName: 'My Kinetic',
        instanceId: 'i-1',
        selectedPerks: [7, 8],
      ),
    );
    expect(err, isNull);
    expect(controller.selected!.activeItems.single.selectedPerks, [7, 8]);
  });

  test('needsReplaceConfirm when occupied (GAP-UI-SETS-07)', () async {
    await controller.createSet(
      name: 'W',
      type: SetType.weapon,
      id: 'set-r',
    );
    expect(controller.needsReplaceConfirm('primary'), isFalse);
    await controller.fillSlot(
      'primary',
      const SetSlotPickResult(itemHash: 1, itemName: 'Old'),
    );
    expect(controller.needsReplaceConfirm('primary'), isTrue);
    expect(controller.occupantForSlot('primary')?.itemName, 'Old');
  });

  test('catalog bridge provides named items for fill density (GAP-UI-SETS-03)',
      () async {
    final store = MemoryTokenStore();
    final session = buildSignedInSession(store: store);
    await session.restore();
    final bridge = OwnedCatalogBridge(
      db: db,
      session: session,
      baseItems: const [
        CatalogItem(
          hash: 100,
          name: 'Named Hand Cannon',
          slot: 'Kinetic',
          element: 'Solar',
          itemTypeName: 'Hand Cannon',
          isExotic: false,
        ),
      ],
    );
    await bridge.refresh(reloadEntities: false);
    final hits = bridge.browse(const CatalogClientFilters());
    expect(hits, hasLength(1));
    expect(hits.single.name, 'Named Hand Cannon');
    expect(selectedPerksFromInstance(null), isEmpty);
  });
}
