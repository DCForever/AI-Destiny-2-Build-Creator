import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart' hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  const now = '2026-07-24T12:00:00.000Z';
  final clock = fixedNow(now);
  final ids = sequentialIds('opt');

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedUser() => insertUser(
        db,
        bungieMembershipId: 'm-opt',
        membershipType: 3,
        displayName: 'Optimizer',
      );

  List<MaterializePiece> fivePieces({String suffix = ''}) {
    return [
      MaterializePiece(
        slot: EquipmentSlot.helmet,
        itemHash: 101,
        instanceId: 'inst-h$suffix',
      ),
      MaterializePiece(
        slot: EquipmentSlot.arms,
        itemHash: 102,
        instanceId: 'inst-a$suffix',
      ),
      MaterializePiece(
        slot: EquipmentSlot.chest,
        itemHash: 103,
        instanceId: 'inst-c$suffix',
      ),
      MaterializePiece(
        slot: EquipmentSlot.legs,
        itemHash: 104,
        instanceId: 'inst-l$suffix',
      ),
      MaterializePiece(
        slot: EquipmentSlot.classItem,
        itemHash: 105,
        instanceId: 'inst-ci$suffix',
      ),
    ];
  }

  group('US3 materialize confirm-only', () {
    test('materialize creates armor set with five items', () async {
      final userId = await seedUser();
      final result = await materializeArmorCombination(
        db,
        userId,
        MaterializeArmorCommand(
          id: 'armor-opt-1',
          armorSetName: 'Optimized Kit',
          pieces: fivePieces(),
          optimizerConstraintsJson: '{"preferReuse":false}',
        ),
        now: clock,
        newId: ids,
      );

      expect(result.armorSet.set.id, 'armor-opt-1');
      expect(result.armorSet.set.type, 'armor');
      expect(result.armorSet.set.name, 'Optimized Kit');
      expect(result.armorSet.set.optimizerConstraints, '{"preferReuse":false}');
      expect(result.armorSet.activeItems, hasLength(5));
      final slots =
          result.armorSet.activeItems.map((i) => i.slot).toSet();
      expect(slots, {
        'helmet',
        'arms',
        'chest',
        'legs',
        'class_item',
      });
    });

    test('incomplete pieces hard-block with no write', () async {
      final userId = await seedUser();
      expect(
        () => materializeArmorCombination(
          db,
          userId,
          const MaterializeArmorCommand(
            armorSetName: 'Bad',
            pieces: [
              MaterializePiece(
                slot: EquipmentSlot.helmet,
                itemHash: 1,
                instanceId: 'h',
              ),
            ],
          ),
          now: clock,
          newId: ids,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.invalidCombination,
          ),
        ),
      );
      final listed = await listUserSets(db, userId, type: SetType.armor);
      expect(listed, isEmpty);
    });

    test('optimize alone does not create sets (confirm-only)', () async {
      final userId = await seedUser();
      final before = await listUserSets(db, userId, type: SetType.armor);

      final candidates = [
        for (final slot in armorOptimizerSlots)
          CandidatePiece(
            slot: slot,
            itemHash: 1,
            instanceId: slot.wireName,
            isExotic: false,
            statValues: const {
              ArmorStatName.health: 10,
              ArmorStatName.melee: 10,
              ArmorStatName.grenade: 10,
              ArmorStatName.superStat: 10,
              ArmorStatName.classStat: 10,
              ArmorStatName.weapons: 10,
            },
          ),
      ];
      final response = optimizeArmorLocal(
        ArmorOptimizeRequest(candidates: candidates),
      );
      expect(response.combinations, isNotEmpty);

      final after = await listUserSets(db, userId, type: SetType.armor);
      expect(after.length, before.length);
    });

    test('ownership validation blocks unowned instance', () async {
      final userId = await seedUser();
      final ownership = <String, OwnedInstanceRef>{
        'inst-h': const OwnedInstanceRef(itemHash: 101, isExotic: false),
        // missing other instances
      };
      expect(
        () => materializeArmorCombination(
          db,
          userId,
          MaterializeArmorCommand(
            armorSetName: 'Owned check',
            pieces: fivePieces(),
          ),
          ownership: ownership,
          now: clock,
          newId: ids,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.instanceNotOwned,
          ),
        ),
      );
    });
  });

  group('US4 apply in place', () {
    test('updates existing armor set items same id', () async {
      final userId = await seedUser();
      final created = await materializeArmorCombination(
        db,
        userId,
        MaterializeArmorCommand(
          id: 'armor-existing',
          armorSetName: 'Base Kit',
          pieces: fivePieces(suffix: '-a'),
        ),
        now: clock,
        newId: ids,
      );
      expect(created.armorSet.activeItems, hasLength(5));

      final applied = await applyArmorCombinationInPlace(
        db,
        userId,
        ApplyArmorCombinationCommand(
          setId: 'armor-existing',
          pieces: fivePieces(suffix: '-b'),
        ),
        now: clock,
        newId: ids,
      );

      expect(applied.armorSet.set.id, 'armor-existing');
      expect(applied.itemsUpdated, isTrue);
      final idsAfter =
          applied.armorSet.activeItems.map((i) => i.instanceId).toSet();
      expect(idsAfter, {
        'inst-h-b',
        'inst-a-b',
        'inst-c-b',
        'inst-l-b',
        'inst-ci-b',
      });
    });

    test('missing set → not found', () async {
      final userId = await seedUser();
      expect(
        () => applyArmorCombinationInPlace(
          db,
          userId,
          ApplyArmorCombinationCommand(
            setId: 'missing',
            pieces: fivePieces(),
          ),
          now: clock,
          newId: ids,
        ),
        throwsA(
          isA<UseCaseException>().having(
            (e) => e.code,
            'code',
            UseCaseErrorCode.notFound,
          ),
        ),
      );
    });
  });
}
