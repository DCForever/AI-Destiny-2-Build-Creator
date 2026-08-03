import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_web_host/sets/sets_controller.dart';
import 'package:test/test.dart';

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

  test('search + type filters and readiness fill next', () async {
    await controller.createSet(
      name: 'Kinetic Core',
      type: SetType.weapon,
      id: 'set-w',
    );
    await controller.createSet(
      name: 'Void Armor',
      type: SetType.armor,
      id: 'set-a',
    );

    controller.setSearchQuery('void');
    expect(controller.sets.map((s) => s.id), ['set-a']);
    controller.setSearchQuery('');
    controller.setTypeFilter(SetType.weapon);
    expect(controller.sets.map((s) => s.id), ['set-w']);

    await controller.selectSet('set-w');
    final readiness = controller.readinessOfSelected()!;
    expect(readiness.filled, 0);
    expect(readiness.capacity, 3);
    expect(readiness.nextEmptySlot, 'primary');

    await controller.fillSlot(
      'primary',
      const SetSlotPickResult(itemHash: 1, itemName: 'Gun'),
    );
    final next = controller.readinessOfSelected()!;
    expect(next.filled, 1);
    expect(next.nextEmptySlot, 'special');
    // Under occupancy floor (DBR-CMP-008): package-min badge, not "filled".
    expect(next.badgeLabel, contains('1/3'));
    expect(next.badgeLabel, contains('need 2+'));
  });

  test('delete unused set; SET_IN_USE when attached', () async {
    await controller.createSet(
      name: 'Free Set',
      type: SetType.weapon,
      id: 'free',
    );
    await controller.selectSet('free');
    expect(await controller.deleteSelected(), isNull);
    expect(controller.sets, isEmpty);

    await controller.createSet(
      name: 'Used Set',
      type: SetType.weapon,
      id: 'used',
    );
    final uid = controller.userId!;
    const now = '2026-01-01T00:00:00.000Z';
    await createBuildRecord(
      db,
      uid,
      id: 'b1',
      name: 'Build',
      className: 'Titan',
      now: now,
    );
    await createVariantRecord(
      db,
      id: 'v1',
      buildId: 'b1',
      name: 'Default',
      isDefault: true,
      now: now,
    );
    await replaceAttachments(
      db,
      'v1',
      const [AttachmentWrite(id: 'att-1', setId: 'used', mode: 'live')],
      now,
    );

    await controller.selectSet('used');
    final err = await controller.deleteSelected();
    expect(err, isNotNull);
    expect(err!, contains('SET_IN_USE'));
    expect(controller.selected?.set.id, 'used');
  });
}
