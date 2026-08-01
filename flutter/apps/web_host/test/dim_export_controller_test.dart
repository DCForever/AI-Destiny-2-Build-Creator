import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart'
    hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_web_host/builds/builds_controller.dart';
import 'package:destiny2_web_host/dim_export/dim_export_controller.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late BuildsController builds;
  late List<String> clipboard;
  late DimExportController dim;

  setUp(() async {
    db = AppDatabase.memory();
    builds = BuildsController(db: db);
    clipboard = <String>[];
    dim = DimExportController(
      db: db,
      clipboardWriter: (text) async {
        clipboard.add(text);
      },
      loadoutIdFactory: () => 'fixed-loadout-id',
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedWeaponSet(
    int userId,
    String setId,
    String slot,
    int hash, {
    String? instanceId,
  }) async {
    await createUserSet(
      db,
      userId,
      CreateSetCommand(id: setId, name: 'Set $setId', type: SetType.weapon),
    );
    await upsertUserSetItem(
      db,
      userId,
      setId,
      UpsertSetItemCommand(
        id: '$setId-item',
        slot: slot,
        itemHash: hash,
        itemName: 'Item $hash',
        instanceId: instanceId,
      ),
    );
  }

  Future<void> seedInventory(
    int userId, {
    required String instanceId,
    required int itemHash,
  }) async {
    await replaceInventoryBatch(
      db,
      userId,
      items: [
        InventoryItemRecord(
          instanceId: instanceId,
          itemHash: itemHash,
          bucket: 'Kinetic',
          location: 'vault',
          syncedAt: '2026-07-25T12:00:00.000Z',
        ),
      ],
      now: '2026-07-25T12:00:00.000Z',
    );
  }

  Future<({int userId, String buildId, String variantId})> seedCompose({
    String? instanceId,
  }) async {
    final uid = await builds.resolveLibraryUserId();
    await seedWeaponSet(
      uid,
      'set-dim',
      'primary',
      100,
      instanceId: instanceId,
    );
    await builds.createBuild(
      name: 'DIM Build',
      className: GuardianClass.hunter,
      synergyTypes: const [DraftSynergyType(type: 'melee')],
    );
    final createVar = await builds.createVariant(name: 'Alt');
    expect(createVar, isNull);
    final attach = await builds.attachSet('set-dim');
    expect(attach, isNull);
    final buildId = builds.selected!.build.id;
    final variantId = builds.selectedVariant!.id;
    return (userId: uid, buildId: buildId, variantId: variantId);
  }

  test('US1 wishlist not equip-ready blocks export (no clipboard)', () async {
    final seed = await seedCompose(); // wishlist (no instance)
    await dim.bind(
      userId: seed.userId,
      buildId: seed.buildId,
      variantId: seed.variantId,
    );

    expect(dim.equipReady, isFalse);
    expect(dim.canExport, isFalse);

    final err = await dim.requestExport();
    expect(err, isNotNull);
    expect(err!.toLowerCase(), contains('equip-ready'));
    expect(clipboard, isEmpty);
    expect(dim.clipboardWrites, 0);
  });

  test('US2 owned pin equip-ready exports jsonOnly to clipboard', () async {
    final seed = await seedCompose(instanceId: 'inst-primary');
    await seedInventory(
      seed.userId,
      instanceId: 'inst-primary',
      itemHash: 100,
    );

    await dim.bind(
      userId: seed.userId,
      buildId: seed.buildId,
      variantId: seed.variantId,
    );

    expect(dim.equipReady, isTrue, reason: dim.error);
    expect(dim.canExport, isTrue);

    final err = await dim.requestExport();
    expect(err, isNull, reason: dim.error);
    expect(clipboard, hasLength(1));
    expect(dim.clipboardWrites, 1);
    expect(dim.statusMessage, contains('Copied'));
    expect(clipboard.single, contains('"loadout"'));
    expect(clipboard.single, contains('100'));
    expect(clipboard.single, contains('inst-primary'));
    expect(clipboard.single, contains('fixed-loadout-id'));
  });

  test('export does not mutate soft targets or pins', () async {
    final seed = await seedCompose(instanceId: 'inst-primary');
    await seedInventory(
      seed.userId,
      instanceId: 'inst-primary',
      itemHash: 100,
    );
    await builds.saveSoftStatTargetsFromFields({'Health': '100'});

    await dim.bind(
      userId: seed.userId,
      buildId: seed.buildId,
      variantId: seed.variantId,
    );
    await dim.requestExport();

    final detail = await getBuildDetail(db, seed.userId, seed.buildId);
    expect(detail, isNotNull);
    final soft = softStatTargetsFromJson(detail!.build.softStatTargets);
    expect(soft.values[ArmorStatName.health], 100);

    final pins = builds.slotPins;
    expect(pins, isNotEmpty);
    expect(pins.first.instanceId, 'inst-primary');
  });
}
