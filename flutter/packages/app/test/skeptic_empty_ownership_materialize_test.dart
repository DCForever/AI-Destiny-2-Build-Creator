import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_db/destiny2_db.dart'
    hide Build, SetItem, Synergy, SynergyLink;
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

/// Skeptic plan item 3/7: empty ownership map fails closed on materialize
/// (no set write).
void main() {
  late AppDatabase db;
  const now = '2026-07-24T12:00:00.000Z';
  final clock = fixedNow(now);
  final ids = sequentialIds('skeptic-own');

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  List<MaterializePiece> fivePieces() => [
        const MaterializePiece(
          slot: EquipmentSlot.helmet,
          itemHash: 101,
          instanceId: 'inst-h',
        ),
        const MaterializePiece(
          slot: EquipmentSlot.arms,
          itemHash: 102,
          instanceId: 'inst-a',
        ),
        const MaterializePiece(
          slot: EquipmentSlot.chest,
          itemHash: 103,
          instanceId: 'inst-c',
        ),
        const MaterializePiece(
          slot: EquipmentSlot.legs,
          itemHash: 104,
          instanceId: 'inst-l',
        ),
        const MaterializePiece(
          slot: EquipmentSlot.classItem,
          itemHash: 105,
          instanceId: 'inst-ci',
        ),
      ];

  test(
    'Skeptic #3/#7: empty ownership map refuses materialize (no write)',
    () async {
      final userId = await insertUser(
        db,
        bungieMembershipId: 'm-skeptic',
        membershipType: 3,
        displayName: 'Skeptic',
      );
      await expectLater(
        materializeArmorCombination(
          db,
          userId,
          MaterializeArmorCommand(
            armorSetName: 'Empty ownership',
            pieces: fivePieces(),
          ),
          ownership: const <String, OwnedInstanceRef>{},
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
      final listed = await listUserSets(db, userId, type: SetType.armor);
      expect(listed, isEmpty);
    },
  );
}
