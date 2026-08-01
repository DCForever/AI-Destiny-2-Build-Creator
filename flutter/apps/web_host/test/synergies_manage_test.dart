import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_manifest/destiny2_manifest.dart';
import 'package:destiny2_web_host/synergies/synergies_controller.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late SynergiesController controller;

  setUp(() {
    db = AppDatabase.memory();
    controller = SynergiesController(
      db: db,
      catalogItems: const [
        CatalogItem(
          hash: 100,
          name: 'Lodestar',
          isExotic: true,
          slot: 'Energy',
          ammo: 'Special',
          sourceStore: 'exotic-weapons',
        ),
        CatalogItem(
          hash: 200,
          name: 'Other Gun',
          isExotic: false,
          slot: 'Kinetic',
          ammo: 'Primary',
          sourceStore: 'weapons',
        ),
      ],
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('select opens detail and can edit links + delete', () async {
    final err = await controller.createSynergy(
      id: 'syn-1',
      name: 'Melee Loop',
      type: 'melee',
      subType: 'Base',
    );
    expect(err, isNull);
    await controller.selectSynergy('syn-1');
    expect(controller.selected?.name, 'Melee Loop');

    final hits = controller.searchEvidence(linkKind: 'weapon', query: 'Lode');
    expect(hits, isNotEmpty);
    expect(controller.addPickerHitToDraft(hits.first), isNull);
    expect(controller.draftLinks, hasLength(1));

    // BR-SYN-011 omit already linked
    final again = controller.searchEvidence(linkKind: 'weapon', query: 'Lode');
    expect(again.any((h) => h.hash == 100), isFalse);

    final save = await controller.saveDraftLinks();
    expect(save, isNull);
    expect(controller.selected!.links, hasLength(1));

    final idErr = await controller.updateSelectedIdentity(
      name: 'Melee Loop 2',
      description: 'notes',
    );
    expect(idErr, isNull);
    expect(controller.selected!.name, 'Melee Loop 2');

    final del = await controller.deleteSelected();
    expect(del, isNull);
    expect(controller.selected, isNull);
    expect(controller.synergies, isEmpty);
  });

  test('library search and type filters', () async {
    await controller.createSynergy(
      id: 's1',
      name: 'Hammer Strike',
      type: 'melee',
    );
    await controller.createSynergy(
      id: 's2',
      name: 'Grenade Spam',
      type: 'grenade',
    );
    controller.setSearchQuery('hammer');
    expect(controller.synergies.map((s) => s.id), ['s1']);
    controller.setSearchQuery('');
    controller.toggleTypeFacet('grenade');
    expect(controller.synergies.map((s) => s.id), ['s2']);
  });
}
