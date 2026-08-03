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
    // Display designation (wire remains melee/Base on the record).
    expect(controller.designationOf(controller.selected!), 'Melee: Base');
    expect(controller.selected!.type, 'melee');
    expect(controller.selected!.subType, 'Base');
    expect(controller.selected!.links, hasLength(1));
  });

  test('required flag toggle round-trips save (pkg-default-three-gates)',
      () async {
    final err = await controller.createSynergy(
      id: 'syn-req',
      name: 'Required Loop',
      type: 'melee',
      links: const [
        SynergyLinkWrite(
          id: 'l1',
          kind: 'weapon',
          displayName: 'Must Pin',
          itemHash: 42,
          required: false,
        ),
      ],
    );
    expect(err, isNull);
    expect(controller.draftLinks.single.required, isFalse);

    controller.setDraftLinkRequired(0, true);
    expect(controller.draftLinks.single.required, isTrue);

    final saveErr = await controller.saveDraftLinks();
    expect(saveErr, isNull);
    expect(controller.selected!.links.single.required, isTrue);
    expect(controller.draftLinks.single.required, isTrue);
  });
}
