import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_web_host/synergies/synergies_controller.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late SynergiesController controller;

  setUp(() {
    db = AppDatabase.memory();
    controller = SynergiesController(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('create synergy with optional weapon link', () async {
    final err = await controller.createSynergy(
      id: 'syn-1',
      name: 'Melee Loop',
      type: 'melee',
      subType: 'Base',
      links: const [
        SynergyLinkWrite(
          kind: 'weapon',
          displayName: 'Needed Gun',
          itemHash: 777001,
        ),
      ],
    );
    expect(err, isNull);
    expect(controller.synergies, hasLength(1));
    expect(controller.designationOf(controller.selected!), 'melee::Base');
    expect(controller.selected!.links, hasLength(1));
  });
}
