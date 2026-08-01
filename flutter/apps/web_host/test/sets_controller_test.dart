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

  test('create set and fill slot', () async {
    final err = await controller.createSet(
      name: 'Kinetic Core',
      type: SetType.weapon,
      id: 'set-kinetic',
    );
    expect(err, isNull);
    expect(controller.sets, hasLength(1));
    expect(controller.selected?.set.name, 'Kinetic Core');

    final fill = await controller.fillSlot(
      'primary',
      const SetSlotPickResult(itemHash: 42, itemName: 'My Kinetic'),
    );
    expect(fill, isNull);
    expect(controller.selected?.activeItems, hasLength(1));
    expect(controller.selected!.activeItems.single.itemHash, 42);
    expect(controller.selected!.activeItems.single.slot, 'primary');
  });
}
